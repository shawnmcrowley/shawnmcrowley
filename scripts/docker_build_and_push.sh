#!/bin/bash

# -----------------------------
# Docker Image Configuration
# -----------------------------
DOCKER_USERNAME="your_dockerhub_username"
IMAGE_NAME="myapp"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="$DOCKER_USERNAME/$IMAGE_NAME:$IMAGE_TAG"

echo "Building Docker image..."

# -----------------------------
# Build Docker Image
# -----------------------------
docker build -t "$FULL_IMAGE_NAME" .

# -----------------------------
# Login to Docker Hub
# -----------------------------
echo "$DOCKER_PASSWORD" | docker login \
  --username "$DOCKER_USERNAME" \
  --password-stdin

# -----------------------------
# Push Image to Docker Hub
# -----------------------------
docker push "$FULL_IMAGE_NAME"

echo "Docker image $FULL_IMAGE_NAME pushed successfully ✅"
