#!/usr/bin/env bash

set -u
set -o pipefail

XDG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
ANIM_DIR="$XDG_CONFIG/hypr/source/animations"
LINK_DIR="$ANIM_DIR/active"
LINK_FILE="$LINK_DIR/active.conf"
ICON_ACTIVE=""
ICON_FILE=""
ICON_ERROR=""

notify_user() {
    local title="$1"
    local message="$2"
    local urgency="${3:-low}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" -a "Hyprland Animations" "$title" "$message"
    fi
}

reload_hyprland() {
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload >/dev/null
    fi
}

selection="${ROFI_INFO:-}"
if [[ -z "$selection" && -n "${1:-}" ]]; then
    clean_name=$(echo "$1" | sed 's/<[^>]*>//g' | xargs)
    selection="$ANIM_DIR/$clean_name"
fi
if [[ -n "$selection" ]]; then
    if [[ ! -f "$selection" ]]; then
        notify_user "Error" "File not found: $selection" "critical"
        exit 1
    fi
    mkdir -p "$LINK_DIR"
    if ln -nfs "$selection" "$LINK_FILE"; then
        filename=$(basename "$selection")
        reload_hyprland
        notify_user "Success" "Switched to: $filename"
    else
        notify_user "Failure" "Could not create symlink." "critical"
        exit 1
    fi
    exit 0
fi

echo -e "\0prompt\x1fAnimations"
echo -e "\0markup-rows\x1ftrue"
echo -e "\0no-custom\x1ftrue"
echo -e "\0message\x1fSelect a configuration to apply instantly"

if [[ ! -d "$ANIM_DIR" ]]; then
    echo -e "Directory Missing\0icon\x1f$ICON_ERROR\x1finfo\x1fignore"
    exit 0
fi
current_active=$(readlink -f "$LINK_FILE" 2>/dev/null || echo "")
shopt -s nullglob
files=("$ANIM_DIR"/*.conf)

if [ ${#files[@]} -eq 0 ]; then
    echo -e "No .conf files found\0icon\x1f$ICON_ERROR\x1finfo\x1fignore"
    exit 0
fi
for i in "${!files[@]}"; do
    if [[ "${files[$i]}" == "$current_active" ]]; then
        echo -e "\0active\x1f$i"
        break
    fi
done
for file in "${files[@]}"; do
    filename=$(basename "$file")
    if [[ "$file" == "$current_active" ]]; then
          echo -e "<span weight='bold'>${filename}</span> <span size='small' style='italic'>(Active)</span>\0icon\x1f${ICON_ACTIVE}\x1finfo\x1f${file}"
    else
        echo -e "${filename}\0icon\x1f${ICON_FILE}\x1finfo\x1f${file}"
    fi
done
