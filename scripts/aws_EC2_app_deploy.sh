#!/bin/bash

# -----------------------------
# EC2 & Application Details
# -----------------------------
INSTANCE_USER="ec2-user"
INSTANCE_HOST="ec2-xx-xxx-xxx-xx.compute-1.amazonaws.com"
SSH_KEY="your-key.pem"
APP_DIR="/path/to/app"
SERVICE_NAME="myapp.service"

echo "Starting deployment..."

# -----------------------------
# Remote Deployment
# -----------------------------
ssh -i "$SSH_KEY" "$INSTANCE_USER@$INSTANCE_HOST" << EOF
  cd "$APP_DIR"
  git pull origin main
  sudo systemctl restart "$SERVICE_NAME"
  exit
EOF

echo "Deployment completed successfully ✅"
