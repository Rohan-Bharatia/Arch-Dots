#!/usr/bin/env bash

set -euo pipefail

readonly APP_NAME="waybar"
readonly TIMEOUT_SEC=5

if [[ -t 2 ]]; then
    readonly C_RED=$'\033[0;31m'
    readonly C_GREEN=$'\033[0;32m'
    readonly C_BLUE=$'\033[0;34m'
    readonly C_RESET=$'\033[0m'
else
    readonly C_RED=''
    readonly C_GREEN=''
    readonly C_BLUE=''
    readonly C_RESET=''
fi

log_info() {
    printf '%s[INFO]%s %s\n' "${C_BLUE}" "${C_RESET}" "$*"
}
log_success() {
    printf '%s[OK]%s %s\n' "${C_GREEN}" "${C_RESET}" "$*"
}
log_err() {
    printf '%s[ERROR]%s %s\n' "${C_RED}" "${C_RESET}" "$*" >&2
}

(( EUID != 0 )) || { log_err "This script must NOT be run as root."; exit 1; }
command -v "${APP_NAME}" &>/dev/null || { log_err "${APP_NAME} binary not found in PATH."; exit 1; }
[[ -d "${XDG_RUNTIME_DIR:-}" ]] || { log_err "XDG_RUNTIME_DIR is missing or invalid."; exit 1; }
readonly LOCK_FILE="${XDG_RUNTIME_DIR}/${APP_NAME}_manager.lock"
exec 9>"${LOCK_FILE}"
flock -n 9 || { log_err "Another instance is running. Exiting."; exit 1; }
log_info "Managing ${APP_NAME} instances..."
if pgrep -x "${APP_NAME}" >/dev/null; then
    log_info "Stopping existing instances..."
    pkill -x "${APP_NAME}" 2>/dev/null || true
    for ((i=0; i<TIMEOUT_SEC*10; i++)); do
        pgrep -x "${APP_NAME}" >/dev/null || break
        sleep 0.1
    done
    if pgrep -x "${APP_NAME}" >/dev/null; then
        log_err "Process hung. Sending SIGKILL..."
        pkill -9 -x "${APP_NAME}" 2>/dev/null || true
        sleep 0.2
    fi
    log_success "Cleanup complete."
else
    log_info "No running instance found."
fi
log_info "Starting ${APP_NAME}..."
exec "${APP_NAME}" "$@" 9>&-
