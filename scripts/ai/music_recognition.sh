#!/bin/bash

set -euo pipefail

readonly SCRIPT_NAME="${0##*/}"
readonly TIMEOUT_SECS=20
readonly INTERVAL=4
readonly LOCK_FILE="/tmp/hypr_songrec.lock"

TMP_DIR=""
RAW_FILE=""
MP3_FILE=""
REC_PID=""

log_info() {
    printf '[%s] INFO: %s\n' "$SCRIPT_NAME" "$1" >&2
}
log_error() {
    printf '[%s] ERROR: %s\n' "$SCRIPT_NAME" "$1" >&2
}

die() {
    log_error "$1"
    exit "${2:-1}"
}

acquire_lock() {
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
        exit 0
    fi
    printf '%d\n' "$$" >&200
}

setup_environment() {
    TMP_DIR=$(mktemp -d "/tmp/hypr_songrec.XXXXXX")
    RAW_FILE="${TMP_DIR}/recording.raw"
    MP3_FILE="${TMP_DIR}/recording.mp3"
}

cleanup() {
    local exit_code=$?
    set +e
    if [[ -n "${REC_PID:-}" ]] && kill -0 "$REC_PID" 2>/dev/null; then
        kill "$REC_PID" 2>/dev/null
        wait "$REC_PID" 2>/dev/null
    fi
    [[ -d "${TMP_DIR:-}" ]] && rm -rf "$TMP_DIR"
    rm -f "$LOCK_FILE"
    exit "$exit_code"
}

get_monitor_source() {
    local default_sink
    if ! default_sink=$(pactl get-default-sink 2>/dev/null) || [[ -z "$default_sink" ]]; then
        die "Failed to get default audio sink from pactl."
    fi
    printf '%s.monitor' "$default_sink"
}

start_recording() {
    local monitor_source="$1"
    parec -d "$monitor_source" --format=s16le --rate=44100 --channels=2 >"$RAW_FILE" 2>/dev/null &
    REC_PID=$!
    sleep 0.2
    if ! kill -0 "$REC_PID" 2>/dev/null; then
        die "Failed to start audio recording with parec on source '$monitor_source'."
    fi
}

convert_to_mp3() {
    if [[ ! -s "$RAW_FILE" ]]; then
        return 1
    fi
    ffmpeg -f s16le -ar 44100 -ac 2 -i "$RAW_FILE" \
        -vn -acodec libmp3lame -q:a 2 -y -loglevel error "$MP3_FILE" 2>/dev/null
}

recognize_song() {
    local json
    if ! json=$(songrec audio-file-to-recognized-song "$MP3_FILE" 2>/dev/null); then
        return 1
    fi
    [[ -z "$json" ]] && return 1
    local parsed
    if ! parsed=$(printf '%s' "$json" | jq -re '.track | [.title, .subtitle] | @tsv' 2>/dev/null); then
        return 1
    fi
    local title artist
    IFS=$'\t' read -r title artist <<<"$parsed"
    [[ -z "$title" ]] && return 1
    notify-send -u normal -t 10000 \
        -h string:x-canonical-private-synchronous:songrec \
        "Song Detected" "<b>${title}</b>\n${artist}"
    printf 'Found: %s by %s\n' "$title" "$artist"
    return 0
}

recognition_loop() {
    local start_time=$EPOCHSECONDS
    while true; do
        sleep "$INTERVAL"
        local elapsed=$((EPOCHSECONDS - start_time))
        if ((elapsed >= TIMEOUT_SECS)); then
            notify-send -u low -t 3000 \
                -h string:x-canonical-private-synchronous:songrec \
                "SongRec" "No match found."
            return 1
        fi
        if convert_to_mp3 && recognize_song; then
            return 0
        fi
    done
}

acquire_lock
setup_environment
trap cleanup EXIT HUP INT TERM
local monitor_source
monitor_source=$(get_monitor_source)
notify-send -u low -t 3000 \
    -h string:x-canonical-private-synchronous:songrec \
    "SongRec" "Listening..."
start_recording "$monitor_source"
recognition_loop
