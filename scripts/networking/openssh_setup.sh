#!/usr/bin/env bash

set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true

if [[ -t 1 ]]; then
    readonly C_RESET=$'\e[0m'
    readonly C_BOLD=$'\e[1m'
    readonly C_GREEN=$'\e[32m'
    readonly C_BLUE=$'\e[34m'
    readonly C_YELLOW=$'\e[33m'
    readonly C_RED=$'\e[31m'
    readonly C_CYAN=$'\e[36m'
    readonly C_MAGENTA=$'\e[35m'
else
    readonly C_RESET='' C_BOLD='' C_GREEN='' C_BLUE=''
    readonly C_YELLOW='' C_RED='' C_CYAN='' C_MAGENTA=''
fi

info() {
    printf "%s[INFO]%s %s\n" "$C_BLUE" "$C_RESET" "$*"
}
success() {
    printf "%s[OK]%s   %s\n" "$C_GREEN" "$C_RESET" "$*"
}
warn() {
    printf "%s[WARN]%s %s\n" "$C_YELLOW" "$C_RESET" "$*"
}
error() {
    printf "%s[ERR]%s  %s\n" "$C_RED" "$C_RESET" "$*" >&2
}
die() {
    error "$*"; exit 1
}

cleanup() {
    :
}
trap cleanup EXIT

escalate_and_detect_user() {
    if [[ $EUID -eq 0 ]]; then
        local human_user="${SUDO_USER:-}"
        if [[ -z "$human_user" ]]; then
            human_user=$(loginctl list-sessions --no-legend | head -n1 | awk '{print $3}' 2>/dev/null || true)
        fi
        REAL_USER="${human_user:-root}"
        return 0
    fi
    info "Root privileges required for system configuration."
    if sudo -v; then
        exec sudo --preserve-env=TERM,COLORTERM "$0" "$@"
    else
        die "Sudo authentication failed."
    fi
}

escalate_and_detect_user
printf "\n%sArch Linux SSH Provisioning%s\n" "$C_BOLD" "$C_RESET"
printf "Checks: OpenSSH, Firewalld, Tailscale, Network Routes.\n\n"
read -r -p "${C_YELLOW}Enable SSH Access? [Y/n]${C_RESET} " response
response=${response:-Y}
if [[ ! "$response" =~ ^[yY]([eE][sS])?$ ]]; then
    info "Aborting setup at user request."
    exit 0
fi
if ! pacman -Qi openssh &>/dev/null; then
    info "Installing OpenSSH..."
    if ! pacman -S --noconfirm --needed openssh >/dev/null; then
        error "Installation failed."
        warn "Your local package database might be old."
        warn "Please run 'sudo pacman -Syu' manually to update your system,"
        die "then run this script again. Refusing to perform partial upgrade (-Sy)."
    fi
    success "OpenSSH installed."
else
    success "OpenSSH is already installed."
fi
if command -v firewall-cmd &>/dev/null; then
    if systemctl is-active --quiet firewalld; then
        DEFAULT_ZONE=$(firewall-cmd --get-default-zone)
        if ! firewall-cmd --zone="$DEFAULT_ZONE" --query-service=ssh; then
            info "Opening SSH in default zone ($DEFAULT_ZONE)..."
            firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-service=ssh >/dev/null
            firewall-cmd --reload >/dev/null
            success "SSH service allowed in '$DEFAULT_ZONE'."
        else
            success "Firewalld already permits SSH in '$DEFAULT_ZONE'."
        fi
    else
        warn "Firewalld installed but NOT active. Skipping."
    fi
fi
if ! systemctl is-active --quiet sshd; then
    info "Starting sshd..."
    systemctl enable --now sshd
    for i in {1..5}; do
        if systemctl is-active --quiet sshd; then
            break
        fi
        sleep 1
    done
    if ! systemctl is-active --quiet sshd; then
        die "Failed to start sshd. Check 'systemctl status sshd'."
    fi
