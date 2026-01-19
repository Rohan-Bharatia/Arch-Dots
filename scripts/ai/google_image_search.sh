#!/usr/bin/env bash

set -euo pipefail

notify() {
    notify-send -a "Google Lens" "$1" "$2"
}

open_url() {
    uwsm-app -- xdg-open "$1" &
    disown
}

die() {
    printf '❌ %s\n' "$1" >&2
    notify "Error" "$1"
    exit 1
}

printf '📷 Select region...\n'
if ! geometry=$(slurp 2>/dev/null); then
    printf '🚫 Selection cancelled.\n'
    exit 0
fi
if [[ ! "${geometry}" =~ ^[0-9]+,[0-9]+\ [0-9]+x[0-9]+$ ]]; then
    die "Invalid selection geometry received."
fi
if [[ "${USE_UPLOAD_SERVICE}" == "true" ]]; then
    tmp_file=$(mktemp /tmp/lens-XXXXXX.png)
    trap 'rm -f "${tmp_file}"' EXIT
    grim -g "${geometry}" "${tmp_file}"
    notify "Uploading..." "Sending image to secure host"
    if ! response=$(curl -sSf -F "files[]=@${tmp_file}" 'https://uguu.se/upload'); then
        die "Upload connection failed."
    fi
    url=$(jq -r '.files[0].url // empty' <<<"${response}")
    if [[ -z "${url}" ]]; then
        printf 'Debug: Raw response was: %s\n' "${response}" >&2
        die "Upload succeeded but URL parsing failed."
    fi
    open_url "https://lens.google.com/uploadbyurl?url=${url}"
else
    if grim -g "${geometry}" - | wl-copy; then
        notify "Ready" "Screenshot copied. Paste (Ctrl+V) in browser."
        open_url "https://lens.google.com/"
    else
        die "Failed to capture or copy to clipboard."
    fi
fi
