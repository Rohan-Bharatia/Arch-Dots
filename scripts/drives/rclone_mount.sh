#!/usr/bin/env bash

set -euo pipefail

MOUNTPOINT="$HOME/gdrive"
REMOTE="remote:"

echo "Unmounting existing mount (if any)..."
if mountpoint -q "$MOUNTPOINT"; then
    fusermount -u "$MOUNTPOINT"
fi
echo "Recreating mount directory..."
rm -rf "$MOUNTPOINT"
mkdir -p "$MOUNTPOINT"
echo "Mounting entire Google Drive..."
rclone mount "$REMOTE" "$MOUNTPOINT" \
    --vfs-cache-mode full \
    --allow-other \
    --drive-shared-with-me \
    -vv \
    --vfs-read-chunk-size 32M \
    --vfs-read-chunk-size-limit 2G \
    --dir-cache-time 72h \
    --poll-interval 15s \
    --uid $(id -u) \
    --gid $(id -g)
