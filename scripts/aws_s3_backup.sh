#!/bin/bash

# -----------------------------
# Backup Configuration
# -----------------------------
SOURCE_DIR="/path/to/files"
S3_BUCKET="s3://my-bucket/backup"

echo "Starting backup to AWS S3..."

# Sync local files to S3 - do without --delete to validate
aws s3 sync "$SOURCE_DI" "$S3_BUCKET"
# aws s3 sync "$SOURCE_DIR" "$S3_BUCKET" --delete

echo "Backup to S3 completed successfully ✅"
