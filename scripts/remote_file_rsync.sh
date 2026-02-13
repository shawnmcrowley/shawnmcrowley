#!/bin/bash

# -----------------------------
# Sync Configuration
# -----------------------------
LOCAL_DIR="/var/www/myapp/"
REMOTE_DIR="user@remote.server:/var/www/myapp/"

echo "Starting file synchronization..."

# Sync local files to remote server
rsync -avz --delete "$LOCAL_DIR" "$REMOTE_DIR"

echo "Files have been successfully synced to the remote server ✅"
