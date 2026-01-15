#!/usr/bin/env bash

set -euo pipefail

readonly SERVER_BIN="/usr/bin/swayosd-server"
readonly PROCESS_NAME="swayosd-server"
readonly SHUTDOWN_ATTEMPTS=20
readonly SHUTDOWN_INTERVAL=0.1
readonly STARTUP_DELAY=0.5

is_running() {
    pgrep -x "$PROCESS_NAME" >/dev/null 2>&1
}
log_error() {
    printf 'Error: %s\n' "$*" >&2
}
log_success() {
    printf 'Success: %s\n' "$*"
}

if [[ ! -x "$SERVER_BIN" ]]; then
    log_error "Server binary not found or not executable: $SERVER_BIN"
    exit 1
fi
if is_running; then
    pkill -x "$PROCESS_NAME" 2>/dev/null || true
    for ((_i = 0; _i < SHUTDOWN_ATTEMPTS; _i++)); do
        is_running || break
        sleep "$SHUTDOWN_INTERVAL"
    done
    if is_running; then
        pkill -9 -x "$PROCESS_NAME" 2>/dev/null || true
        sleep 0.1
    fi
    if is_running; then
        log_error "Failed to terminate existing $PROCESS_NAME process"
        exit 1
    fi
fi
if command -v uwsm-app >/dev/null 2>&1; then
    uwsm-app -- "$SERVER_BIN" >/dev/null 2>&1 &
elif command -v systemd-run >/dev/null 2>&1; then
    unit_name="swayosd-$$-$(date +%s)"
    systemd-run --user --scope --unit="$unit_name" \
        -- "$SERVER_BIN" >/dev/null 2>&1 &
else
    setsid "$SERVER_BIN" >/dev/null 2>&1 &
fi
disown 2>/dev/null || true
sleep "$STARTUP_DELAY"
if is_running; then
    log_success "SwayOSD server restarted"
    exit 0
else
    log_error "SwayOSD server failed to start"
    exit 1
fi
