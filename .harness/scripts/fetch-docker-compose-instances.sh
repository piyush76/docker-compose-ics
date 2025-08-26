#!/bin/bash
set -e


COMPOSE_PATH="${1:-/opt/ics-service}"
TARGET_HOST="${2:-localhost}"

echo "Fetching docker-compose instances from: $COMPOSE_PATH" >&2

cd "$COMPOSE_PATH"

if [ ! -f "docker-compose.yml" ]; then
    echo "Error: docker-compose.yml not found in $COMPOSE_PATH" >&2
    echo "[]"
    exit 0
fi

services=$(docker-compose ps --format json 2>/dev/null || echo "[]")

if [ "$services" = "[]" ] || [ -z "$services" ]; then
    echo "[]"
    exit 0
fi

echo "$services" | jq -r --arg target_host "$TARGET_HOST" '
  if type == "array" then
    map({
      "instanceName": .Name,
      "host": {
        "hostName": $target_host,
        "ip": $target_host
      },
      "properties": {
        "serviceName": .Service,
        "state": .State,
        "ports": .Ports,
        "image": .Image,
        "created": .CreatedAt,
        "status": .Status
      }
    })
  else
    [{
      "instanceName": .Name,
      "host": {
        "hostName": $target_host,
        "ip": $target_host
      },
      "properties": {
        "serviceName": .Service,
        "state": .State,
        "ports": .Ports,
        "image": .Image,
        "created": .CreatedAt,
        "status": .Status
      }
    }]
  end'
