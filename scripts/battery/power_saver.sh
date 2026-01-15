#!/usr/bin/env bash

set -uo pipefail

if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
    printf 'Error: Bash 4.4+ required (found %s)\n' "${BASH_VERSION}" >&2
    exit 1
fi

readonly BRIGHTNESS_LEVEL="1%"
readonly VOLUME_CAP="50"
readonly SUDO_REFRESH_INTERVAL=60  # Refresh sudo every N seconds to prevent timeout
readonly BLUR_SCRIPT="${HOME}/user_scripts/hypr/hypr_blur_opacity_shadow_toggle.sh"
readonly THEME_SCRIPT="${HOME}/user_scripts/theme_matugen/matugen_config.sh"
readonly TERMINATOR_SCRIPT="${HOME}/user_scripts/battery/process_terminator.sh"
readonly ASUS_PROFILE_SCRIPT="${HOME}/user_scripts/battery/asus_tuf_profile/quiet_profile_and_keyboard_light.sh"
readonly ANIM_SOURCE="${HOME}/.config/hypr/source/animations/disable.conf"
readonly ANIM_TARGET="${HOME}/.config/hypr/source/animations/active/active.conf"

SWITCH_THEME_LATER=false
TURN_OFF_WIFI=false
SUDO_AUTHENTICATED=false

has_cmd() {
    command -v "$1" &>/dev/null
}

is_numeric() {
    [[ -n "$1" && "$1" =~ ^[0-9]+$ ]]
}

log_step() {
    gum style --foreground 212 ":: $*"
}
log_warn() {
    gum style --foreground 208 "⚠ $*"
}
log_error() {
    gum style --foreground 196 "✗ $*" >&2
}

run_quiet() {
    "$@" &>/dev/null || true
}

spin_exec() {
    local title="$1"
    shift
    gum spin --spinner dot --title "$title" -- "$@"
}

sudo_keepalive() {
    if [[ "${SUDO_AUTHENTICATED}" == "true" ]]; then
        sudo -vn 2>/dev/null || true
    fi
}

safe_pkill() {
    local process_name="$1"
    pkill -x "$process_name" 2>/dev/null || true
}

