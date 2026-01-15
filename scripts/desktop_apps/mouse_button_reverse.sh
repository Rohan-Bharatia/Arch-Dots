#!/usr/bin/env bash
# ==============================================================================

set -euo pipefail

readonly CONFIG_FILE="${HOME}/.config/hypr/source/input.conf"

cleanup() {
    [[ -f "${TEMP_FILE:-}" ]] && rm -f "$TEMP_FILE" || true
}
trap cleanup EXIT

if [[ ! -f "$CONFIG_FILE" ]]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    printf "input {\n}\n" > "$CONFIG_FILE"
fi
local current_mode="Right-Handed (Standard)"
local target_val="true"
local prompt_action="Switch to Left-Handed (Reverse)"
if grep -qE '^[[:space:]]*left_handed[[:space:]]*=[[:space:]]*true' "$CONFIG_FILE"; then
    current_mode="Left-Handed (Reversed)"
    target_val="false"
    prompt_action="Switch to Right-Handed (Standard)"
fi
printf "Current Status: %s\n" "$current_mode"
printf "%s? [Y/n]: " "$prompt_action"
read -r -n 1 user_input < /dev/tty
printf "\n"
if [[ "$user_input" =~ ^[Yy]$ ]] || [[ -z "$user_input" ]]; then
    TEMP_FILE=$(mktemp)
    awk -v target_val="$target_val" '
    BEGIN { inside_input = 0; modified = 0 }

    # Detect start of input block
    /^input[[:space:]]*\{/ {
        inside_input = 1
        print $0
        next
    }

    # Detect end of input block
    inside_input && /^\}/ {
        if (modified == 0) {
            print "    left_handed = " target_val
            modified = 1
        }
        inside_input = 0
        print $0
        next
    }

    # Detect existing key inside input block
    inside_input && /^[[:space:]]*left_handed[[:space:]]*=/ {
        sub(/=.*/, "= " target_val)
        modified = 1
        print $0
        next
    }

    { print }
    ' "$CONFIG_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$CONFIG_FILE"
    if pgrep -x "Hyprland" > /dev/null; then
        command -v hyprctl >/dev/null && hyprctl reload > /dev/null 2>&1 || true
    fi
    printf "Success: Configuration updated to %s (left_handed = %s).\n" "${prompt_action%% *}" "$target_val"
else
    printf "No changes made.\n"
fi
