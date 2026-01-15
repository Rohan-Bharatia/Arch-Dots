#!/bin/bash

if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    exit 0
fi
if ! command -v rofi &> /dev/null || ! command -v qalc &> /dev/null || ! command -v wl-copy &> /dev/null; then
    notify-send "Error" "Missing dependencies: rofi, libqalculate, or wl-copy" -u critical
    exit 1
fi

last_equation=""
last_result=""

while true; do
    if [ -z "$last_result" ]; then
        display_mesg="<i>Type an equation (e.g., 50*5) and hit Enter</i>"
    else
        display_mesg="<b>$last_equation</b> = <span color='#a6e3a1'>$last_result</span>"
    fi
    current_input=$(rofi -dmenu \
        -i \
        -lines 0 \
        -theme ~/.config/rofi/config.rasi \
        -no-show-icons \
        -p " Calc" \
        -mesg "$display_mesg")
    if [ $? -ne 0 ]; then
        exit 0
    fi
    if [ -n "$current_input" ]; then
        calculation=$(qalc -t "$current_input")
        last_equation="$current_input"
        last_result="$calculation"
        echo -n "$last_result" | wl-copy
    fi
done
