#!/usr/bin/env bash

wallpaper_dir="$HOME/.local/share/wallpapers"
output_file="$HOME/.cache/current_wallpaper"

selected_path=$(
    find "$wallpaper_dir" -maxdepth 1 -type f \
        \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) |
        while read -r file; do
            printf '%s\0icon\x1f%s\n' "$file" "$file"
        done |
        rofi -dmenu -show-icons -p "Wallpaper"
)

[ -z "$selected_path" ] && exit 0

echo "Selected: '$selected_path'"

printf '%s\n' "$selected_path" >"$output_file"

matugen image "$selected_path" --mode dark --source-color-index 0
awww img "$selected_path" -t any
