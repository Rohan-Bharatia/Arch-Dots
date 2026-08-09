#!/usr/bin/env bash

set -euo pipefail

MOUNTPOINT="$HOME/gdrive"
REMOTE="remote:"

if mount | grep "$MOUNTPOINT"; then
    umount -l "$MOUNTPOINT"
fi

rm -rf "$MOUNTPOINT"
mkdir -p "$MOUNTPOINT"

rclone mount "$REMOTE" "$MOUNTPOINT" --vfs-cache-mode full --allow-other --drive-shared-with-me -vv \
    --vfs-read-chunk-size 32M --vfs-read-chunk-size-limit 2G --dir-cache-time 72h --poll-interval 10s \
    --uid $(id -u) --gid $(id -g) &
