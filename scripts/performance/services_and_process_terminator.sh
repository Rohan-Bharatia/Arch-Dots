#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if ((zsh_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 3))); then
    printf 'Error: This script requires zsh 4.3 or higher (found %s)\n' "$BASH_VERSION" >&2
    exit 1
fi

_cleanup() {
    local exit_code=$?
    trap - ERR EXIT

    if [[ "${1:-}" == "error" ]]; then
        printf '\n\033[1;31mScript encountered an error on line %s (exit code: %d)\033[0m\n' \
            "${2:-unknown}" "$exit_code" >&2
        read -rp "Press Enter to exit..."
    fi
}
trap '_cleanup error "$LINENO"' ERR
trap '_cleanup' EXIT

declare -ra DEFAULT_PROCESSES=(
    "hyprsunset"
    "swww-daemon"
    "waybar"
)
declare -ra OPTIONAL_PROCESSES=(
    "inotifywait"
    "wl-paste"
    "wl-copy"
    "firefox"
    "discord"
)
declare -ra DEFAULT_SYSTEM_SERVICES=(
    "firewalld"
    "vsftpd"
    "waydroid-container"
    "logrotate.timer"
    "sshd"
)
declare -ra OPTIONAL_SYSTEM_SERVICES=(
    "udisks2"
    "swayosd-libinput-backend"
    "warp-svc"
    "NetworkManager"
)
declare -ra DEFAULT_USER_SERVICES=(
    "battery_notify"
    "blueman-applet"
    "blueman-manager"
    "hypridle"
    "hyprpolkitagent"
    "swaync"
    "gvfs-daemon"
    "gvfs-metadata"
    "network_meter"
    "waybar"
)
declare -ra OPTIONAL_USER_SERVICES=(
    "gnome-keyring-daemon"
    "swayosd-server"
    "pipewire-pulse.socket"
    "pipewire.socket"
    "pipewire"
    "wireplumber"
)

if ! command -v gum &>/dev/null; then
    printf 'Error: "gum" is not installed.\n' >&2
    exit 1
fi

contains_element() {
    local match="$1"
    shift
    local element
    for element in "$@"; do
        [[ "$element" == "$match" ]] && return 0
    done
    return 1
}

is_active() {
    local name="$1"
    local type="$2"
    case "$type" in
    proc)
        pgrep -x "$name" &>/dev/null
        ;;
    sys)
        systemctl is-active --quiet "$name" 2>/dev/null
        ;;
    user)
        systemctl --user is-active --quiet "$name" 2>/dev/null
        ;;
    *)
        printf 'Warning: Unknown type "%s" in is_active()\n' "$type" >&2
        return 1
        ;;
    esac
}

gather_candidates() {
    local item
    for item in "${DEFAULT_PROCESSES[@]}" "${OPTIONAL_PROCESSES[@]}"; do
        is_active "$item" "proc" && printf 'proc:%s|%s (Process)\n' "$item" "$item"
    done
    for item in "${DEFAULT_SYSTEM_SERVICES[@]}" "${OPTIONAL_SYSTEM_SERVICES[@]}"; do
        is_active "$item" "sys" && printf 'sys:%s|%s (System Svc)\n' "$item" "$item"
    done
    for item in "${DEFAULT_USER_SERVICES[@]}" "${OPTIONAL_USER_SERVICES[@]}"; do
        is_active "$item" "user" && printf 'user:%s|%s (User Svc)\n' "$item" "$item"
    done
    return 0
}

is_default_item() {
    local name="$1"
    local type="$2"
    case "$type" in
    proc)
        contains_element "$name" "${DEFAULT_PROCESSES[@]}"
        ;;
    sys)
        contains_element "$name" "${DEFAULT_SYSTEM_SERVICES[@]}"
        ;;
    user)
        contains_element "$name" "${DEFAULT_USER_SERVICES[@]}"
        ;;
    *)
        return 1
        ;;
    esac
}

perform_stop() {
    local type="$1"
    local name="$2"
    local i
    case "$type" in
    proc)
        pkill -x "$name" 2>/dev/null || true
        for i in {1..20}; do
            is_active "$name" "proc" || return 0
            sleep 0.1
        done
        pkill -9 -x "$name" 2>/dev/null || true
        sleep 0.3
        ! is_active "$name" "proc"
        ;;
    sys)
        if ! sudo systemctl stop "$name" 2>/dev/null; then
            if ! systemctl list-unit-files "$name" &>/dev/null; then
                printf 'Warning: Unit %s not found\n' "$name" >&2
            fi
            return 1
        fi
        sleep 0.2
        ! is_active "$name" "sys"
        ;;
    user)
        if ! systemctl --user stop "$name" 2>/dev/null; then
            return 1
        fi
        sleep 0.2
        ! is_active "$name" "user"
        ;;
    *)
        printf 'Error: Unknown type "%s" in perform_stop()\n' "$type" >&2
        return 1
        ;;
    esac
}

