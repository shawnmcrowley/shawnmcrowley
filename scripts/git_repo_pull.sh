#!/bin/bash

# -----------------------------
# Repository Location
# -----------------------------
REPO_DIR="/home/ubuntu/my-repo"
BRANCH="main"

echo "Starting Git auto-pull..."

cd "$REPO_DIR" || exit 1

git pull origin "$BRANCH"

echo "Repository updated successfully ✅"
