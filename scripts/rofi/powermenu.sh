#!/usr/bin/env bash

set -euo pipefail

exec 9>"${XDG_RUNTIME_DIR}/rofi-power.lock"
flock -n 9 || exit 0

declare -Ar ICONS=(
    [shutdown]=""
    [reboot]=""
    [suspend]=""
    [soft_reboot]=""
    [logout]=""
    [lock]=""
    [cancel]=""
)
declare -Ar MENU=(
    [lock]="${ICONS[lock]}  Lock"
    [logout]="${ICONS[logout]}  Logout"
    [suspend]="${ICONS[suspend]}  Suspend"
    [reboot]="${ICONS[reboot]}  Reboot"
    [soft_reboot]="${ICONS[soft_reboot]}  Soft Reboot"
    [shutdown]="${ICONS[shutdown]}  Shutdown"
)
declare -ar ORDER=(shutdown reboot suspend lock logout soft_reboot )
declare -Ar CONFIRM=([shutdown]=1 [reboot]=1 [logout]=1 [soft_reboot]=1)

execute() {
    sleep 0.05
    case $1 in
        lock)
            if ! pgrep -x hyprlock >/dev/null; then
                uwsm-app -- hyprlock > /tmp/hyprlock.log 2>&1 &
            fi
            ;;
        logout)
            uwsm stop
            ;;
        suspend)
            systemctl suspend
            ;;
        reboot)
            systemctl reboot
            ;;
        soft_reboot)
            systemctl soft-reboot
            ;;
        shutdown)
            systemctl poweroff
            ;;
    esac
}

IFS=: read -r key state <<< "${ROFI_INFO:-}"
if [[ -z ${key:-} ]]; then
    uptime_str=$(uptime -p | sed 's/^up //')
    printf '\0prompt\x1fUptime\n'
    printf '\0theme\x1fentry { placeholder: "%s"; }\n' "$uptime_str"
    for k in "${ORDER[@]}"; do
        printf '%s\0info\x1f%s\n' "${MENU[$k]}" "$k"
    done
    exit 0
fi
[[ $key == cancel ]] && exit 0
[[ -v MENU[$key] ]] || exit 1
if [[ ${state:-} == confirmed ]]; then
    execute "$key"
    exit 0
fi
if [[ -v CONFIRM[$key] ]]; then
    label=${MENU[$key]#* }
    printf '\0prompt\x1f%s?\n' "$label"
    printf 'Yes, %s\0info\x1f%s:confirmed\n' "$label" "$key"
    printf '%s No, Cancel\0info\x1fcancel\n' "${ICONS[cancel]}"
    exit 0
fi
execute "$key"
