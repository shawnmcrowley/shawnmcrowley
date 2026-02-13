#!/bin/bash

echo "Starting Docker cleanup..."

# Remove unused Docker images
docker image prune -f

# Remove all stopped containers
docker container prune -f

# Remove unused (dangling) volumes
docker volume prune -f

echo "Cleaning unused Docker images older than 24 hours..."
docker image prune -af --filter "until=24h"

echo "Removing old application images (keeping latest)..."
docker images --filter=reference='myapp*' --format "{{.ID}}" \
  | tail -n +3 \
  | xargs docker rmi -f

echo "Docker cleanup completed successfully ✅"
