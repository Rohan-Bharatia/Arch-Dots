#!/usr/bin/env bash

BAT_PATH=""
for bat in /sys/class/power_supply/BAT* /sys/class/power_supply/CW201*; do
    if [ -e "$bat/status" ]; then
        BAT_PATH="$bat"
        break
    fi
done
if [ -z "$BAT_PATH" ]; then
    echo ""
    exit 0
fi

STATUS=$(cat "$BAT_PATH/status")
CAPACITY=$(cat "$BAT_PATH/capacity")

if [ "$STATUS" == "Charging" ]; then
    echo "⚡ $CAPACITY%"
elif [ "$STATUS" == "Discharging" ]; then
    echo "$CAPACITY%"
elif [ "$STATUS" == "Full" ]; then
    echo "Full"
elif [ "$STATUS" == "Not charging" ]; then
    echo " $CAPACITY%"
else
    echo "$CAPACITY%"
fi
