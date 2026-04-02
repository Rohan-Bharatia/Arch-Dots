#!/bin/bash

WALLPAPER=$(awww query | grep -oP 'image: \K.*' | head -1)
cp "$WALLPAPER" ~/.cache/current_wallpaper
hyprlock
