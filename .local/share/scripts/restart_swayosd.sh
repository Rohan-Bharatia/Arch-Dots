#!/usr/bin/env bash

set -e

if [[ ! -x /usr/bin/swayosd-server ]]; then
    printf "Server binary not found or not executable: /usr/bin/swayosd-server"
    exit 1
fi
if pgrep -x swayosd-server 2>/dev/null 2>&1; then
    pkill -x swayosd-server 2>/dev/null || true
    for ((_i = 0; _i < 20; _i++)); do
        pgrep -x swayosd-server 2>/dev/null 2>&1 || break
        sleep 0.1
    done
    if pgrep -x swayosd-server 2>/dev/null 2>&1; then
        pkill -9 -x swayosd-server 2>/dev/null || true
        sleep 0.1
    fi
    if pgrep -x swayosd-server 2>/dev/null 2>&1; then
        printf "Failed to terminate existing swayosd-server process"
        exit 1
    fi
fi
if command -v uwsm-app >/dev/null 2>&1; then
    uwsm-app -- /usr/bin/swayosd-server >/dev/null 2>&1 &
else
    setsid /usr/bin/swayosd-server >/dev/null 2>&1 &
fi
disown 2>/dev/null || true
sleep 0.5
if pgrep -x swayosd-server 2>/dev/null 2>&1; then
    printf "SwayOSD server restarted"
    exit 0
else
    printf "SwayOSD server failed to start"
    exit 1
fi
