#!/usr/bin/env bash

set -euo pipefail

CONFIG_FILE="$HOME/.config/hypr/source/keybinds.conf"
BOLD=$'\033[1m'
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[0;33m'
NC=$'\033[0m'

log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}
log_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}
log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}
log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1" >&2
}

cleanup() {
    :
}
trap cleanup EXIT

if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Configuration file not found at: $CONFIG_FILE"
    exit 1
fi

is_current_manager() {
    local manager="$1"
    if grep -q "^\$fileManager = $manager" "$CONFIG_FILE"; then
        return 0
    else
        return 1
    fi
}

switch_to_yazi() {
    if is_current_manager "yazi"; then
        log_success "System is already configured for Yazi. No changes made."
        return
    fi
    log_info "Switching configuration to Yazi..."
    sed -i 's/\$fileManager = nemo/\$fileManager = yazi/' "$CONFIG_FILE"
    sed -i 's/uwsm-app \$fileManager/uwsm-app -- \$terminal -e \$fileManager/' "$CONFIG_FILE"
    log_info "Updating XDG MIME defaults..."
    xdg-mime default yazi.desktop inode/directory
    log_success "Switched to Yazi successfully."
}

switch_to_thunar() {
    if is_current_manager "thunar"; then
        log_success "System is already configured for Thunar. No changes made."
        return
    fi
    log_info "Switching configuration to Thunar..."
    sed -i 's/\$fileManager = yazi/\$fileManager = thunar/' "$CONFIG_FILE"
    sed -i 's/uwsm-app -- \$terminal -e \$fileManager/uwsm-app \$fileManager/' "$CONFIG_FILE"
    log_info "Updating XDG MIME defaults..."
    xdg-mime default thunar.desktop inode/directory
    log_success "Switched to Thunar successfully."
}

switch_to_nemo() {
    if is_current_manager "nemo"; then
        log_success "System is already configured for Nemo. No changes made."
        return
    fi
    log_info "Switching configuration to Nemo..."
    sed -i 's/\$fileManager = yazi/\$fileManager = nemo/' "$CONFIG_FILE"
    sed -i 's/uwsm-app \$fileManager/uwsm-app -- \$terminal -e \$fileManager/' "$CONFIG_FILE"
    log_info "Updating XDG MIME defaults..."
    xdg-mime default yazi.desktop inode/directory
    log_success "Switched to nemo successfully."
}

printf "${BOLD}File Manager Switcher (UWSM/Hyprland)${NC}\n"
if is_current_manager "yazi"; then
    printf "Current Config: ${GREEN}Yazi${NC}\n"
elif is_current_manager "thunar"; then
    printf "Current Config: ${GREEN}Thunar${NC}\n"
elif is_current_manager "nemo"; then
    printf "Current Config: ${GREEN}Nemo${NC}\n"
else
    printf "Current Config: ${RED}Unknown / Neither${NC}\n"
fi
printf -- "--------------------------------------\n"
printf "1) Switch to ${BOLD}Yazi${NC} (Terminal) [Default]\n"
printf "2) Switch to ${BOLD}Thunar${NC} (GUI)\n"
printf "3) Switch to ${BOLD}Nemo${NC} (GUI)\n"
printf "q) Quit\n"
read -r -p "Select an option [1]: " choice
choice="${choice#"${choice%%[![:space:]]*}"}"
case "$choice" in
    1|yazi|Yazi|"")
        switch_to_yazi
        ;;
    2|thunar|Thunar)
        switch_to_thunar
        ;;
    3|nemo|Nemo)
        switch_to_nemo
        ;;
    q|Q)
        log_info "Exiting."
        exit 0
        ;;
    *)
        log_error "Invalid selection."
        exit 1
        ;;
esac
