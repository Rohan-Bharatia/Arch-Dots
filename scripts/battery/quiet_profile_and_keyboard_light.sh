#!/bin/bash

set -o pipefail

(( EUID == 0 )) || exit 0

{
    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set power-saver
    elif command -v tlp >/dev/null 2>&1; then
        tlp setcharge BAT
        tlp start
    fi
} >/dev/null 2>&1 || true

{
    for led in /sys/class/leds/*kbd_backlight*/brightness; do
        [[ -w "$led" ]] && echo 0 > "$led"
    done
} >/dev/null 2>&1 || true

exit 0
