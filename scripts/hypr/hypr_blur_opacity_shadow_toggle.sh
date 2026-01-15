#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly CONFIG_FILE="${HOME}/.config/hypr/conf/appearance.conf"
readonly OP_ACTIVE_ON="0.8"
readonly OP_INACTIVE_ON="0.6"
readonly OP_ACTIVE_OFF="1.0"
readonly OP_INACTIVE_OFF="1.0"

die() {
    local message="$1"
    printf 'Error: %s\n' "$message" >&2
    if command -v notify-send &>/dev/null; then
        notify-send -u critical "Hyprland Error" "$message" 2>/dev/null || true
    fi
    exit 1
}

notify() {
    local message="$1"
    if command -v notify-send &>/dev/null; then
        notify-send -h string:x-canonical-private-synchronous:hypr-visuals \
            -t 1500 "Hyprland" "$message" 2>/dev/null || true
    fi
}

get_current_blur_state() {
    local state
    state=$(awk '
        /^[[:space:]]*blur[[:space:]]*\{/ { in_block = 1; next }
        in_block && /^[[:space:]]*enabled[[:space:]]*=[[:space:]]*true/  { found = "on" }
        in_block && /^[[:space:]]*enabled[[:space:]]*=[[:space:]]*false/ { found = "off" }
        in_block && /\}/  { in_block = 0 }
        END { print (found ? found : "off") }
    ' "$CONFIG_FILE" 2>/dev/null) || state="off"
    printf '%s' "$state"
}

show_help() {
    cat <<EOF
Usage: ${0##*/} [OPTION]

Control Hyprland visual effects (blur, shadow, opacity).

Options:
  on, enable, 1, true     Enable blur, shadow, and transparency
  off, disable, 0, false  Disable blur/shadow, set opacity to 1.0
  toggle                  Toggle based on current state (default)
  -h, --help              Show this help message

Configuration:
  Config file: ${CONFIG_FILE}

  Opacity when ON:  active=${OP_ACTIVE_ON}, inactive=${OP_INACTIVE_ON}
  Opacity when OFF: active=${OP_ACTIVE_OFF}, inactive=${OP_INACTIVE_OFF}

Examples:
  ${0##*/}           # Toggle current state
  ${0##*/} on        # Enable all visual effects
  ${0##*/} off       # Disable for performance
EOF
}

[[ -e "$CONFIG_FILE" ]] || die "Config file not found: $CONFIG_FILE"
[[ -f "$CONFIG_FILE" ]] || die "Config path is not a regular file: $CONFIG_FILE"
[[ -r "$CONFIG_FILE" ]] || die "Config file not readable: $CONFIG_FILE"
[[ -w "$CONFIG_FILE" ]] || die "Config file not writable: $CONFIG_FILE"
command -v hyprctl &>/dev/null || die "hyprctl not found in PATH. Is Hyprland installed?"
TARGET_STATE=""
case "${1:-toggle}" in
    on|ON|enable|1|true|yes)
        TARGET_STATE="on"
        ;;
    off|OFF|disable|0|false|no)
        TARGET_STATE="off"
        ;;
    toggle|"")
        if [[ "$(get_current_blur_state)" == "on" ]]; then
            TARGET_STATE="off"
        else
            TARGET_STATE="on"
        fi
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    *)
        printf 'Unknown argument: %s\n\n' "$1" >&2
        show_help >&2
        exit 1
        ;;
esac
declare NEW_ENABLED NEW_ACTIVE NEW_INACTIVE NOTIFY_MSG
if [[ "$TARGET_STATE" == "on" ]]; then
    NEW_ENABLED="true"
    NEW_ACTIVE="$OP_ACTIVE_ON"
    NEW_INACTIVE="$OP_INACTIVE_ON"
    NOTIFY_MSG="Visuals: Max (Blur/Shadow ON)"
else
    NEW_ENABLED="false"
    NEW_ACTIVE="$OP_ACTIVE_OFF"
    NEW_INACTIVE="$OP_INACTIVE_OFF"
    NOTIFY_MSG="Visuals: Performance (Blur/Shadow OFF)"
fi
if ! sed -i \
    -e "/^[[:space:]]*blur[[:space:]]*{/,/}/ s/\(enabled[[:space:]]*=[[:space:]]*\)[a-z][a-z]*/\1${NEW_ENABLED}/" \
    -e "/^[[:space:]]*shadow[[:space:]]*{/,/}/ s/\(enabled[[:space:]]*=[[:space:]]*\)[a-z][a-z]*/\1${NEW_ENABLED}/" \
    -e "s/^\([[:space:]]*active_opacity[[:space:]]*=[[:space:]]*\)[0-9][0-9.]*/\1${NEW_ACTIVE}/" \
    -e "s/^\([[:space:]]*inactive_opacity[[:space:]]*=[[:space:]]*\)[0-9][0-9.]*/\1${NEW_INACTIVE}/" \
    "$CONFIG_FILE" 2>&1; then
    die "Failed to update config file: $CONFIG_FILE"
fi
declare -a HYPR_CMDS=(
    "decoration:blur:enabled ${NEW_ENABLED}"
    "decoration:shadow:enabled ${NEW_ENABLED}"
    "decoration:active_opacity ${NEW_ACTIVE}"
    "decoration:inactive_opacity ${NEW_INACTIVE}"
)
hypr_errors=0
for cmd in "${HYPR_CMDS[@]}"; do
    # shellcheck disable=SC2086  # Intentional word splitting
    if ! hyprctl keyword $cmd &>/dev/null; then
        ((hypr_errors++)) || true
    fi
done
if ((hypr_errors > 0)); then
    printf 'Warning: %d hyprctl command(s) failed. Is Hyprland running?\n' "$hypr_errors" >&2
fi
notify "$NOTIFY_MSG"
