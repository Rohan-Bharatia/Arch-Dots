#!/usr/bin/env bash

set -euo pipefail

shopt -s inherit_errexit 2>/dev/null || true

if [[ -t 1 ]]; then
    readonly C_RED="\033[31m"
    readonly C_GREEN="\033[32m"
    readonly C_YELLOW="\033[33m"
    readonly C_BLUE="\033[34m"
    readonly C_GRAY="\033[90m"
    readonly C_BOLD="\033[1m"
    readonly C_RESET="\033[0m"
else
    readonly C_RED="" C_GREEN="" C_YELLOW="" C_BLUE=""
    readonly C_GRAY="" C_BOLD="" C_RESET=""
fi
if [[ $EUID -ne 0 ]]; then
    printf "%b[PRIV]%b Root privileges needed for block analysis. Auto-escalating...\n" "$C_YELLOW" "$C_RESET"
    script_path=$(realpath -- "$0" 2>/dev/null || echo "$0")
    if command -v sudo &>/dev/null; then
        exec sudo env PATH="$PATH" bash -- "$script_path" "$@"
    else
        printf "%b[ERR]%b 'sudo' not found. Please run as root.\n" "$C_RED" "$C_RESET" >&2
        exit 1
    fi
fi
declare -a missing_pkgs=()
if ! command -v compsize &>/dev/null; then
    missing_pkgs+=("compsize")
fi
if ! command -v findmnt &>/dev/null; then
    missing_pkgs+=("util-linux")
fi
if ! command -v awk &>/dev/null; then
    missing_pkgs+=("gawk")
fi
if ! command -v grep &>/dev/null; then
    missing_pkgs+=("grep")
fi
if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
    printf "%b[DEPS]%b Missing packages detected: %b%s%b\n" "$C_YELLOW" "$C_RESET" "$C_BOLD" "${missing_pkgs[*]}" "$C_RESET"
    printf "       Installing via pacman...\n"
    if pacman -S --needed --noconfirm "${missing_pkgs[@]}"; then
        printf "%b[OK]%b Dependencies installed successfully.\n" "$C_GREEN" "$C_RESET"
    else
        printf "%b[ERR]%b Failed to install dependencies. Aborting.\n" "$C_RED" "$C_RESET" >&2
        exit 1
    fi
fi
raw_mounts=$(findmnt -n -l -t btrfs -o TARGET 2>/dev/null || true)
if [[ -z "$raw_mounts" ]]; then
    printf "%b[ERR]%b No Btrfs filesystems detected on this system.\n" "$C_RED" "$C_RESET" >&2
    exit 1
fi
mapfile -t targets < <(echo "$raw_mounts" | grep -vE "/var/lib/docker|/var/lib/containers|/snap" | sort -u || true)
if [[ ${#targets[@]} -eq 0 ]]; then
    printf "%b[ERR]%b No suitable Btrfs mounts found (all were filtered).\n" "$C_RED" "$C_RESET" >&2
    exit 1
fi
printf "%b[INFO]%b Detected Btrfs targets:\n" "$C_BLUE" "$C_RESET"
printf "       %s\n" "${targets[@]}"
printf "\n%b[RUN]%b  Calculating compression (this may take a moment)...\n" "$C_BLUE" "$C_RESET"
printf "       %b(Using -x to respect mount boundaries)%b\n" "$C_GRAY" "$C_RESET"
printf "%s\n" "---------------------------------------------------------------"
output=$(compsize -x "${targets[@]}" 2>&1 || true)
printf "%s\n" "$output"
printf "%s\n" "---------------------------------------------------------------"
total_line=$(echo "$output" | grep "^TOTAL" || true)
if [[ -n "$total_line" ]]; then
    read -r _ ratio_str disk_str uncomp_str _ <<< "$total_line"
    ratio_val="${ratio_str%\%}"
    ratio_val="${ratio_val%%.*}"
    if [[ ! "$ratio_val" =~ ^[0-9]+$ ]]; then
        printf "%b[WARN]%b Could not parse compression ratio (got: %s)\n" "$C_YELLOW" "$C_RESET" "$ratio_str" >&2
        exit 0
    fi
    bytes_disk=$(numfmt --from=iec "$disk_str" 2>/dev/null || echo 0)
    bytes_uncomp=$(numfmt --from=iec "$uncomp_str" 2>/dev/null || echo 0)
    bytes_saved=$(( bytes_uncomp - bytes_disk ))
    if [[ $bytes_saved -lt 0 ]]; then bytes_saved=0; fi
    human_saved=$(numfmt --to=iec "$bytes_saved" 2>/dev/null || echo "N/A")
    saved_val=$((100 - ratio_val))
    save_color="$C_GREEN"
    [[ $saved_val -lt 10 ]] && save_color="$C_YELLOW"
    printf "\n%b=== ARCH SYSTEM SAVINGS OVERVIEW ===%b\n" "$C_BOLD" "$C_RESET"
    printf "  Total Data Size:      %s\n" "$uncomp_str"
    printf "  Physical Disk Used:   %s\n" "$disk_str"
    printf "  Compression Ratio:    %s\n" "$ratio_str"
    printf "  Total Space Saved:    %b%s%b\n" "$save_color" "$human_saved" "$C_RESET"
    printf "  Space Reclaimed:      %b~%s%% of your drive%b\n" "$save_color" "$saved_val" "$C_RESET"
    printf "\n"
else
    printf "%b[WARN]%b Could not find 'TOTAL' line in output. Is the volume empty?\n" "$C_YELLOW" "$C_RESET"
fi
