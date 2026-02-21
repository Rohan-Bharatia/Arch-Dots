#!/usr/bin/env bash

set -euo pipefail

readonly WALLPAPER_DIR="${HOME}/Pictures/wallpapers"
readonly -a SWWW_OPTS=(
    --transition-type grow
    --transition-duration 2
    --transition-fps 60
)
readonly DAEMON_INIT_RETRIES=25

die() {
    printf '%s: %s\n' "${0##*/}" "$1" >&2
    exit 1
}

for cmd in swww matugen uwsm-app; do
    command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: '$cmd'"
done
[[ -d "$WALLPAPER_DIR" ]] || die "Directory does not exist: '$WALLPAPER_DIR'"
[[ -r "$WALLPAPER_DIR" ]] || die "Directory is not readable: '$WALLPAPER_DIR'"
if ! swww query >/dev/null 2>&1; then
    uwsm-app -- swww-daemon >/dev/null 2>&1 &
    for ((i = 0; i < DAEMON_INIT_RETRIES; i++)); do
        swww query >/dev/null 2>&1 && break
        sleep 0.2
    done
    swww query >/dev/null 2>&1 || die "swww daemon failed to initialize"
fi
shopt -s globstar nullglob nocaseglob
wallpapers=("$WALLPAPER_DIR"/**/*.{jpg,jpeg,png,webp,gif})
if ((${#wallpapers[@]} == 0)); then
    die "No image files found in '$WALLPAPER_DIR'"
fi
target_wallpaper="${wallpapers[RANDOM % ${#wallpapers[@]}]}"
[[ -r "$target_wallpaper" ]] || die "Image not readable: '$target_wallpaper'"
swww img "$target_wallpaper" "${SWWW_OPTS[@]}"
setsid uwsm-app -- matugen --mode dark --type scheme-fruit-salad --source-color-index 0 image "$target_wallpaper" \
    >/dev/null 2>&1 &
WALLPAPER=$(swww query | grep -oP 'image: \K.*' | head -1)
cp "$WALLPAPER" ~/.cache/current_wallpaperp "$WALLPAPER" ~/.cache/current_wallpaper
