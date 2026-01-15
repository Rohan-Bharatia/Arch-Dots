#!/usr/bin/env bash

IS_CAPS=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .capsLock')

if [ "$IS_CAPS" == "true" ]; then
    echo "CAPS LOCK"
else
    echo ""
fi
