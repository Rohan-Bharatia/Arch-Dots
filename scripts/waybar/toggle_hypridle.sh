#!/usr/bin/env bash

set -uo pipefail

readonly WAYBAR_SIGNAL=9
readonly PROC_NAME="hypridle"
readonly KILL_TIMEOUT=50

is_running() {
    pgrep -x "${PROC_NAME}" &>/dev/null
}

send_notification() {
    local urgency="$1"
    local title="$2"
    local body="$3"
    local icon="$4"
    command -v notify-send &>/dev/null || return 0
    notify-send -u "${urgency}" -t 2000 "${title}" "${body}" -i "${icon}"
}

update_waybar() {
    pkill -RTMIN+"${WAYBAR_SIGNAL}" waybar 2>/dev/null || true
}

if is_running; then
    pkill -x "${PROC_NAME}" 2>/dev/null || true
    local count=0
    while is_running && (( count < KILL_TIMEOUT )); do
        sleep 0.1
        ((count++))
    done
    if is_running; then
        pkill -9 -x "${PROC_NAME}" 2>/dev/null || true
        sleep 0.2
    fi
    if is_running; then
        send_notification "critical" "Error" \
            "Failed to stop ${PROC_NAME}" "dialog-error"
        exit 1
    fi
    send_notification "low" "Suspend Inhibited" \
        "Automatic suspend is now OFF (Coffee Mode ☕)." \
        "dialog-warning"
else
    if ! command -v "${PROC_NAME}" &>/dev/null; then
        send_notification "critical" "Error" \
            "${PROC_NAME} not found in PATH" "dialog-error"
        exit 1
    fi
    "${PROC_NAME}" &>/dev/null &
    disown
    sleep 0.3
    if ! is_running; then
        send_notification "critical" "Error" \
            "Failed to start ${PROC_NAME}" "dialog-error"
        exit 1
    fi
    send_notification "low" "Suspend Enabled" \
        "Automatic suspend is now ON." \
        "dialog-information"
fi
update_waybar
