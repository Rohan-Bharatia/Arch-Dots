#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

VOICE_MODEL="af_sarah.4+af_nicole.6"
OUTPUT_DIR="/mnt/zram1/kokoros"
PLAYBACK_SPEED="2.2"
KOKOROS_MODEL_PATH="${HOME}/.uv/kokoros_cpu/Kokoros/checkpoints/kokoro-v1.0.onnx"
KOKOROS_DATA_PATH="${HOME}/.uv/kokoros_cpu/Kokoros/data/voices-v1.0.bin"
KOKOROS_BIN="${HOME}/.local/bin/kokoros"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Kokoros TTS" -u normal "$1" "$2"
    fi
    echo "[$(date '+%H:%M:%S')] $1: $2" >&2
}

die() {
    notify "❌ Error" "$1"
    exit 1
}

validate_environment() {
    if [ ! -x "$KOKOROS_BIN" ]; then
        if [ -x "${HOME}/.uv/kokoros_cpu/Kokoros/target/release/koko" ]; then
            KOKOROS_BIN="${HOME}/.uv/kokoros_cpu/Kokoros/target/release/koko"
        else
            die "kokoros binary not found at $KOKOROS_BIN"
        fi
    fi
    for cmd in mpv wl-paste; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            die "Required command '$cmd' not found"
        fi
    done
    if [ ! -f "$KOKOROS_MODEL_PATH" ]; then
        die "Model file not found: $KOKOROS_MODEL_PATH"
    fi

    if [ ! -f "$KOKOROS_DATA_PATH" ]; then
        die "Data file not found: $KOKOROS_DATA_PATH"
    fi
}

validate_environment
local clipboard_text="$(wl-paste --no-newline 2>/dev/null || wl-paste 2>/dev/null || echo '')"
if [ -z "$clipboard_text" ]; then
    notify "Clipboard empty" "No text to process"
    exit 0
fi
clipboard_text="$(echo "$clipboard_text" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | head -c 2000)"
mkdir -p "$OUTPUT_DIR" || die "Cannot create output directory"
local filename_prefix="$(echo "$clipboard_text" | head -n1 | awk '{
    for(i=1;i<=5 && i<=NF;i++) {
        printf "%s", tolower($i)
        if(i<5 && i<NF) printf " "
    }
}' | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]/_/g' -e 's/__*/_/g' -e 's/^_//' -e 's/_$//')"
[ -z "$filename_prefix" ] && filename_prefix="clipboard"
local existing="$(find "$OUTPUT_DIR" -maxdepth 1 -name "*.wav" 2>/dev/null | wc -l)"
local index=$((existing + 1))
"$KOKOROS_BIN" --model "$KOKOROS_MODEL_PATH" \
    --data "$KOKOROS_DATA_PATH" \
    --style "$VOICE_MODEL" \
    text "$clipboard_text" \
    --output "$output_file"
if [ ! -f "$output_file" ]; then
    die "Speech generation failed" "No output file created"
fi
notify "Playing" "$(basename "$output_file")"
mpv --no-terminal \
    --force-window \
    --title="Kokoros TTS: ${filename_prefix}" \
    --speed="$PLAYBACK_SPEED" \
    "$output_file"
notify "Complete" "Audio saved to $(basename "$output_file")"
