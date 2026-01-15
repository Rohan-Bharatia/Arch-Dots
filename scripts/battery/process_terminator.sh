#!/bin/bash

set -o pipefail

readonly STOP_TIMEOUT=10
readonly PROCESS_WAIT_ATTEMPTS=10
readonly PROCESS_WAIT_INTERVAL=0.1
readonly RED=$'\033[1;31m'
readonly GREEN=$'\033[1;32m'
readonly YELLOW=$'\033[1;33m'
readonly BLUE=$'\033[1;34m'
readonly GRAY=$'\033[0;37m'
readonly RESET=$'\033[0m'
readonly -a TARGET_PROCESSES=(
    "hyprsunset"
    "waybar"
    "blueman-manager"
)
readonly -a TARGET_SYSTEM_SERVICES=(
    "firewalld"
    "vsftpd"
    "waydroid-container"
    "logrotate.timer"
    "sshd"
)
readonly -a TARGET_USER_SERVICES=(
    "battery_notify"
    "blueman-applet"
    "hypridle"
    "swaync"
    "gvfs-daemon"
    "gvfs-metadata"
    "network_meter"
)

FAILURE_COUNT=0
REAL_USER=""
REAL_UID=""
USER_RUNTIME_DIR=""
USER_DBUS_ADDRESS=""

die() {
    echo -e "${RED}Error: $1${RESET}" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}Warning: $1${RESET}" >&2
}

check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        die "This script must be run as root (sudo)."
    fi
}

check_dependencies() {
    local -a missing=()
    local cmd
    for cmd in pgrep pkill systemctl id timeout; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing required commands: ${missing[*]}"
    fi
}

detect_real_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        REAL_USER="$SUDO_USER"
        REAL_UID=$(id -u "$SUDO_USER" 2>/dev/null) || die "Could not determine UID for user '$SUDO_USER'"
    else
        warn "Script not run via sudo. User services may not stop correctly."
        REAL_USER="root"
        REAL_UID=0
    fi
    USER_RUNTIME_DIR="/run/user/${REAL_UID}"
    USER_DBUS_ADDRESS="unix:path=${USER_RUNTIME_DIR}/bus"
}

print_status() {
    local status="$1"
    local name="$2"
    local extra="${3:-}"
    case "$status" in
        success)
            echo -e "[${GREEN} OK ${RESET}] Stopped: ${name}${extra:+ ($extra)}"
            ;;
        skip)
            echo -e "[${GRAY}SKIP${RESET}] Not running: ${name}${extra:+ ($extra)}"
            ;;
        fail)
            echo -e "[${RED}FAIL${RESET}] Could not stop: ${name}${extra:+ ($extra)}"
            ((FAILURE_COUNT++))
            ;;
    esac
}

stop_process() {
    local name="$1"
    local i
    if ! pgrep -x "$name" &>/dev/null; then
        print_status "skip" "$name"
        return 0
    fi
    pkill -x "$name" 2>/dev/null
    for ((i = 0; i < PROCESS_WAIT_ATTEMPTS; i++)); do
        if ! pgrep -x "$name" &>/dev/null; then
            print_status "success" "$name" "SIGTERM"
            return 0
        fi
        sleep "$PROCESS_WAIT_INTERVAL"
    done
    pkill -9 -x "$name" 2>/dev/null
    sleep 0.3
    if ! pgrep -x "$name" &>/dev/null; then
        print_status "success" "$name" "SIGKILL"
    else
        print_status "fail" "$name"
    fi
}

stop_system_service() {
    local name="$1"
    if ! systemctl is-active --quiet "$name" 2>/dev/null; then
        print_status "skip" "$name"
        return 0
    fi
    if timeout "$STOP_TIMEOUT" systemctl stop "$name" 2>/dev/null; then
        if ! systemctl is-active --quiet "$name" 2>/dev/null; then
            print_status "success" "$name"
            return 0
        fi
    fi
    print_status "fail" "$name"
}

run_as_user() {
    sudo -u "$REAL_USER" \
        XDG_RUNTIME_DIR="$USER_RUNTIME_DIR" \
        DBUS_SESSION_BUS_ADDRESS="$USER_DBUS_ADDRESS" \
        "$@"
}

stop_user_service() {
    local name="$1"
    if [[ "$REAL_USER" == "root" ]]; then
        print_status "skip" "$name" "no user session"
        return 0
    fi
    if [[ ! -d "$USER_RUNTIME_DIR" ]]; then
        print_status "skip" "$name" "no runtime dir"
        return 0
    fi
    if ! run_as_user systemctl --user is-active --quiet "$name" 2>/dev/null; then
        print_status "skip" "$name"
        return 0
    fi
    if run_as_user timeout "$STOP_TIMEOUT" systemctl --user stop "$name" 2>/dev/null; then
        if ! run_as_user systemctl --user is-active --quiet "$name" 2>/dev/null; then
            print_status "success" "$name"
            return 0
        fi
    fi
    print_status "fail" "$name"
}

print_header() {
    local width=44
    local title="Performance Terminator"
    local user_info="User: ${REAL_USER} (UID: ${REAL_UID})"
    echo ""
    printf '%*s\n' "$width" '' | tr ' ' '-'
    printf " %-*s\n" $((width - 2)) "$title"
    printf " %-*s\n" $((width - 2)) "$user_info"
    printf '%*s\n' "$width" '' | tr ' ' '-'
}

print_footer() {
    local width=44
    echo ""
    printf '%*s\n' "$width" '' | tr ' ' '-'
    if [[ $FAILURE_COUNT -eq 0 ]]; then
        echo -e " ${GREEN}Cleanup complete. All operations successful.${RESET}"
    else
        echo -e " ${YELLOW}Cleanup complete with ${FAILURE_COUNT} failure(s).${RESET}"
    fi
    printf '%*s\n' "$width" '' | tr ' ' '-'
}

local item
check_root
check_dependencies
detect_real_user
print_header
echo -e "\n${BLUE}:: Processes${RESET}"
for item in "${TARGET_PROCESSES[@]}"; do
    stop_process "$item"
done
echo -e "\n${BLUE}:: System Services${RESET}"
for item in "${TARGET_SYSTEM_SERVICES[@]}"; do
    stop_system_service "$item"
done
echo -e "\n${BLUE}:: User Services${RESET}"
for item in "${TARGET_USER_SERVICES[@]}"; do
    stop_user_service "$item"
done
print_footer
if [[ $FAILURE_COUNT -gt 0 ]]; then
    exit 1
fi