check_dependencies() {
    if ! has_cmd gum; then
        printf 'Error: gum is not installed. Run: sudo pacman -S gum\n' >&2
        exit 1
    fi
    local -a missing=()
    local -a recommended=(
        uwsm-app
        brightnessctl
        hyprctl
        wpctl
        rfkill
        tlp
        hyprshade
        playerctl
    )
    local cmd
    for cmd in "${recommended[@]}"; do
        has_cmd "$cmd" || missing+=("$cmd")
    done
    if ((${#missing[@]} > 0)); then
        log_warn "Missing optional dependencies: ${missing[*]}"
        log_warn "Some features will be skipped."
        echo
    fi
}

run_script() {
    local script_path="$1"
    local description="$2"
    shift 2
    local -a extra_args=("$@")

    if [[ -x "${script_path}" ]]; then
        if has_cmd uwsm-app; then
            spin_exec "${description}" uwsm-app -- "${script_path}" "${extra_args[@]}"
        else
            spin_exec "${description}" "${script_path}" "${extra_args[@]}"
        fi
        return 0
    elif [[ -f "${script_path}" ]]; then
        log_warn "Script not executable: ${script_path}"
        return 1
    else
        log_warn "Script not found: ${script_path}"
        return 1
    fi
}

cleanup() {
    tput cnorm 2>/dev/null || true
    tput sgr0 2>/dev/null || true
}
trap cleanup EXIT

prompt_user_choices() {
    [[ -t 0 ]] || {
        log_step "Non-interactive shell detected. Skipping prompts."
        return
    }
    echo
    gum style --foreground 245 --italic \
        "Rationale: Light mode often allows for lower backlight brightness" \
        "while maintaining readability in well-lit environments."
    echo
    if gum confirm "Switch to Light Mode?" \
        --affirmative "Yes, switch it" \
        --negative "No, stay dark"; then
        log_step "Theme switch queued for end of script."
        SWITCH_THEME_LATER=true
    else
        log_step "Keeping current theme."
    fi
    echo
    if gum confirm "Turn off Wi-Fi to save power?" \
        --affirmative "Yes, disable Wi-Fi" \
        --negative "No, keep connected"; then
        log_step "Wi-Fi disable queued."
        TURN_OFF_WIFI=true
    else
        log_step "Keeping Wi-Fi active."
    fi
}

disable_visual_effects() {
    echo
    if ! has_cmd uwsm-app; then
        log_warn "uwsm-app not found. Skipping visual effects."
        return
    fi
    if [[ -x "${BLUR_SCRIPT}" ]]; then
        spin_exec "Disabling blur/opacity/shadow..." \
            uwsm-app -- "${BLUR_SCRIPT}" off
    elif [[ -f "${BLUR_SCRIPT}" ]]; then
        log_warn "Blur script not executable: ${BLUR_SCRIPT}"
    fi
    if has_cmd hyprshade; then
        spin_exec "Disabling Hyprshade..." \
            uwsm-app -- hyprshade off
    fi
    log_step "Visual effects disabled."
}

cleanup_user_processes() {
    echo
    spin_exec "Cleaning up resource monitors..." \
        bash -c 'pkill -x btop 2>/dev/null; pkill -x nvtop 2>/dev/null; exit 0'
    if has_cmd playerctl; then
        run_quiet playerctl -a pause
    fi
    log_step "Resource monitors killed & media paused."
    if has_cmd warp-cli; then
        spin_exec "Disconnecting Warp..." \
            bash -c 'warp-cli disconnect &>/dev/null || true'
        log_step "Warp disconnected."
    fi
}

set_brightness() {
    if has_cmd brightnessctl; then
        spin_exec "Lowering brightness to ${BRIGHTNESS_LEVEL}..." \
            brightnessctl set "${BRIGHTNESS_LEVEL}" -q
        log_step "Brightness set to ${BRIGHTNESS_LEVEL}."
    else
        log_warn "brightnessctl not found. Skipping brightness."
    fi
}

disable_animations() {
    if ! has_cmd hyprctl; then
        log_warn "hyprctl not found. Skipping animation toggle."
        return
    fi
    if [[ ! -f "${ANIM_SOURCE}" ]]; then
        log_warn "Animation source not found: ${ANIM_SOURCE}"
        return
    fi
    local target_dir
    target_dir="$(dirname "${ANIM_TARGET}")"
    if ! mkdir -p "${target_dir}" 2>/dev/null; then
        log_warn "Failed to create directory: ${target_dir}"
        return
    fi
    spin_exec "Disabling animations & reloading Hyprland..." \
        bash -c 'ln -nfs "$1" "$2" && hyprctl reload' _ "${ANIM_SOURCE}" "${ANIM_TARGET}"
    log_step "Hyprland animations disabled."
}

apply_asus_profile() {
    run_script "${ASUS_PROFILE_SCRIPT}" "Applying Quiet Profile & KB Lights..." && \
        log_step "ASUS Quiet profile & lighting applied."
}

request_sudo() {
    echo
    gum style \
        --border normal \
        --border-foreground 196 \
        --padding "0 1" \
        --foreground 196 \
        "PRIVILEGE ESCALATION REQUIRED" \
        "Need root for TLP, Wi-Fi, and Process Terminator."
    echo
    if sudo -v; then
        SUDO_AUTHENTICATED=true
        return 0
    else
        log_error "Authentication failed. Root operations skipped."
        return 1
    fi
}

block_bluetooth() {
    has_cmd rfkill || {
        log_warn "rfkill not found. Skipping Bluetooth block."
        return
    }
    sudo_keepalive
    spin_exec "Blocking Bluetooth..." sudo rfkill block bluetooth
    sleep 0.5
    log_step "Bluetooth blocked."
}

block_wifi() {
    [[ "${TURN_OFF_WIFI}" == "true" ]] || return 0
    has_cmd rfkill || {
        log_warn "rfkill not found. Skipping Wi-Fi block."
        return
    }
    sudo_keepalive
    spin_exec "Blocking Wi-Fi (Hardware)..." sudo rfkill block wifi
    sleep 0.5
    log_step "Wi-Fi blocked."
}

cap_volume() {
    has_cmd wpctl || {
        log_warn "wpctl not found. Skipping volume cap."
        return
    }
    local raw_output
    local current_vol
    if ! raw_output=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); then
        log_warn "Could not query audio sink."
        return
    fi
    current_vol=$(awk '{printf "%.0f", $2 * 100}' <<< "${raw_output}") || current_vol=""
    if ! is_numeric "${current_vol}"; then
        log_warn "Could not parse volume level from: ${raw_output}"
        return
    fi
    if ((current_vol > VOLUME_CAP)); then
        spin_exec "Volume ${current_vol}% → ${VOLUME_CAP}%..." \
            wpctl set-volume @DEFAULT_AUDIO_SINK@ "${VOLUME_CAP}%"
        log_step "Volume capped at ${VOLUME_CAP}%."
    else
        log_step "Volume at ${current_vol}%. No change needed."
    fi
}

activate_tlp() {
    has_cmd tlp || {
        log_warn "tlp not found. Skipping power profile."
        return
    }

    sudo_keepalive
    spin_exec "Activating TLP power saver..." sudo tlp power-saver
    log_step "TLP power saver activated."
}

run_process_terminator() {
    [[ -x "${TERMINATOR_SCRIPT}" ]] || {
        if [[ -f "${TERMINATOR_SCRIPT}" ]]; then
            log_warn "Terminator script not executable: ${TERMINATOR_SCRIPT}"
        else
            log_warn "Terminator script not found: ${TERMINATOR_SCRIPT}"
        fi
        return
    }
    sudo_keepalive
    spin_exec "Running Process Terminator..." sudo "${TERMINATOR_SCRIPT}"
    log_step "High-drain processes terminated."
}

perform_root_operations() {
    request_sudo || return
    echo
    block_bluetooth
    block_wifi
    cap_volume
    activate_tlp
    run_process_terminator
}

switch_theme_if_queued() {
    if [[ "${SWITCH_THEME_LATER}" != "true" ]]; then
        run_quiet pkill swww-daemon
        log_step "swww-daemon terminated."
        return
    fi
    echo
    if ! has_cmd uwsm-app; then
        log_error "uwsm-app required for theme switch but not found."
        return 1
    fi
    if [[ ! -x "${THEME_SCRIPT}" ]]; then
        if [[ -f "${THEME_SCRIPT}" ]]; then
            log_warn "Theme script not executable: ${THEME_SCRIPT}"
        else
            log_warn "Theme script not found: ${THEME_SCRIPT}"
        fi
        return 1
    fi
    gum style --foreground 212 "Executing theme switch..."
    gum style --foreground 240 "(Terminal may close - this is expected)"
    sleep 1
    if uwsm-app -- "${THEME_SCRIPT}" --mode light; then
        sleep 3
        run_quiet pkill swww-daemon
        log_step "Theme switched to light mode."
    else
        log_error "Theme switch failed."
        return 1
    fi
}

check_dependencies
clear
gum style \
    --border double \
    --margin "1" \
    --padding "1 2" \
    --border-foreground 212 \
    --foreground 212 \
    "POWER SAVER MODE"
prompt_user_choices
disable_visual_effects
cleanup_user_processes
set_brightness
disable_animations
apply_asus_profile
perform_root_operations
switch_theme_if_queued
echo
gum style \
    --foreground 46 \
    --bold \
    "✓ DONE: Power Saving Mode Active"

sleep 1
