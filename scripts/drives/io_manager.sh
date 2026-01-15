#!/usr/bin/env bash

set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true

readonly C_RESET=$'\e[0m'
readonly C_BOLD=$'\e[1m'
readonly C_CYAN=$'\e[36m'
readonly C_GREEN=$'\e[32m'
readonly C_RED=$'\e[31m'
readonly C_PURPLE=$'\e[35m'
readonly C_GREY=$'\e[90m'
readonly VALID_DEV_REGEX='^[a-zA-Z0-9_-]+$'

cleanup() {
    tput cnorm 2>/dev/null || true
}
trap cleanup EXIT INT TERM

die() {
    printf '%s[Error] %s%s\n' "$C_RED" "$1" "$C_RESET" >&2
    exit "${2:-1}"
}

check_deps() {
    local -a missing=()
    local cmd
    for cmd in iostat lsblk watch tput; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if (( ${#missing[@]} )); then
        die "Missing dependencies: ${missing[*]} (install: sysstat, procps-ng, ncurses)"
    fi
}

validate_device() {
    local dev="$1"
    if [[ ! "$dev" =~ $VALID_DEV_REGEX ]]; then
        die "Invalid device name format: '$dev'"
    fi
    if [[ ! -b "/dev/$dev" ]]; then
        die "Device '/dev/$dev' does not exist or is not a block device."
    fi
}

select_drive() {
    local -a dev_list=()
    local -A dev_set=()
    local name size type model formatted
    {
        clear
        printf '%s%s:: Drive Selection ::%s\n' "$C_BOLD" "$C_CYAN" "$C_RESET"
        printf '%s%-12s %-10s %-8s %-24s%s\n' "$C_BOLD" "NAME" "SIZE" "TYPE" "MODEL" "$C_RESET"
        printf '%s%s%s\n' "$C_GREY" "────────────────────────────────────────────────────────────" "$C_RESET"
    } >&2
    while read -r name size type model; do
        [[ -z "$name" ]] && continue
        dev_list+=("$name")
        dev_set["$name"]=1
        printf -v formatted '%-12s %-10s %-8s %-24s' "$name" "$size" "$type" "${model:-N/A}"
        printf '%s%s%s\n' "$C_GREEN" "$formatted" "$C_RESET" >&2
    done < <(lsblk -dno NAME,SIZE,TYPE,MODEL | grep -vE '^(loop|sr|ram|zram|fd)')
    if (( ${#dev_list[@]} == 0 )); then
        die "No physical drives detected."
    fi
    printf '\n%sEnter target drive (e.g., %s): %s' "$C_BOLD" "${dev_list[0]}" "$C_RESET" >&2
    local input
    if ! read -r -t 60 input; then
        printf '\n' >&2
        die "Timed out waiting for input (60s)."
    fi
    input="${input#/dev/}"
    input="${input//[[:space:]]/}"
    if [[ -z "${dev_set[$input]+_}" ]]; then
        die "Invalid device: '$input'. Available: ${dev_list[*]}"
    fi
    printf '%s' "$input"
}

build_dashboard_cmd() {
    local drive="$1"
    cat <<-EOF
	# Section 1: System Write Buffers
	printf '${C_BOLD}${C_CYAN}━━━ 1. System Write Buffer (RAM) ━━━${C_RESET} ${C_GREY}[ grep Dirty|Writeback /proc/meminfo ]${C_RESET}\n'
	grep -E '^(Dirty|Writeback):' /proc/meminfo | awk '{printf "  %-15s %8.2f MB\n", \$1, \$2/1024}'

	# Section 2: Lifetime I/O Totals
	printf '\n${C_BOLD}${C_PURPLE}━━━ 2. Lifetime I/O (Since Boot) ━━━${C_RESET} ${C_GREY}[ iostat -m -d /dev/${drive} ]${C_RESET}\n'
	iostat -m -d /dev/${drive} | grep -E '^(Device|${drive})'

	# Section 3: Instant Speed (1-second sample)
	printf '\n${C_BOLD}${C_GREEN}━━━ 3. Instant Speed (Last 1s) ━━━${C_RESET} ${C_GREY}[ iostat -y -m -d 1 1 ]${C_RESET}\n'
	iostat -y -m -d /dev/${drive} 1 1 | grep '^${drive}'
	EOF
}

show_help() {
    cat <<-EOF
	${C_BOLD}Usage:${C_RESET} ${0##*/} [DEVICE]

	${C_BOLD}Description:${C_RESET}
	  Monitor disk I/O with a real-time dashboard showing:
	    • RAM write buffers (Dirty/Writeback)
	    • Lifetime I/O statistics (since boot)
	    • Instant read/write speeds (1-second samples)

	${C_BOLD}Arguments:${C_RESET}
	  DEVICE    Block device name (e.g., sda, nvme0n1)
	            If omitted, an interactive menu is shown.

	${C_BOLD}Examples:${C_RESET}
	  ${0##*/}           # Interactive device selection
	  ${0##*/} sda       # Monitor /dev/sda directly
	  ${0##*/} nvme0n1   # Monitor NVMe drive

	${C_BOLD}Dependencies:${C_RESET}
	  iostat (sysstat), watch (procps-ng), lsblk, tput (ncurses)
	EOF
    exit 0
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && show_help
check_deps
local drive
if (( $# > 0 )); then
    drive="${1#/dev/}"
    validate_device "$drive"
else
    drive=$(select_drive)
fi
[[ -z "$drive" ]] && die "No drive selected."
local dashboard_cmd
dashboard_cmd=$(build_dashboard_cmd "$drive")
clear
printf '%s╔═══════════════════════════════════════════════════════════════╗%s\n' "$C_CYAN" "$C_RESET"
printf '%s║  %sI/O Dashboard%s :: Monitoring /dev/%-27s%s║%s\n' "$C_CYAN" "$C_BOLD" "$C_RESET$C_CYAN" "$drive" "$C_CYAN" "$C_RESET"
printf '%s╚═══════════════════════════════════════════════════════════════╝%s\n' "$C_CYAN" "$C_RESET"
printf '%sPress Ctrl+C to exit.%s\n\n' "$C_GREY" "$C_RESET"
sleep 0.8
tput civis 2>/dev/null || true
exec watch --color -t -d -n 1 -- "$dashboard_cmd"
