#!/usr/bin/env bash

set -euo pipefail
readonly MONO_SINK_NAME="mono_global_downmix"
readonly STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/mono_audio_state_${UID}"

get_sink_id_by_name() {
    pactl list sinks short 2>/dev/null | awk -v name="$1" '$2 == name {print $1; exit}'
}
get_sink_name_by_id() {
    pactl list sinks short 2>/dev/null | awk -v id="$1" '$1 == id {print $2; exit}'
}

wait_for_sink() {
    local sink_name="$1"
    local attempts=0
    local max_attempts=20 # 1 second total

    while (( attempts++ < max_attempts )); do
        if pactl list sinks short 2>/dev/null | grep -q "$sink_name"; then
            return 0
        fi
        sleep 0.05
    done
    return 1
}

move_streams() {
    local target_name="$1"
    local target_id=$(get_sink_id_by_name "$target_name")
    if [[ -z "$target_id" ]]; then
        return 0
    fi
    while read -r stream_id current_sink_id _rest; do
        if [[ -n "$stream_id" ]]; then
            if [[ "$current_sink_id" == "$target_id" ]]; then
                continue
            fi
            pactl move-sink-input "$stream_id" "$target_id" 2>/dev/null || true
        fi
    done < <(pactl list sink-inputs short 2>/dev/null)
}

get_busiest_sink_id() {
    pactl list sink-inputs short 2>/dev/null | awk '
        { count[$2]++ }
        END {
            max = 0
            best = ""
            for (id in count) {
                if (count[id] > max) {
                    max = count[id]
                    best = id
                }
            }
            print best
        }
    '
}

cleanup_mono_modules() {
    pactl list modules short 2>/dev/null | grep "module-loopback" | while read -r mod_id _rest; do
        if pactl list modules | grep -A 20 "Module #$mod_id" | grep -q "source=${MONO_SINK_NAME}.monitor"; then
            pactl unload-module "$mod_id" 2>/dev/null || true
        fi
    done
    pactl list modules short 2>/dev/null | grep "module-null-sink" | while read -r mod_id _rest; do
        if pactl list modules | grep -A 20 "Module #$mod_id" | grep -q "sink_name=${MONO_SINK_NAME}"; then
            pactl unload-module "$mod_id" 2>/dev/null || true
        fi
    done
}

CURRENT_NULL_ID=$(pactl list modules short 2>/dev/null | awk -v name="sink_name=$MONO_SINK_NAME" '$0 ~ name {print $1; exit}')
if [[ -n "$CURRENT_NULL_ID" ]]; then
    RESTORE_SINK=""
    if [[ -s "$STATE_FILE" ]]; then
        RESTORE_SINK=$(<"$STATE_FILE")
    fi
    if [[ -z "$RESTORE_SINK" ]]; then
        RESTORE_SINK=$(pactl list sinks short 2>/dev/null | awk -v mono="$MONO_SINK_NAME" '$2 != mono {print $2; exit}')
    fi
    if [[ -z "${RESTORE_SINK:-}" ]]; then
        notify-send -u critical "Audio Error" "Could not find hardware sink to restore!" || true
        exit 1
    fi
    pactl set-default-sink "$RESTORE_SINK" || true
    move_streams "$RESTORE_SINK"
    cleanup_mono_modules
    rm -f "$STATE_FILE"
    notify-send -u low -t 2000 "Audio" "Switched to Stereo 🎧" || true
else
    BUSIEST_SINK_ID=$(get_busiest_sink_id)
    TARGET_HARDWARE_SINK=""
    if [[ -n "$BUSIEST_SINK_ID" ]]; then
        TARGET_HARDWARE_SINK=$(get_sink_name_by_id "$BUSIEST_SINK_ID")
    fi
    if [[ -z "$TARGET_HARDWARE_SINK" ]]; then
        TARGET_HARDWARE_SINK=$(pactl get-default-sink)
    fi
    if [[ -z "$TARGET_HARDWARE_SINK" ]]; then
        notify-send -u critical "Audio Error" "No audio device found!" || true
        exit 1
    fi
    printf "%s" "$TARGET_HARDWARE_SINK" > "$STATE_FILE"
    if ! pactl load-module module-null-sink \
        sink_name="$MONO_SINK_NAME" \
        sink_properties='device.description="Mono_Downmix"' \
        channels=1 \
        channel_map=mono > /dev/null; then
        notify-send -u critical "Audio Error" "Failed to create null sink." || true
        exit 1
    fi
    if ! wait_for_sink "$MONO_SINK_NAME"; then
        notify-send -u critical "Audio Error" "Mono sink failed to register." || true
        cleanup_mono_modules
        exit 1
    fi
    pactl set-default-sink "$MONO_SINK_NAME" || true
    move_streams "$MONO_SINK_NAME"
    if ! pactl load-module module-loopback \
        source="${MONO_SINK_NAME}.monitor" \
        sink="$TARGET_HARDWARE_SINK" \
        channels=2 \
        channel_map=front-left,front-right > /dev/null; then
        notify-send -u critical "Audio Error" "Failed to create loopback." || true
        cleanup_mono_modules
        exit 1
    fi
    notify-send -u low -t 2000 "Audio" "Switched to Mono 🔊" || true
fi
