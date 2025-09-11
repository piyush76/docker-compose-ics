#!/bin/bash


set -e

if [ -z "$ACR_USERNAME" ] || [ -z "$ACR_PASSWORD" ]; then
    echo "Error: ACR_USERNAME and ACR_PASSWORD environment variables must be set"
    echo "Please ensure your .env file contains these variables or export them:"
    echo "  export ACR_USERNAME=your-username"
    echo "  export ACR_PASSWORD=your-password"
    exit 1
fi

echo "Logging into Azure Container Registry (incora.azurecr.io)..."
echo "$ACR_PASSWORD" | docker login incora.azurecr.io --username "$ACR_USERNAME" --password-stdin

if [ $? -eq 0 ]; then
    echo "Successfully logged into Azure Container Registry"
else
    echo "Failed to login to Azure Container Registry"
    exit 1
fi
