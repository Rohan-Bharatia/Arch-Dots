#!/usr/bin/env bash

set -euo pipefail

IFS=$'\n\t'

readonly C_RED=$'\e[31m'
readonly C_GREEN=$'\e[32m'
readonly C_YELLOW=$'\e[33m'
readonly C_BLUE=$'\e[34m'
readonly C_BOLD=$'\e[1m'
readonly C_RESET=$'\e[0m'

cleanup_trap() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        printf "%s[ERROR]%s Script aborted unexpectedly (Exit Code: %d).\n" \
            "$C_RED" "$C_RESET" "$exit_code" >&2
    fi
}
trap cleanup_trap EXIT

if ! command -v jq &> /dev/null; then
    printf "%s[ERROR]%s 'jq' is missing. Install it with: sudo pacman -S jq\n" \
        "$C_RED" "$C_RESET" >&2
    exit 1
fi
if [[ $EUID -eq 0 ]]; then
    printf "%s[ERROR]%s Root detected. Please run this as your normal user to access the Hyprland socket.\n" \
        "$C_RED" "$C_RESET" >&2
    exit 1
fi
DIRECTION=0
if [[ $# -ne 1 ]]; then
    printf "%s[INFO]%s Usage: %s [+90|-90]\n" \
        "$C_YELLOW" "$C_RESET" "${0##*/}"
    exit 1
fi
case "$1" in
    "+90")
        DIRECTION=1
        ;;
    "-90")
        DIRECTION=-1
        ;;
    *)
        printf "%s[ERROR]%s Invalid flag '%s'. Use +90 or -90.\n" "$C_RED" "$C_RESET" "$1" >&2
        exit 1
        ;;
esac
MON_STATE=$(hyprctl monitors -j)
NAME=$(printf "%s" "$MON_STATE" | jq -r '.[0].name')
SCALE=$(printf "%s" "$MON_STATE" | jq -r '.[0].scale')
CURRENT_TRANSFORM=$(printf "%s" "$MON_STATE" | jq -r '.[0].transform')
if [[ -z "$NAME" || "$NAME" == "null" ]]; then
    printf "%s[ERROR]%s No active monitors detected via Hyprland IPC.\n" \
        "$C_RED" "$C_RESET" >&2
    exit 1
fi
NEW_TRANSFORM=$(( (CURRENT_TRANSFORM + DIRECTION + 4) % 4 ))
printf "%s[INFO]%s Rotating %s%s%s (Scale: %s): %d -> %d\n" \
    "$C_BLUE" "$C_RESET" "$C_BOLD" "$NAME" "$C_RESET" "$SCALE" "$CURRENT_TRANSFORM" "$NEW_TRANSFORM"
if hyprctl keyword monitor "${NAME}, preferred, auto, ${SCALE}, transform, ${NEW_TRANSFORM}" > /dev/null; then
    printf "%s[SUCCESS]%s Rotation applied successfully.\n" \
        "$C_GREEN" "$C_RESET"
    if command -v notify-send &> /dev/null; then
        notify-send -a "System" "Display Rotated" "Monitor: $NAME\nTransform: $NEW_TRANSFORM" -h string:x-canonical-private-synchronous:display-rotate
    fi
else
    printf "%s[ERROR]%s Failed to apply Hyprland keyword.\n" \
        "$C_RED" "$C_RESET" >&2
    exit 1
fi
trap - EXIT
