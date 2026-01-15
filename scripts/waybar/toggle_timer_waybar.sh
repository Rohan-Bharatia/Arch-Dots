#!/bin/bash

set -uo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly DURATION="${1:-60}"
readonly LOCK_FILE="${XDG_RUNTIME_DIR:-/run/user/${UID:-$(id -u)}}/waybar_timer.lock"
readonly STARTUP_GRACE_PERIOD=1
readonly KILL_GRACE_PERIOD=1

WAYBAR_PID=""
CLEANUP_EXECUTED=0

log_info() {
    printf '[%s] %s\n' "$SCRIPT_NAME" "$*"
}
log_error() {
    printf '[%s] ERROR: %s\n' "$SCRIPT_NAME" "$*" >&2
}

cleanup() {
    if (( CLEANUP_EXECUTED )); then
        return 0
    fi
    CLEANUP_EXECUTED=1
    log_info "Initiating cleanup..."
    if [[ -n "${WAYBAR_PID:-}" ]]; then
        if kill -0 "$WAYBAR_PID" 2>/dev/null; then
            log_info "Sending SIGTERM to PID $WAYBAR_PID..."
            kill -TERM "$WAYBAR_PID" 2>/dev/null || true
            local waited=0
            while (( waited < KILL_GRACE_PERIOD * 10 )); do
                if ! kill -0 "$WAYBAR_PID" 2>/dev/null; then
                    log_info "Process terminated gracefully."
                    break
                fi
                sleep 0.1
                (( waited++ )) || true
            done
            if kill -0 "$WAYBAR_PID" 2>/dev/null; then
                log_info "Process didn't terminate, sending SIGKILL..."
                kill -KILL "$WAYBAR_PID" 2>/dev/null || true
            fi
            wait "$WAYBAR_PID" 2>/dev/null || true
        else
            log_info "Process $WAYBAR_PID already terminated."
        fi
    fi
    rm -f "$LOCK_FILE" 2>/dev/null || true
    log_info "Cleanup complete."
}

setup_traps() {
    trap cleanup EXIT
    trap 'cleanup; exit 130' INT
    trap 'cleanup; exit 143' TERM
    trap 'cleanup; exit 131' QUIT
}

validate_environment() {
    local missing=()
    local cmd
    for cmd in pgrep uwsm-app timeout tail flock; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if (( ${#missing[@]} > 0 )); then
        log_error "Missing required commands: ${missing[*]}"
        return 1
    fi
    if ! [[ "$DURATION" =~ ^[1-9][0-9]*$ ]]; then
        log_error "DURATION must be a positive integer (got: '$DURATION')"
        return 1
    fi
    local lock_dir
    lock_dir="$(dirname "$LOCK_FILE")"
    if [[ ! -d "$lock_dir" ]]; then
        log_error "Lock directory does not exist: $lock_dir"
        log_error "Is XDG_RUNTIME_DIR set correctly?"
        return 1
    fi
    return 0
}

acquire_lock() {
    if ! exec 200>"$LOCK_FILE"; then
        log_error "Cannot create lock file: $LOCK_FILE"
        return 1
    fi
    if ! flock -n 200; then
        log_error "Another instance of this script is already running."
        log_error "Lock file: $LOCK_FILE"
        return 1
    fi
    echo $$ >&200
    return 0
}

check_existing_waybar() {
    if pgrep -x "waybar" >/dev/null 2>&1; then
        log_error "Waybar is already running (found via pgrep)."
        log_error "This script refuses to interfere with existing instances."
        log_error "Stop the existing Waybar first, or manage it separately."
        return 1
    fi
    return 0
}

start_waybar() {
    log_info "Launching Waybar via uwsm-app..."
    uwsm-app -- waybar &
    WAYBAR_PID=$!
    log_info "Started process with PID: $WAYBAR_PID"
    sleep "$STARTUP_GRACE_PERIOD"
    if ! kill -0 "$WAYBAR_PID" 2>/dev/null; then
        log_error "Process $WAYBAR_PID died during startup."
        log_error "Check waybar configuration for errors."
        return 1
    fi
    if ! pgrep -x "waybar" >/dev/null 2>&1; then
        log_error "uwsm-app started but waybar process not detected."
        log_error "The launcher may have failed silently."
        return 1
    fi
    log_info "Waybar is running. Starting ${DURATION}s countdown..."
    return 0
}

monitor_waybar() {
    local monitor_status=0
    timeout "$DURATION" tail --pid="$WAYBAR_PID" -f /dev/null 2>/dev/null || monitor_status=$?
    case $monitor_status in
        0)
            log_info "Waybar process exited on its own (or was killed externally)."
            ;;
        124)
            log_info "Time limit reached (${DURATION}s). Stopping Waybar..."
            ;;
        137)
            log_info "Monitoring was forcefully terminated."
            ;;
        *)
            log_info "Monitoring ended with unexpected status: $monitor_status"
            ;;
    esac
    return $monitor_status
}

log_info "=== Waybar Timer Script ==="
log_info "Duration: ${DURATION}s"
if ! validate_environment; then
    exit 1
fi
if ! acquire_lock; then
    exit 1
fi
setup_traps
if ! check_existing_waybar; then
    exit 1
fi
if ! start_waybar; then
    exit 1
fi
monitor_waybar
local final_status=$?
log_info "=== Script finished ==="
exit $final_status
