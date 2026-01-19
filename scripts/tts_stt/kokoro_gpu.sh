#!/bin/bash
set -euo pipefail

readonly KOKORO_APP_DIR="$HOME/.uv/kokoro_gpu"
readonly PYTHON_SCRIPT_PATH="$HOME/.user_scripts/tts_stt/kokoro_gpu/python/kokoro_gpu.py"
readonly SAVE_DIR="/mnt/zram1/kokoro_gpu"
readonly MPV_PLAYBACK_SPEED="2.2"
readonly AUDIO_RATE=24000
readonly AUDIO_CHANNELS=1
readonly AUDIO_FORMAT="f32le"
readonly BUFFER_SIZE="512M"

declare -a CHILD_PIDS=()

cleanup() {
    local exit_code=$?
    trap - EXIT INT TERM
    for pid in "${CHILD_PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done
    kill -- -$$ 2>/dev/null || true
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

die() {
    notify-send "Kokoro Error" "$1" -u critical
    exit 1
}

check_dependencies() {
    local -a missing=()
    local -a deps=(mbuffer wl-paste ffmpeg mpv uv)
    for cmd in "${deps[@]}"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing dependencies: ${missing[*]}"
    fi
    [[ -f "$PYTHON_SCRIPT_PATH" ]] || die "Python script not found: $PYTHON_SCRIPT_PATH"
    [[ -d "$KOKORO_APP_DIR" ]] || die "Kokoro directory not found: $KOKORO_APP_DIR"
}

[[ "$EUID" -eq 0 ]] && die "Don't run as root."

check_dependencies
if ! mkdir -p "$SAVE_DIR" 2>/dev/null; then
    die "Cannot create save directory: $SAVE_DIR"
fi
CLIPBOARD_TEXT=$(wl-paste 2>/dev/null) || true
if [[ -z "$CLIPBOARD_TEXT" ]]; then
    CLIPBOARD_TEXT=$(wl-paste --primary 2>/dev/null) || true
fi
if [[ -z "$CLIPBOARD_TEXT" ]]; then
    notify-send "Kokoro TTS" "Clipboard empty." -u low
    exit 0
fi
generate_filename() {
    local text="$1"
    local words
    words=$(printf '%s' "$text" |
        tr -cs '[:alnum:]' '\n' |
        tr '[:upper:]' '[:lower:]' |
        grep -E '.+' |
        head -n 5 |
        paste -sd '_') || true
    printf '%s' "${words:-audio}"
}

get_next_index() {
    local max_index=0
    local index
    while IFS= read -r -d '' file; do
        index=$(basename "$file" | cut -d'_' -f1)
        if [[ "$index" =~ ^[0-9]+$ ]] && ((index > max_index)); then
            max_index=$index
        fi
    done < <(find "$SAVE_DIR" -maxdepth 1 -type f -name "*.wav" -print0 2>/dev/null)
    printf '%d' $((max_index + 1))
}

FILENAME_WORDS=$(generate_filename "$CLIPBOARD_TEXT")
NEXT_INDEX=$(get_next_index)
FINAL_FILENAME="${NEXT_INDEX}_${FILENAME_WORDS}.wav"
FULL_PATH="$SAVE_DIR/$FINAL_FILENAME"
while [[ -f "$FULL_PATH" ]]; do
    NEXT_INDEX=$((NEXT_INDEX + 1))
    FINAL_FILENAME="${NEXT_INDEX}_${FILENAME_WORDS}.wav"
    FULL_PATH="$SAVE_DIR/$FINAL_FILENAME"
done
notify-send "Kokoro TTS" "Streaming: '${FILENAME_WORDS//_/ }...'" -u low
cd "$KOKORO_APP_DIR" || die "Cannot cd to $KOKORO_APP_DIR"
FFMPEG_FIFO=$(mktemp -u)
mkfifo "$FFMPEG_FIFO"
ffmpeg -f "$AUDIO_FORMAT" \
    -ar "$AUDIO_RATE" \
    -ac "$AUDIO_CHANNELS" \
    -i "$FFMPEG_FIFO" \
    -c:a pcm_f32le \
    -y "$FULL_PATH" \
    -loglevel warning &
FFMPEG_PID=$!
CHILD_PIDS+=("$FFMPEG_PID")
printf '%s' "$CLIPBOARD_TEXT" |
    uv run python "$PYTHON_SCRIPT_PATH" 2>/dev/null |
    tee --output-error=exit "$FFMPEG_FIFO" |
    mbuffer -q -m "$BUFFER_SIZE" 2>/dev/null |
    mpv --no-terminal \
        --force-window \
        --title="Kokoro TTS" \
        --x11-name=kokoro \
        --wayland-app-id=kokoro \
        --geometry=400x100 \
        --keep-open=no \
        --speed="$MPV_PLAYBACK_SPEED" \
        --demuxer=rawaudio \
        --demuxer-rawaudio-rate="$AUDIO_RATE" \
        --demuxer-rawaudio-channels="$AUDIO_CHANNELS" \
        --demuxer-rawaudio-format=float \
        --cache=yes \
        --cache-secs=30 \
        - || true
rm -f "$FFMPEG_FIFO" 2>/dev/null
wait "$FFMPEG_PID" 2>/dev/null || true
if [[ -s "$FULL_PATH" ]]; then
    notify-send "Kokoro TTS" "Saved: $FINAL_FILENAME" -u low
fi