mapfile -t CANDIDATES < <(gather_candidates)
if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
    gum style --border normal --padding "1 2" --border-foreground 212 \
        "System Clean" \
        "All monitored services/processes are already inactive."
    printf '\n'
    trap - ERR EXIT
    exec "${SHELL:-/bin/zsh}"
fi

declare -a SELECTED_ITEMS=()

if [[ "${1:-}" == "--auto" ]]; then
    for line in "${CANDIDATES[@]}"; do
        data="${line%%|*}"
        type="${data%%:*}"
        name="${data#*:}"
        if is_default_item "$name" "$type"; then
            SELECTED_ITEMS+=("$data")
        fi
    done
else
    declare -a OPTIONS_DISPLAY=()
    declare -a PRE_SELECTED_DISPLAY=()
    declare -A DATA_MAP=()

    for line in "${CANDIDATES[@]}"; do
        data="${line%%|*}"
        display="${line#*|}"
        type="${data%%:*}"
        name="${data#*:}"
        OPTIONS_DISPLAY+=("$display")
        DATA_MAP["$display"]="$data"
        if is_default_item "$name" "$type"; then
            PRE_SELECTED_DISPLAY+=("$display")
        fi
    done
    PRE_SELECTED_STR=""
    if [[ ${#PRE_SELECTED_DISPLAY[@]} -gt 0 ]]; then
        PRE_SELECTED_STR=$(
            IFS=,
            printf '%s' "${PRE_SELECTED_DISPLAY[*]}"
        )
    fi
    gum style --border double --padding "1 2" --border-foreground 57 \
        "Performance Terminator"
    SELECTION_RESULT=$(
        gum choose --no-limit --height 15 \
            --header "Select resources to FREE. (SPACE: toggle, ENTER: confirm)" \
            --selected="$PRE_SELECTED_STR" \
            "${OPTIONS_DISPLAY[@]}"
    ) || true
    if [[ -z "$SELECTION_RESULT" ]]; then
        printf 'Cancelled.\n'
        exit 0
    fi
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            SELECTED_ITEMS+=("${DATA_MAP[$line]}")
        fi
    done <<<"$SELECTION_RESULT"
fi
if [[ ${#SELECTED_ITEMS[@]} -eq 0 ]]; then
    printf 'No items selected.\n'
    trap - ERR EXIT
    exec "${SHELL:-/bin/zsh}"
fi
NEEDS_SUDO=false
for item in "${SELECTED_ITEMS[@]}"; do
    if [[ "$item" == sys:* ]]; then
        NEEDS_SUDO=true
        break
    fi
done
if [[ "$NEEDS_SUDO" == true ]]; then
    printf 'System services selected. Authenticating...\n'
    if ! sudo -v; then
        gum style --foreground 196 "Authentication failed. Aborting."
        exit 1
    fi
fi

declare -a SUCCESS_LIST=()
declare -a FAIL_LIST=()

printf '\n'
gum style --bold "Stopping selected resources..."
for item in "${SELECTED_ITEMS[@]}"; do
    type="${item%%:*}"
    name="${item#*:}"
    printf ' • Stopping %s...' "$name"
    if perform_stop "$type" "$name"; then
        printf '\r \033[0;32m✔\033[0m Stopped %s     \n' "$name"
        SUCCESS_LIST+=("$type: $name")
    else
        printf '\r \033[0;31m✘\033[0m Failed %s      \n' "$name"
        FAIL_LIST+=("$type: $name")
    fi
done
REPORT=""
if [[ ${#SUCCESS_LIST[@]} -gt 0 ]]; then
    REPORT+="$(gum style --foreground 82 "✔ Successfully Stopped:")"$'\n'
    for item in "${SUCCESS_LIST[@]}"; do
        REPORT+="  $item"$'\n'
    done
    REPORT+=$'\n'
fi
if [[ ${#FAIL_LIST[@]} -gt 0 ]]; then
    REPORT+="$(gum style --foreground 196 "✘ Failed to Stop (Still Active):")"$'\n'
    for item in "${FAIL_LIST[@]}"; do
        REPORT+="  $item"$'\n'
    done
    REPORT+=$'\n'
fi
clear
gum style --border double --padding "1 2" --border-foreground 57 "Execution Complete"
printf '%b' "$REPORT"
trap - ERR EXIT
printf '%s\n' "-----------------------------------------------------"
printf '%s\n' "Session Active. Type 'exit' to close."
exec "${SHELL:-/bin/zsh}"
