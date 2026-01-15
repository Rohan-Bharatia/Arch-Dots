#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly R=$'\e[31m'
readonly G=$'\e[32m'
readonly Y=$'\e[33m'
readonly B=$'\e[34m'
readonly RESET=$'\e[0m'
readonly BOLD=$'\e[1m'
readonly PACMAN_CACHE="/var/cache/pacman/pkg"
readonly PARU_CACHE="${HOME}/.cache/paru"
readonly YAY_CACHE="${HOME}/.cache/yay"

log() {
    printf "%s%s%s %s\n" "${B}" "::" "${RESET}" "$1"
    sleep 0.5
}

get_dir_size_mb() {
    local target="$1"
    if [[ ! -d "$target" ]]; then
        echo "0"
        return
    fi
    if [[ -w "$target" ]]; then
        du -sm "$target" 2>/dev/null | cut -f1
    else
        sudo du -sm "$target" 2>/dev/null | cut -f1
    fi
}

echo -e "${BOLD}Starting Aggressive Cache Cleanup...${RESET}"
sleep 0.5
local has_paru=false
local has_yay=false
if command -v paru &>/dev/null; then has_paru=true; fi
if command -v yay &>/dev/null; then has_yay=true; fi
if [[ "$has_paru" == "false" && "$has_yay" == "false" ]]; then
    echo -e "${Y}Warning: No AUR helpers (yay/paru) detected. Cleaning Pacman only.${RESET}"
fi
log "Measuring current cache usage..."
local pacman_start
local paru_start=0
local yay_start=0
pacman_start=$(get_dir_size_mb "$PACMAN_CACHE")
echo -e "   ${BOLD}Pacman Cache:${RESET} ${pacman_start} MB"
if [[ "$has_paru" == "true" ]]; then
    paru_start=$(get_dir_size_mb "$PARU_CACHE")
    echo -e "   ${BOLD}Paru Cache:${RESET}   ${paru_start} MB"
fi
if [[ "$has_yay" == "true" ]]; then
    yay_start=$(get_dir_size_mb "$YAY_CACHE")
    echo -e "   ${BOLD}Yay Cache:${RESET}    ${yay_start} MB"
fi
local total_start=$((pacman_start + paru_start + yay_start))
sleep 0.5
log "Purging Pacman cache (System)..."
if sudo -v; then
    if [[ -d "$PACMAN_CACHE" ]]; then
        if sudo find "$PACMAN_CACHE" -maxdepth 1 -type d -name "download-*" -print -quit | grep -q .; then
             echo -e "   ${Y}Found stuck download directories. Removing...${RESET}"
             sudo find "$PACMAN_CACHE" -maxdepth 1 -type d -name "download-*" -exec rm -rf {} +
        fi
    fi
    yes | sudo pacman -Scc > /dev/null 2>&1 || true
    echo -e "   ${G}✔ Pacman cache cleared.${RESET}"
else
    echo -e "   ${R}✘ Sudo authentication failed. Skipping Pacman.${RESET}"
fi
sleep 0.5
if [[ "$has_paru" == "true" ]]; then
    log "Purging Paru cache (AUR)..."
    yes | paru -Scc > /dev/null 2>&1 || true
    echo -e "   ${G}✔ Paru cache cleared.${RESET}"
fi
if [[ "$has_yay" == "true" ]]; then
    log "Purging Yay cache (AUR)..."
    yes | yay -Scc > /dev/null 2>&1 || true
    echo -e "   ${G}✔ Yay cache cleared.${RESET}"
fi
sleep 0.5
log "Calculating reclaimed space..."
local pacman_end
local paru_end=0
local yay_end=0
pacman_end=$(get_dir_size_mb "$PACMAN_CACHE")
if [[ "$has_paru" == "true" ]]; then paru_end=$(get_dir_size_mb "$PARU_CACHE"); fi
if [[ "$has_yay" == "true" ]]; then yay_end=$(get_dir_size_mb "$YAY_CACHE"); fi
local total_end=$((pacman_end + paru_end + yay_end))
local saved=$((total_start - total_end))
echo ""
echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD}       DISK SPACE RECLAIMED REPORT      ${RESET}"
echo -e "${BOLD}========================================${RESET}"
printf "${BOLD}Initial Usage:${RESET} %s MB\n" "$total_start"
printf "${BOLD}Final Usage:${RESET}   %s MB\n" "$total_end"
echo -e "${BOLD}----------------------------------------${RESET}"
if [[ $saved -gt 0 ]]; then
    printf "${G}${BOLD}TOTAL CLEARED:${RESET} ${G}%s MB${RESET}\n" "$saved"
else
    printf "${Y}${BOLD}TOTAL CLEARED:${RESET} ${Y}0 MB (Already Clean)${RESET}\n"
fi
echo -e "${BOLD}========================================${RESET}"
