#!/usr/bin/env bash

set -ufo pipefail

readonly APP_NAME="hyprsunset"
readonly TITLE_HINT="Hyprsunset"
readonly DEFAULT_TEMP=4500
readonly MIN_TEMP=1000
readonly MAX_TEMP=6000
readonly STARTUP_WAIT=5
readonly RESTART_COOLDOWN=3
readonly USER_ID="$(id -u)"
readonly RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${USER_ID}}"
readonly LOCK_FILE="${RUNTIME_DIR}/${APP_NAME}_slider.lock"
readonly STATE_FILE="${RUNTIME_DIR}/${APP_NAME}_last_temp"

die() {
    local msg="$1"
    printf 'FATAL: %s\n' "$msg" >&2
    command -v notify-send >/dev/null 2>&1 && \
        notify-send -u critical "${TITLE_HINT} Error" "$msg"
    exit 1
}

warn() {
    printf 'WARN: %s\n' "$1" >&2
}

check_dependencies() {
    local -a missing=()
    local cmd
    for cmd in yad hyprctl pgrep; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    (( ${#missing[@]} == 0 )) || die "Missing dependencies: ${missing[*]}"
    [[ -d "$RUNTIME_DIR" ]] || die "Runtime directory missing: ${RUNTIME_DIR}"
}

get_current_temp() {
    local val=""
    [[ -f "$STATE_FILE" && -r "$STATE_FILE" ]] && val=$(<"$STATE_FILE")
    if [[ "$val" =~ ^[0-9]+$ ]] && (( val >= MIN_TEMP && val <= MAX_TEMP )); then
        printf '%d' "$val"
    else
        printf '%d' "$DEFAULT_TEMP"
    fi
}

save_current_temp() {
    printf '%d' "$1" > "$STATE_FILE" 2>/dev/null || \
        warn "Failed to save state to ${STATE_FILE}"
}

clamp_temp() {
    local val=$1
    (( val < MIN_TEMP )) && val=$MIN_TEMP
    (( val > MAX_TEMP )) && val=$MAX_TEMP
    printf '%d' "$val"
}

is_daemon_running() {
    pgrep -u "$USER_ID" -x "$APP_NAME" >/dev/null 2>&1
}

wait_for_daemon() {
    local deadline=$((SECONDS + STARTUP_WAIT))
    while (( SECONDS < deadline )); do
        is_daemon_running && return 0
        sleep 0.2
    done
    return 1
}

wait_for_ipc() {
    local temp=$1
    local deadline=$((SECONDS + STARTUP_WAIT))
    while (( SECONDS < deadline )); do
        hyprctl hyprsunset temperature "$temp" >/dev/null 2>&1 && return 0
        sleep 0.2
    done
    return 1
}

start_daemon() {
    printf 'Starting %s...\n' "$APP_NAME" >&2
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl --user start "$APP_NAME" 2>/dev/null; then
            wait_for_daemon && {
                wait_for_ipc "$(get_current_temp)" && return 0
            }
        fi
    fi
    if ! is_daemon_running; then
        local bin_path
        bin_path=$(command -v "$APP_NAME" 2>/dev/null)
        if [[ -z "$bin_path" ]]; then
            die "Binary '${APP_NAME}' not found in PATH"
        fi
        setsid "$bin_path" </dev/null >/dev/null 2>&1 &
    fi
    wait_for_ipc "$(get_current_temp)"
}

focus_existing_window() {
    local addr=""
    if command -v jq >/dev/null 2>&1; then
        addr=$(hyprctl clients -j 2>/dev/null | \
               jq -r --arg t "$TITLE_HINT" \
               'first(.[] | select(.title == $t) | .address) // empty' 2>/dev/null) || true
        if [[ -n "$addr" ]]; then
            hyprctl dispatch focuswindow "address:${addr}" >/dev/null 2>&1
            return 0
        fi
    fi
    hyprctl dispatch focuswindow "title:^${TITLE_HINT}\$" >/dev/null 2>&1 && return 0
    command -v wmctrl >/dev/null 2>&1 && wmctrl -a "$TITLE_HINT" 2>/dev/null
    return 0
}

acquire_lock() {
    exec 9>"$LOCK_FILE" || die "Cannot create lock file: ${LOCK_FILE}"
    if ! flock -n 9; then
        focus_existing_window
        exit 0
    fi
}

cleanup() {
    exec 9>&- 2>/dev/null
    rm -f "$LOCK_FILE" 2>/dev/null
}

check_dependencies
acquire_lock
trap cleanup EXIT INT TERM HUP
local current_temp last_restart_attempt=0
current_temp=$(get_current_temp)
save_current_temp "$current_temp"
is_daemon_running || start_daemon || warn "Daemon start failed; continuing anyway"
local -ra yad_cmd=(
    yad
    --title="$TITLE_HINT"
    --class="$TITLE_HINT"
    --scale
    --text="󰡬"
    --text-align=center
    --min-value="$MIN_TEMP"
    --max-value="$MAX_TEMP"
    --value="$current_temp"
    --step=50
    --show-value
    --print-partial
    --width=420
    --height=90
    --window-icon=preferences-system
    --button="Close":1
    --buttons-layout=center
    --fixed
)
local new_temp now
while IFS= read -r new_temp; do
    new_temp="${new_temp%%.*}"
    new_temp="${new_temp//[!0-9]/}"
    [[ -z "$new_temp" ]] && continue
    [[ ! "$new_temp" =~ ^[0-9]+$ ]] && continue
    new_temp=$(clamp_temp "$new_temp")
    (( new_temp == current_temp )) && continue
    if ! hyprctl hyprsunset temperature "$new_temp" >/dev/null 2>&1; then
        printf -v now '%(%s)T' -1
        if (( now - last_restart_attempt > RESTART_COOLDOWN )); then
            last_restart_attempt=$now
            if ! is_daemon_running; then
                start_daemon || true
            fi
            hyprctl hyprsunset temperature "$new_temp" >/dev/null 2>&1 || true
        fi
    fi
    current_temp=$new_temp
    save_current_temp "$current_temp"
done < <("${yad_cmd[@]}")