fi
success "sshd.service is active."
USE_TAILSCALE_IP=false
TAILSCALE_IP=""
if command -v tailscale &>/dev/null && systemctl is-active --quiet tailscaled; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || true)
    if [[ -n "$TAILSCALE_IP" ]]; then
        printf "\n%s[Tailscale Detected]%s\n" "$C_MAGENTA" "$C_RESET"
        printf "Tailscale IP: %s%s%s\n" "$C_BOLD" "$TAILSCALE_IP" "$C_RESET"
        read -r -p "${C_YELLOW}Use Tailscale IP for remote connection? [y/N]${C_RESET} " ts_choice
        ts_choice=${ts_choice:-N}
        if [[ "$ts_choice" =~ ^[yY]([eE][sS])?$ ]]; then
            USE_TAILSCALE_IP=true
            if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld; then
                TS_IFACE=$(ip -o link show | awk -F': ' '/tailscale/ {print $2; exit}')
                TS_IFACE=${TS_IFACE:-tailscale0}
                if ! firewall-cmd --zone=trusted --query-interface="$TS_IFACE"; then
                    info "Trusting interface $TS_IFACE in firewall..."
                    firewall-cmd --permanent --zone=trusted --add-interface="$TS_IFACE" >/dev/null
                    firewall-cmd --reload >/dev/null
                    success "Tailscale traffic is now trusted."
                fi
            fi
        fi
    fi
fi
TARGET_IP=""
if [[ "$USE_TAILSCALE_IP" == "true" ]]; then
    TARGET_IP="$TAILSCALE_IP"
else
    info "Detecting Local LAN IP..."
    CANDIDATE_IP=$(ip -o -4 addr show | awk '$2 ~ /^(e|w)/ && $2 !~ /(docker|br|vbox|virbr|waydroid|tun|warp)/ {print $4}' | cut -d/ -f1 | head -n 1)
    if [[ -n "$CANDIDATE_IP" ]]; then
        TARGET_IP="$CANDIDATE_IP"
    else
        DEFAULT_IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
        if [[ -n "$DEFAULT_IFACE" ]]; then
             TARGET_IP=$(ip -o -4 addr show dev "$DEFAULT_IFACE" | awk '{print $4}' | cut -d/ -f1 | head -n 1)
        fi
    fi
fi
if [[ -z "$TARGET_IP" ]]; then
    TARGET_IP="<IP-NOT-FOUND>"
    warn "Could not determine IP address automatically."
fi
SSH_PORT="22"
if active_port=$(sshd -T 2>/dev/null | awk '/^port / {print $2}'); then
    SSH_PORT="$active_port"
fi
if [[ ! "$SSH_PORT" =~ ^[0-9]+$ ]]; then
    SSH_PORT="22"
fi
if [[ "$SSH_PORT" == "22" ]]; then
    CONN_CMD="ssh ${REAL_USER}@${TARGET_IP}"
else
    CONN_CMD="ssh -p ${SSH_PORT} ${REAL_USER}@${TARGET_IP}"
fi
printf "\n%s======================================================%s\n" "$C_GREEN" "$C_RESET"
printf " %sSSH Setup Complete!%s\n" "$C_BOLD" "$C_RESET"
printf "%s======================================================%s\n" "$C_GREEN" "$C_RESET"
printf " %-15s : %s%s%s\n" "IP Address" "$C_CYAN" "$TARGET_IP" "$C_RESET"
printf " %-15s : %s%s%s\n" "Port" "$C_CYAN" "$SSH_PORT" "$C_RESET"
printf " %-15s : %s%s%s\n" "User" "$C_CYAN" "$REAL_USER" "$C_RESET"
printf "\n Connect from another device:\n"
printf "    %s%s%s\n\n" "$C_MAGENTA" "$CONN_CMD" "$C_RESET"
printf "%s======================================================%s\n" "$C_GREEN" "$C_RESET"
if [[ -t 0 ]]; then
    read -r -p "Press ${C_BOLD}[Enter]${C_RESET} to close setup..."
fi
