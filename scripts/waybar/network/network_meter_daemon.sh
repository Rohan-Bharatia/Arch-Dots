#!/usr/bin/env bash

set -euo pipefail

if [[ -f /usr/lib/bash/sleep ]]; then
    enable -f /usr/lib/bash/sleep sleep 2>/dev/null || true
fi

RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
STATE_DIR="$RUNTIME/waybar-net"
STATE_FILE="$STATE_DIR/state"
HEARTBEAT_FILE="$STATE_DIR/heartbeat"
PID_FILE="$STATE_DIR/daemon.pid"

mkdir -p "$STATE_DIR"
touch "$HEARTBEAT_FILE"
echo $$ > "$PID_FILE"
trap 'rm -rf "$STATE_DIR"' EXIT
trap ':' USR1

get_primary_iface() {
    ip route get 1.1.1.1 2>/dev/null | \
        awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}' || :
}

get_time_us() {
    local -n _out=$1
    local s us
    IFS=. read -r s us <<< "${EPOCHREALTIME:-0.0}"
    us="${us}000000"
    _out=$(( s * 1000000 + 10#${us:0:6} ))
}

format_speed() {
    local -n _unit=$1 _tx=$2 _rx=$3 _class=$4
    local rx_d=$5 tx_d=$6
    local max=$(( rx_d > tx_d ? rx_d : tx_d ))
    if (( max >= 1048576 )); then
        local tx_x10=$(( tx_d * 10 / 1048576 ))
        local rx_x10=$(( rx_d * 10 / 1048576 ))
        if (( tx_x10 < 100 )); then
            _tx="$((tx_x10 / 10)).$((tx_x10 % 10))"
        else
            _tx="$((tx_x10 / 10))"
        fi
        if (( rx_x10 < 100 )); then
            _rx="$((rx_x10 / 10)).$((rx_x10 % 10))"
        else
            _rx="$((rx_x10 / 10))"
        fi
        _unit="MB"
        _class="network-mb"
    else
        _tx=$(( tx_d / 1024 ))
        _rx=$(( rx_d / 1024 ))
        _unit="KB"
        _class="network-kb"
    fi
}

rx_prev=0
tx_prev=0
iface=""
iface_counter=0
hb_counter=2
hb_time=0
while :; do
    now=$(printf '%(%s)T' -1)
    if (( ++hb_counter >= 3 )); then
        hb_counter=0
        if [[ -f "$HEARTBEAT_FILE" ]]; then
            hb_time=$(stat -c %Y "$HEARTBEAT_FILE" 2>/dev/null) || hb_time=$now
        else
            hb_time=$now
        fi
    fi
    if (( now - hb_time > 10 )); then
        sleep 600 &
        wait $! || true
        hb_counter=10
        continue
    fi
    if (( ++iface_counter >= 5 )) || [[ -z "$iface" ]]; then
        iface_counter=0
        current_iface=$(get_primary_iface)
    else
        current_iface="$iface"
    fi
    if [[ -z "$current_iface" ]]; then
        printf '%s\n' "- - - network-disconnected" > "$STATE_FILE.tmp"
        mv -f "$STATE_FILE.tmp" "$STATE_FILE"
        rx_prev=0
        tx_prev=0
        iface=""
        sleep 3 || true
        continue
    fi
    get_time_us start_time
    if [[ "$current_iface" != "$iface" ]]; then
        iface="$current_iface"
        rx_prev=0
        tx_prev=0
    fi
    if [[ -r "/sys/class/net/$iface/statistics/rx_bytes" ]] && \
       [[ -r "/sys/class/net/$iface/statistics/tx_bytes" ]]; then
        read -r rx_now < "/sys/class/net/$iface/statistics/rx_bytes" || rx_now=0
        read -r tx_now < "/sys/class/net/$iface/statistics/tx_bytes" || tx_now=0
    else
        rx_now=0
        tx_now=0
    fi
    if (( rx_prev == 0 && tx_prev == 0 )); then
        rx_prev=$rx_now
        tx_prev=$tx_now
        sleep 1 || true
        continue
    fi
    rx_delta=$(( rx_now - rx_prev ))
    tx_delta=$(( tx_now - tx_prev ))
    (( rx_delta < 0 )) && rx_delta=0
    (( tx_delta < 0 )) && tx_delta=0
    rx_prev=$rx_now
    tx_prev=$tx_now
    format_speed unit tx_fmt rx_fmt class "$rx_delta" "$tx_delta"
    printf '%s %s %s %s\n' "$unit" "$tx_fmt" "$rx_fmt" "$class" > "$STATE_FILE.tmp"
    mv -f "$STATE_FILE.tmp" "$STATE_FILE"
    get_time_us end_time
    sleep_us=$(( 1000000 - (end_time - start_time) ))
    if (( sleep_us <= 0 )); then
        :
    elif (( sleep_us >= 1000000 )); then
        sleep 1 || true
    else
        printf -v sleep_sec "0.%06d" "$sleep_us"
        sleep "$sleep_sec" || true
    fi
done
