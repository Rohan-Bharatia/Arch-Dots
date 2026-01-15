#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

readonly WAYPAPER_CONFIG="${HOME}/.config/waypaper/config.ini"
readonly RANDOM_THEME="${HOME}/.user_scripts/theme_matugen/random_theme.sh"
readonly SYMLINK_SCRIPT="${HOME}/.user_scripts/theme_matugen/dark_light_directory_switch.sh"
readonly C_RESET=$'\033[0m'
readonly C_GREEN=$'\033[1;32m'
readonly C_BLUE=$'\033[1;34m'
readonly C_RED=$'\033[1;31m'

DEFAULT_MODE="dark"
DEFAULT_TYPE="disable"
DEFAULT_CONTRAST="disable"
TARGET_MODE="$DEFAULT_MODE"
TARGET_TYPE="$DEFAULT_TYPE"
TARGET_CONTRAST="$DEFAULT_CONTRAST"

log_info() {
    printf "${C_BLUE}[INFO]${C_RESET} %s\n" "$1"
}
log_succ() {
    printf "${C_GREEN}[OK]${C_RESET}   %s\n" "$1"
}
log_err() {
    printf "${C_RED}[ERR]${C_RESET}  %s\n" "$1" >&2
}

cleanup() {
    if [[ $? -ne 0 ]]; then
        log_err "Script exited with errors."
    fi
}
trap cleanup EXIT

rofi_menu() {
    local prompt="$1"
    local options="$2"
    echo -e "$options" | rofi -dmenu -i -p "$prompt"
}

kill_process_safely() {
    local proc_name="$1"
    local -i i
    if ! pgrep -x "$proc_name" &>/dev/null; then
        return 0
    fi
    log_info "Terminating ${proc_name}..."
    pkill -x "$proc_name" 2>/dev/null
    for ((i = 0; i < 20; i++)); do
        if ! pgrep -x "$proc_name" &>/dev/null; then
            log_succ "${proc_name} terminated gracefully."
            return 0
        fi
        sleep 0.1
    done
    if pgrep -x "$proc_name" &>/dev/null; then
        log_err "${proc_name} did not exit gracefully, force killing..."
        pkill -9 -x "$proc_name" 2>/dev/null
        sleep 0.3
    fi
    log_succ "${proc_name} terminated."
}

usage() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo "If no options are provided, launches Rofi menu."
    echo
    echo "Options:"
    echo "  --mode <dark|light>      Set theme mode (Default: dark)"
    echo "  --type <scheme>          Set scheme type (Default: disabled)"
    echo "  --contrast <val>         Set contrast -1.0 to 1.0 (Default: disabled)"
    echo "  --defaults               Run immediately with full defaults"
    echo "  -h, --help               Show this help"
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)
                TARGET_MODE="$2"
                shift 2
                ;;
            --type)
                TARGET_TYPE="$2"
                shift 2
                ;;
            --contrast)
                TARGET_CONTRAST="$2"
                shift 2
                ;;
            --defaults)
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_err "Unknown option: $1"
                usage
                ;;
        esac
    done
}

run_rofi_mode() {
    log_info "No arguments provided. Starting Rofi mode..."
    local sel_mode
    sel_mode=$(rofi_menu "Matugen Mode" "dark\nlight")
    [[ -z "$sel_mode" ]] && exit 0
    TARGET_MODE="$sel_mode"
    local types_list="disable
scheme-content
scheme-expressive
scheme-fidelity
scheme-fruit-salad
scheme-monochrome
scheme-neutral
scheme-rainbow
scheme-tonal-spot
scheme-vibrant"
    local sel_type
    sel_type=$(rofi_menu "Matugen Type" "$types_list")
    [[ -z "$sel_type" ]] && exit 0
    TARGET_TYPE="$sel_type"
    local contrast_list="disable
-1.0
-0.8
-0.6
-0.4
-0.2
0.2
0.4
0.6
0.8
1.0"

    local sel_contrast
    sel_contrast=$(rofi_menu "Matugen Contrast" "$contrast_list")
    [[ -z "$sel_contrast" ]] && exit 0
    TARGET_CONTRAST="$sel_contrast"
}

if [[ $# -gt 0 ]]; then
    parse_args "$@"
    log_info "Running in CLI Mode."
else
    run_rofi_mode
fi
if [[ ! -f "$WAYPAPER_CONFIG" ]]; then
    log_err "Waypaper config not found at: $WAYPAPER_CONFIG"
    exit 1
fi
if [[ ! -x "$RANDOM_THEME" ]]; then
    log_err "random_theme script not executable or found at: $RANDOM_THEME"
    exit 1
fi
if [[ ! -x "$SYMLINK_SCRIPT" ]]; then
    log_err "Symlink script not executable or found at: $SYMLINK_SCRIPT"
    exit 1
fi
kill_process_safely "waypaper"
build_flags="--mode $TARGET_MODE"
if [[ "$TARGET_TYPE" != "disable" ]]; then
    build_flags+=" --type $TARGET_TYPE"
fi

if [[ "$TARGET_CONTRAST" != "disable" ]]; then
    build_flags+=" --contrast $TARGET_CONTRAST"
fi
log_info "Configuration: $build_flags"
log_info "Updating Waypaper configuration..."
sed -i "s|^post_command = matugen .* image \$wallpaper$|post_command = matugen $build_flags image \$wallpaper|" "$WAYPAPER_CONFIG"
log_info "Updating random_theme script flags..."
sed -i "s|^\s*setsid uwsm-app -- matugen .* image \"\$target_wallpaper\".*|    setsid uwsm-app -- matugen $build_flags image \"\$target_wallpaper\" \\\|" "$RANDOM_THEME"
log_info "Syncing filesystem..."
sync
sleep 0.2
log_info "Setting GTK color scheme..."
if gsettings set org.gnome.desktop.interface color-scheme "prefer-${TARGET_MODE}" 2>/dev/null; then
    log_succ "GTK color scheme set to 'prefer-${TARGET_MODE}'."
else
    log_err "Failed to set GTK color scheme (gsettings may be unavailable)."
fi
log_info "Updating wallpaper directory symlinks..."
if "$SYMLINK_SCRIPT" "--$TARGET_MODE"; then
    log_succ "Symlinks updated to $TARGET_MODE."
else
    log_err "Failed to update symlinks (Directory likely not found). Proceeding anyway..."
fi
log_info "Triggering wallpaper refresh..."
exec "$RANDOM_THEME"
