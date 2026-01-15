#!/usr/bin/env bash

set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true

declare -r SCRIPT_NAME="${0##*/}"
declare -r LOCKFILE="/var/lock/${SCRIPT_NAME}.lock"
declare -r NM_CONF="/etc/NetworkManager/conf.d/96-tailscale.conf"

if [[ -t 1 ]]; then
    declare -r R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' B=$'\e[34m' C=$'\e[36m' W=$'\e[0m'
else
    declare -r R="" G="" Y="" B="" C="" W=""
fi

log_info() {
    printf "%s[INFO]%s  %s\n" "$B" "$W" "$*"
}
log_succ() {
    printf "%s[OK]%s    %s\n" "$G" "$W" "$*"
}
log_warn() {
    printf "%s[WARN]%s  %s\n" "$Y" "$W" "$*" >&2
}
log_error() {
    printf "%s[ERROR]%s %s\n" "$R" "$W" "$*" >&2
}
log_step() {
    printf "\n%s[STEP]%s %s\n" "$C" "$W" "$*"
}

die() {
    log_error "$*"
    exit 1
}

cleanup() {
    local exit_code=$?
    if (( EUID == 0 )); then
        rm -f "$LOCKFILE" 2>/dev/null || true
    fi
    if (( exit_code != 0 )); then
        printf "\n%s[FATAL]%s Script terminated with error code %d.\n" "$R" "$W" "$exit_code" >&2
    fi
}
trap cleanup EXIT INT TERM

cmd_exists() {
    command -v "$1" &>/dev/null
}
pkg_installed() {
    pacman -Q "$1" &>/dev/null
}

if (( BASH_VERSINFO[0] < 5 )); then die "Bash 5.0+ required."; fi
if (( EUID != 0 )); then
    log_info "Escalating permissions..."
    script_path=$(realpath "${BASH_SOURCE[0]}")
    exec sudo --preserve-env=TERM bash "$script_path" "$@"
fi
if [[ -f "$LOCKFILE" ]]; then
    if kill -0 "$(<"$LOCKFILE")" 2>/dev/null; then
        die "Another instance is running."
    fi
fi
log_step "Tailscale Teardown & Revert"
printf "This script can disable Tailscale temporarily, reset it, or remove it completely.\n\n"
printf "%sChoose an option:%s\n" "$C" "$W"
printf "  %s[1]%s Disable (Turn off VPN, keep login & install)\n" "$G" "$W"
printf "  %s[2]%s Reset Identity (Keep install, force NEW IP & QR code on next setup)\n" "$B" "$W"
printf "  %s[3]%s Full Uninstall (Remove package, configs & all data)\n" "$R" "$W"
printf "  %s[4]%s Cancel\n\n" "$Y" "$W"
printf "Select [1-4]: "
read -r choice
case "$choice" in
    1)
        MODE="DISABLE"
        ;;
    2)
        MODE="RESET"
        ;;
    3)
        MODE="UNINSTALL"
        ;;
    *)
        log_info "Cancelled."
        exit 0
        ;;
esac
log_step "Stopping Services"
if systemctl is-active --quiet tailscaled; then
    log_info "Bringing down tailscale interface..."
    if [[ "$MODE" != "DISABLE" ]]; then
        timeout 5 tailscale logout 2>/dev/null || true
    fi
    tailscale down --accept-risk=lose-ssh 2>/dev/null || true
    log_info "Stopping tailscaled service..."
    systemctl stop tailscaled
    systemctl disable tailscaled
    log_succ "Service stopped and disabled."
else
    log_info "Tailscale service is not running."
fi
if [[ "$MODE" == "DISABLE" ]]; then
    log_succ "Tailscale is disabled."
    exit 0
fi
log_step "Cleaning State Data"
if [[ -d "/var/lib/tailscale" ]]; then
    log_info "Removing local state files (Identity/Keys)..."
    rm -rf /var/lib/tailscale
    log_succ "Identity wiped."
fi
if [[ -d "/var/cache/tailscale" ]]; then
    rm -rf /var/cache/tailscale
fi
log_info "Cleaning network configs..."
if cmd_exists firewall-cmd && systemctl is-active --quiet firewalld; then
    firewall-cmd --zone=trusted --remove-interface=tailscale0 --permanent >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
elif cmd_exists ufw && systemctl is-active --quiet ufw; then
    ufw delete allow in on tailscale0 >/dev/null 2>&1 || true
fi
rm -f "$NM_CONF"
if systemctl is-active --quiet NetworkManager; then
    systemctl reload NetworkManager || systemctl restart NetworkManager
fi
log_succ "Network configs cleared."
if [[ "$MODE" == "RESET" ]]; then
    printf "\n%s[SUCCESS]%s Tailscale identity has been reset.\n" "$G" "$W"
    printf "You can now run the Setup Script to generate a NEW IP and re-authenticate.\n"
    exit 0
fi
log_step "Removing Software"
if pkg_installed tailscale; then
    log_info "Uninstalling Tailscale package..."
    pacman -Rns --noconfirm tailscale
    log_succ "Tailscale uninstalled."
else
    log_warn "Tailscale package not found (already removed?)."
fi
printf "\n%s[SUCCESS]%s Tailscale has been fully removed.\n" "$G" "$W"
