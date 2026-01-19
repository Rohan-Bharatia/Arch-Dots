#!/usr/bin/env bash

set -euo pipefail

MOUNTPOINT="$HOME/gdrive"
REMOTE="remote:"
FUSE_CONF="/etc/fuse.conf"

ensure_fuse_allow_other() {
    if grep -Eq '^\s*user_allow_other\s*$' "$FUSE_CONF"; then
        return 0
    fi
    echo "'user_allow_other' not enabled in $FUSE_CONF"
    if [[ $EUID -ne 0 ]]; then
        echo "Re-running as root to update $FUSE_CONF..."
        exec sudo --preserve-env=HOME "$0" "$@"
    fi
    echo "Enabling user_allow_other in $FUSE_CONF"
    if grep -Eq '^\s*#\s*user_allow_other\s*$' "$FUSE_CONF"; then
        sed -i 's/^\s*#\s*user_allow_other\s*$/user_allow_other/' "$FUSE_CONF"
    else
        echo "user_allow_other" >>"$FUSE_CONF"
    fi
    echo "Updated $FUSE_CONF successfully"
}

ensure_fuse_allow_other "$@"
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
