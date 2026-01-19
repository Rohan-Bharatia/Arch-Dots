#!/bin/bash

set -euo pipefail

readonly VENV_PATH="/home/dusk/.uv/parakeet"
readonly PYTHON_SCRIPT="/home/dusk/.user_scripts/tts_stt/parakeet/python/parakeet_gpu.py"
readonly AUDIO_DIR="/mnt/zram1/mic"
readonly LOG_FILE="/tmp/transcribe_voice_parakeet.log"
readonly PYTHON_OUTPUT_TEMP_FILE="/tmp/transcription_$$.output"
readonly PYTHON_LOG_TEMP_FILE="/tmp/transcription_$$.log"

: >"$LOG_FILE"
: >"$PYTHON_OUTPUT_TEMP_FILE"
: >"$PYTHON_LOG_TEMP_FILE"
FFMPEG_PID=""

log_message() {
    printf '[%s] %s\n' "$(date '+%T')" "$1" | tee -a "$LOG_FILE" >&2
}

cleanup() {
    local exit_status=$?
    if [[ -n "${FFMPEG_PID:-}" ]]; then
        if kill -0 "$FFMPEG_PID" 2>/dev/null; then
            kill "$FFMPEG_PID" 2>/dev/null || true
            wait "$FFMPEG_PID" 2>/dev/null || true
        fi
    fi
    rm -f "$PYTHON_OUTPUT_TEMP_FILE" "$PYTHON_LOG_TEMP_FILE"
    if [[ $exit_status -ne 0 ]]; then
        log_message "Exiting with error code $exit_status. See $LOG_FILE"
    fi
    exit "$exit_status"
}

fatal_error_dialog() {
    local error_details="$1"
    local log_content=$(<"$LOG_FILE") || log_content="(Could not read log file)"
    local escaped_details=$(printf '%s' "$error_details" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    yad --title="Fatal Transcription Error" \
        --text="<span color='red'><b>Error:</b></span> ${escaped_details}" \
        --width=500 --height=400 \
        --button="Close:1" \
        --text-info --wrap \
        <<<"$log_content"
    exit 1
}
trap cleanup EXIT SIGINT SIGTERM

missing_deps=()
for cmd in ffmpeg pactl yad wl-copy notify-send; do
    command -v "$cmd" &>/dev/null || missing_deps+=("$cmd")
done
if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_message "Error: Missing required commands: ${missing_deps[*]}"
    exit 1
fi
if [[ ! -x "${VENV_PATH}/bin/python3" ]]; then
    log_message "Error: Python interpreter not found or not executable: ${VENV_PATH}/bin/python3"
    exit 1
fi
if [[ ! -f "$PYTHON_SCRIPT" ]]; then
    log_message "Error: Python script not found: $PYTHON_SCRIPT"
    exit 1
fi
mkdir -p "$AUDIO_DIR"
last_num=0
shopt -s nullglob
for f in "$AUDIO_DIR"/*.wav; do
    base_f=$(basename -- "$f" .wav)
    # Check if filename is purely numeric
    if [[ "$base_f" =~ ^[0-9]+$ ]]; then
        # CRITICAL: Force base-10 to avoid octal interpretation (08, 09 are invalid octal!)
        current_num=$((10#$base_f))
        if ((current_num > last_num)); then
            last_num=$current_num
        fi
    fi
done
shopt -u nullglob
next_num=$((last_num + 1))
readonly AUDIO_FILE="${AUDIO_DIR}/${next_num}.wav"
if ! DEFAULT_SOURCE=$(pactl get-default-source 2>/dev/null) || [[ -z "$DEFAULT_SOURCE" ]]; then
    log_message "Error: Could not determine default audio source"
    exit 1
fi
log_message "Recording to: $AUDIO_FILE using source: $DEFAULT_SOURCE"
ffmpeg -y -f pulse -i "$DEFAULT_SOURCE" \
    -ar 16000 -ac 1 \
    -loglevel error \
    "$AUDIO_FILE" &
FFMPEG_PID=$!
sleep 0.3
if ! kill -0 "$FFMPEG_PID" 2>/dev/null; then
    wait "$FFMPEG_PID" 2>/dev/null || true
    log_message "Error: FFMPEG failed to start recording"
    exit 1
fi
yad --title="Parakeet" \
    --text='<span size="large"><b>🔴 Recording...</b></span>' \
    --width=300 --height=100 \
    --button="Stop:0" \
    --fixed --center --undecorated --on-top
if [[ -n "$FFMPEG_PID" ]] && kill -0 "$FFMPEG_PID" 2>/dev/null; then
    kill -SIGINT "$FFMPEG_PID" 2>/dev/null || true
    for _ in {1..20}; do
        kill -0 "$FFMPEG_PID" 2>/dev/null || break
        sleep 0.1
    done
    wait "$FFMPEG_PID" 2>/dev/null || true
fi
FFMPEG_PID=""
if [[ ! -f "$AUDIO_FILE" ]]; then
    log_message "Error: Audio file was not created: $AUDIO_FILE"
    notify-send -u critical "Parakeet" "Recording failed - no file created"
    exit 1
fi
if [[ ! -s "$AUDIO_FILE" ]]; then
    log_message "Error: Audio file is empty: $AUDIO_FILE"
    notify-send -u critical "Parakeet" "Recording failed - empty file"
    rm -f "$AUDIO_FILE"
    exit 1
fi
log_message "Recording complete: $(stat -c%s "$AUDIO_FILE") bytes"
log_message "Transcribing..."
export PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"
py_exit_code=0
"${VENV_PATH}/bin/python3" -u "$PYTHON_SCRIPT" "$AUDIO_FILE" \
    >"$PYTHON_OUTPUT_TEMP_FILE" \
    2>"$PYTHON_LOG_TEMP_FILE" ||
    py_exit_code=$?
if [[ $py_exit_code -ne 0 ]]; then
    log_message "Python script failed with exit code: $py_exit_code"
    if [[ -s "$PYTHON_LOG_TEMP_FILE" ]]; then
        log_message "Python stderr output:"
        cat "$PYTHON_LOG_TEMP_FILE" >>"$LOG_FILE"
    fi
    fatal_error_dialog "Transcription failed (exit code: $py_exit_code). See log for details."
fi
FINAL_TEXT=$(<"$PYTHON_OUTPUT_TEMP_FILE")
if [[ -n "$FINAL_TEXT" ]]; then
    printf '%s' "$FINAL_TEXT" | wl-copy
    notify-send "Parakeet" "Text copied to clipboard." -t 2000
    log_message "Success: $FINAL_TEXT"
else
    notify-send "Parakeet" "No speech detected." -t 2000
    log_message "Result was empty (silence or no speech detected)."
fi
