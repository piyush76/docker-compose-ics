#!/bin/bash

set -e

echo "Logging into Azure Container Registry..."

if [ -f .env ]; then
    source .env
fi

ACR_USERNAME="${ACR_USERNAME}"
ACR_PASSWORD="${ACR_PASSWORD}"
ACR_REGISTRY="${ACR_REGISTRY:-incora.azurecr.io}"

if [ -z "$ACR_USERNAME" ] || [ -z "$ACR_PASSWORD" ]; then
    echo "ERROR: ACR_USERNAME and ACR_PASSWORD must be set in .env file"
    echo "Please copy .env.example to .env and set the actual credentials"
    exit 1
fi

echo "$ACR_PASSWORD" | docker login "$ACR_REGISTRY" --username "$ACR_USERNAME" --password-stdin

echo "Successfully logged into $ACR_REGISTRY"
echo "You can now run: docker-compose up -d"
