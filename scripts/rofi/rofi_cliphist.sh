#!/usr/bin/env bash

set -o nounset
set -o pipefail
shopt -s nullglob

readonly XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
readonly PINS_DIR="${XDG_DATA_HOME}/rofi-cliphist/pins"
readonly PIN_ICON=" |"
readonly MAX_PREVIEW_LENGTH=80

if command -v b2sum &>/dev/null; then
    readonly HASH_CMD="b2sum"
elif command -v sha256sum &>/dev/null; then
    readonly HASH_CMD="sha256sum"
else
    readonly HASH_CMD="md5sum"
fi

log_error() {
    printf '[ERROR] %s\n' "$*" >&2
}

generate_hash() {
    printf '%s' "$1" | "$HASH_CMD" | cut -c1-16
}

create_preview() {
    local content="$1"
    local preview
    preview=$(printf '%s' "$content" | tr '\n\r\t\v\f\x00\x1f' ' ' | tr -s ' ')
    preview="${preview#"${preview%%[![:space:]]*}"}"
    preview="${preview%"${preview##*[![:space:]]}"}"
    if ((${#preview} > MAX_PREVIEW_LENGTH)); then
        preview="${preview:0:MAX_PREVIEW_LENGTH}…"
    fi
    printf '%s' "${preview:-[empty]}"
}

init() {
    if [[ ! -d "${PINS_DIR}" ]]; then
        mkdir -p "${PINS_DIR}"
        chmod 700 "${PINS_DIR}"
    fi
    local cmd
    for cmd in cliphist wl-copy find; do
        if ! command -v "${cmd}" &>/dev/null; then
            log_error "Missing required command: ${cmd}"
            exit 1
        fi
    done
}

list_pins() {
    local pin_file filename content preview
    while IFS= read -r pin_file; do
        [[ -f "${pin_file}" ]] || continue
        filename="${pin_file##*/}"
        content=$(<"${pin_file}") 2>/dev/null || continue
        preview=$(create_preview "${content}")
        printf '%s %s\x00info\x1fpin:%s\n' \
            "${PIN_ICON}" \
            "${preview}" \
            "${filename}"
    done < <(
        find "${PINS_DIR}" -maxdepth 1 -name '*.pin' -type f \
            -printf '%T@\t%p\n' 2>/dev/null \
        | sort -t$'\t' -k1 -rn \
        | cut -f2
    )
}

create_pin() {
    local content="$1"
    local hash_id pin_path
    hash_id=$(generate_hash "${content}")
    pin_path="${PINS_DIR}/${hash_id}.pin"
    if [[ -f "${pin_path}" ]]; then
        touch "${pin_path}"
        return 0
    fi
    printf '%s' "${content}" > "${pin_path}"
    chmod 600 "${pin_path}"
}

delete_pin() {
    local filename="$1"
    if [[ "${filename}" == *'/'* || "${filename}" == '..'* ]]; then
        log_error "Invalid pin filename: ${filename}"
        return 1
    fi
    local pin_path="${PINS_DIR}/${filename}"
    [[ -f "${pin_path}" ]] && rm -f "${pin_path}"
    return 0
}

get_pin_content() {
    local filename="$1"
    if [[ "${filename}" == *'/'* || "${filename}" == '..'* ]]; then
        log_error "Invalid pin filename: ${filename}"
        return 1
    fi
    local pin_path="${PINS_DIR}/${filename}"
    if [[ -f "${pin_path}" ]]; then
        cat "${pin_path}"
    else
        log_error "Pin not found: ${filename}"
        return 1
    fi
}

display_menu() {
    printf '\x00message\x1f<b>Enter</b>: Copy  │  <b>ALT+U</b>: Pin/Unpin  │  <b>ALT+Y</b>: Delete\n'
    printf '\x00use-hot-keys\x1ftrue\n'
    printf '\x00keep-selection\x1ftrue\n'
    list_pins
    local line display_line
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        display_line="${line/$'\t'/: }"
        display_line="${display_line//$'\x00'/}"
        display_line="${display_line//$'\x1f'/}"
        printf '%s\x00info\x1fhist:%s\n' "${display_line}" "${line}"
    done < <(cliphist list 2>/dev/null)
}

handle_selection() {
    local selection="${1:-}"
    local action="${ROFI_RETV:-0}"
    local info="${ROFI_INFO:-}"
    if [[ -z "${selection}" ]]; then
        display_menu
        return 0
    fi
    local item_type="${info%%:*}"
    local item_data="${info#*:}"
    case "${item_type}" in
        pin)
            handle_pinned_item "${item_data}" "${action}"
            ;;
        hist)
            handle_history_item "${item_data}" "${action}"
            ;;
        *)
            log_error "Unknown item type, attempting history fallback"
            handle_history_item "${selection}" "${action}"
            ;;
    esac
}

handle_pinned_item() {
    local filename="$1"
    local action="$2"
    case "${action}" in
        1)
            get_pin_content "${filename}" | wl-copy
            ;;
        10)
            delete_pin "${filename}"
            display_menu
            ;;
        11)
            delete_pin "${filename}"
            display_menu
            ;;
        *)
            display_menu
            ;;
    esac
}

handle_history_item() {
    local original_line="$1"
    local action="$2"
    local content
    case "${action}" in
        1)
            printf '%s' "${original_line}" | cliphist decode | wl-copy
            ;;
        10)
            content=$(printf '%s' "${original_line}" | cliphist decode 2>/dev/null) || content=""
            if [[ -n "${content}" ]]; then
                create_pin "${content}"
            fi
            display_menu
            ;;
        11)
            printf '%s' "${original_line}" | cliphist delete 2>/dev/null || true
            display_menu
            ;;
        *)
            display_menu
            ;;
    esac
}

init
if (($# == 0)); then
    display_menu
else
    handle_selection "$*"
fi
