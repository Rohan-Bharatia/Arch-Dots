#!/usr/bin/env bash

set -euo pipefail

readonly WAYBAR_BIN_NAME="waybar"
readonly SPECIAL_WORKSPACE_NAME="special:magic"

WAYBAR_BIN_PATH=""
_IS_CURRENTLY_ON_SPECIAL="false"
HYPRLAND_SOCKET2=""

find_waybar_binary() {
    WAYBAR_BIN_PATH=$(command -v "$WAYBAR_BIN_NAME" 2>/dev/null) || exit 1
}

check_dependencies() {
    local cmd
    for cmd in hyprctl jq socat pgrep pkill flock; do
        command -v "$cmd" &>/dev/null || exit 1
    done
}

is_waybar_running() {
    pgrep -x "$WAYBAR_BIN_NAME" &>/dev/null
}

start_waybar() {
    [[ "$_IS_CURRENTLY_ON_SPECIAL" != "true" ]] || return 0
    is_waybar_running && return 0
    "$WAYBAR_BIN_PATH" </dev/null &>/dev/null &
    disown "$!" 2>/dev/null || true
}

kill_waybar() {
    pkill -x "$WAYBAR_BIN_NAME" 2>/dev/null || true
}

find_hyprland_socket() {
    [[ -n "${XDG_RUNTIME_DIR:-}" ]] || return 1
    local hyprctl_output sig
    hyprctl_output=$(hyprctl instances -j 2>/dev/null) || return 1
    [[ -n "$hyprctl_output" ]] || return 1
    sig=$(jq -re '.[0].instance // empty' <<< "$hyprctl_output" 2>/dev/null) || return 1
    HYPRLAND_SOCKET2="${XDG_RUNTIME_DIR}/hypr/${sig}/.socket2.sock"
    [[ -S "$HYPRLAND_SOCKET2" ]] || return 1
    return 0
}

update_waybar_visibility() {
    local hypr_output ws_name fullscreen_state jq_result
    if hypr_output=$(hyprctl -j activewindow 2>/dev/null); then
        if [[ -n "$hypr_output" && "$hypr_output" != "{}" && "$hypr_output" != "null" ]]; then
            if jq_result=$(jq -re '[(.workspace.name // ""), (.fullscreen // 0)] | @tsv' <<< "$hypr_output" 2>/dev/null); then
                IFS=$'\t' read -r ws_name fullscreen_state <<< "$jq_result"
                if [[ "$ws_name" == "$SPECIAL_WORKSPACE_NAME" ]]; then
                    _IS_CURRENTLY_ON_SPECIAL="true"
                    kill_waybar
                    return 0
                fi
                _IS_CURRENTLY_ON_SPECIAL="false"
                case "$fullscreen_state" in
                    1|2)
                        kill_waybar
                        ;;
                    *)
                        start_waybar
                        ;;
                esac
                return 0
            fi
        fi
    fi
    if hypr_output=$(hyprctl -j activeworkspace 2>/dev/null) && [[ -n "$hypr_output" ]]; then
        ws_name=$(jq -r '.name // ""' <<< "$hypr_output" 2>/dev/null) || ws_name=""
        if [[ "$ws_name" == "$SPECIAL_WORKSPACE_NAME" ]]; then
            _IS_CURRENTLY_ON_SPECIAL="true"
            kill_waybar
            return 0
        fi
    fi
    _IS_CURRENTLY_ON_SPECIAL="false"
    start_waybar
}

readonly LOCK_DIR="${XDG_RUNTIME_DIR:-/tmp}"
readonly LOCK_FILE="${LOCK_DIR}/waybar_visibility_manager.lock"

cleanup() {
    rm -f "$LOCK_FILE" 2>/dev/null || true
}

setup_lock() {
    [[ -d "$LOCK_DIR" ]] || exit 1
    : > "$LOCK_FILE" 2>/dev/null || exit 1
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
        exit 1
    fi
    echo $$ >&9
    trap cleanup EXIT INT TERM HUP
}

setup_lock
find_waybar_binary
check_dependencies
find_hyprland_socket || exit 1
update_waybar_visibility
local event_line event_type event_payload special_name
while IFS= read -r event_line || [[ -n "$event_line" ]]; do
    event_type="${event_line%%>>*}"
    event_payload="${event_line#*>>}"
    case "$event_type" in
        activespecial)
            special_name="${event_payload%%,*}"
            if [[ "$special_name" == "$SPECIAL_WORKSPACE_NAME" ]]; then
                if [[ "$_IS_CURRENTLY_ON_SPECIAL" == "false" ]]; then
                    _IS_CURRENTLY_ON_SPECIAL="true"
                    kill_waybar
                fi
            elif [[ "$_IS_CURRENTLY_ON_SPECIAL" == "true" ]]; then
                update_waybar_visibility
            fi
            ;;
        workspace)
            update_waybar_visibility
            ;;
        fullscreen|activewindow)
            [[ "$_IS_CURRENTLY_ON_SPECIAL" == "false" ]] && update_waybar_visibility
            ;;
    esac
done < <(socat -u "UNIX-CONNECT:${HYPRLAND_SOCKET2}" - 2>/dev/null)
