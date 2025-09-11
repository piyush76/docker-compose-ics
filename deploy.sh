#!/bin/bash

set -e


if [ $# -eq 0 ]; then
    echo "Usage: $0 <server_name>"
    echo "Available servers: dkrc01, dkrc02"
    exit 1
fi

SERVER_NAME=$1
ENV_FILE=".env.${SERVER_NAME}"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Environment file $ENV_FILE not found"
    echo "Available environment files:"
    ls -1 .env.* 2>/dev/null || echo "No environment files found"
    exit 1
fi

echo "Deploying to server: $SERVER_NAME"
echo "Using environment file: $ENV_FILE"

set -a
source "$ENV_FILE"
set +a

TEMP_CONFIG_DIR="./config_processed"
mkdir -p "$TEMP_CONFIG_DIR"

echo "Processing monitoring configurations..."

envsubst < config/prometheus.yml | sed "s/SERVER_ID_PLACEHOLDER/${SERVER_ID}/g" > "$TEMP_CONFIG_DIR/prometheus.yml"

envsubst < config/alertmanager.yml | sed "s/SERVER_ID_PLACEHOLDER/${SERVER_ID}/g" | sed "s|SLACK_WEBHOOK_URL_PLACEHOLDER|${SLACK_WEBHOOK_URL}|g" > "$TEMP_CONFIG_DIR/alertmanager.yml"

cp config/loki-config.yml "$TEMP_CONFIG_DIR/"
cp config/promtail-config.yml "$TEMP_CONFIG_DIR/"
cp config/alert-rules.yml "$TEMP_CONFIG_DIR/"

cp -r config/grafana "$TEMP_CONFIG_DIR/"

echo "Logging into Azure Container Registry..."
echo "$ACR_PASSWORD" | docker login incora.azurecr.io --username "$ACR_USERNAME" --password-stdin

echo "Starting deployment..."
COMPOSE_FILE="docker-compose.unified.yml"

sed "s|./config/|./${TEMP_CONFIG_DIR}/|g" "$COMPOSE_FILE" > "${TEMP_CONFIG_DIR}/docker-compose.yml"

docker-compose -f "${TEMP_CONFIG_DIR}/docker-compose.yml" --env-file "$ENV_FILE" up -d

echo "Deployment completed successfully!"
echo ""
echo "Access URLs:"
echo "  Grafana: http://${SERVER_HOSTNAME}:${GRAFANA_PORT}"
echo "  Prometheus: http://${SERVER_HOSTNAME}:${PROMETHEUS_PORT}"
echo "  Alertmanager: http://${SERVER_HOSTNAME}:${ALERTMANAGER_PORT}"
echo "  Jaeger: http://${SERVER_HOSTNAME}:${JAEGER_UI_PORT}"
echo ""
echo "To check status: docker-compose -f ${TEMP_CONFIG_DIR}/docker-compose.yml ps"
echo "To view logs: docker-compose -f ${TEMP_CONFIG_DIR}/docker-compose.yml logs -f"
