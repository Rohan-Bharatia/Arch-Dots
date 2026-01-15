#!/bin/bash

set -euo pipefail

declare -r C_GREEN="#50fa7b"
declare -r C_RED="#ff5555"
declare -r C_CYAN="#8be9fd"
declare -r C_PURPLE="#bd93f9"
declare -r C_ORANGE="#ffb86c"
declare -r C_TEXT="#f8f8f2"

(( EUID == 0 )) || { echo "Run as root"; exit 1; }

for c in gum awk; do
    command -v "$c" &>/dev/null || {
        echo "Missing: $c"
        exit 1
    }
done

notify_ok() {
    gum style --foreground "$C_GREEN" "✓ $1"
}
notify_err() {
    gum style --foreground "$C_RED" "✗ $1"
}
notify_info() {
    gum style --foreground "$C_CYAN" "➜ $1"
}

get_power_source() {
    local ac=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -n1)
    [[ "$ac" == "1" ]] && echo "AC" || echo "Battery"
}

battery_info() {
    local cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)
    local status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1)
    echo "${cap:-?}% (${status:-Unknown})"
}

cpu_temp() {
    sensors 2>/dev/null | awk '/Package id 0|Tctl|CPU Temp/ { gsub(/\+|°C/, "", $NF); print $NF; exit }'
}

get_power_profile() {
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl get
    elif command -v tlp-stat &>/dev/null; then
        tlp-stat -s | awk '/Mode/ {print $3}'
    else
        echo "Unknown"
    fi
}

dashboard() {
    clear
    gum style --border double --align center --width 60 --foreground "$C_PURPLE" "Universal Laptop Control"
    gum join --horizontal "$(gum style --border rounded --width 18 "Power" "$(get_power_source)")" \
                          "$(gum style --border rounded --width 18 "Battery" "$(battery_info)")" \
                          "$(gum style --border rounded --width 18 "CPU Temp" "$(cpu_temp)°C")"
    echo
    gum style --foreground "$C_TEXT" "Active Profile: $(get_power_profile)"
    echo
}

menu_profiles() {
    if command -v powerprofilesctl &>/dev/null; then
        local choice=$(gum choose performance balanced power-saver Back)
        [[ "$choice" == "Back" ]] && return
        powerprofilesctl set "$choice" && notify_ok "Profile set to $choice"
    elif command -v tlp &>/dev/null; then
        local choice=$(gum choose AC Battery Back)
        [[ "$choice" == "Back" ]] && return
        tlp setcharge "$choice" &>/dev/null
        notify_ok "TLP mode applied"
    else
        notify_err "No power manager available"
    fi
    sleep 1
}

menu_battery_limit() {
    command -v tlp &>/dev/null || {
        notify_err "TLP not installed"
        sleep 1
        return
    }
    local limit=$(gum input --placeholder "Enter limit (50-100)")
    [[ -z "$limit" ]] && return
    if ! [[ "$limit" =~ ^[0-9]+$ ]] || (( limit < 50 || limit > 100 )); then
        notify_err "Invalid range"
        sleep 1
        return
    fi
    tlp setcharge "$limit" "$limit" &>/dev/null &&
        notify_ok "Charge limit set to $limit%"
    sleep 1
}

menu_keyboard() {
    local led=$(ls /sys/class/leds | grep -i kbd_backlight | head -n1)
    [[ -z "$led" ]] && {
        notify_err "No keyboard backlight found"
        sleep 1
        return
    }
    local max=$(cat /sys/class/leds/$led/max_brightness)
    local cur=$(cat /sys/class/leds/$led/brightness)
    local val=$(gum input --value "$cur" --placeholder "0-$max")
    [[ -z "$val" ]] && return
    echo "$val" > /sys/class/leds/$led/brightness &&
        notify_ok "Brightness set"
    sleep 0.5
}

while true; do
    dashboard
    choice=$(gum choose "Power Profiles" \
                        "Battery Charge Limit" \
                        "Keyboard Backlight" \
                        "Quit")
    case "$choice" in
        "Power Profiles")
            menu_profiles
            ;;
        "Battery Charge Limit")
            menu_battery_limit
            ;;
        "Keyboard Backlight")
            menu_keyboard
            ;;
        "Quit")
            exit 0
            ;;
    esac
done
