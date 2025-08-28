#!/bin/bash
set -e

OPERATION="${1:-deploy}"
COMPOSE_PATH="${2:-/opt/ics-service}"
ENV_FILE_PATH="${3:-/opt/ics-service/.env}"
TIMEOUT="${4:-300}"
ENVIRONMENT="${5:-dev}"

echo "Environment: $ENVIRONMENT"

echo "Starting docker-compose operation: $OPERATION"
echo "Compose path: $COMPOSE_PATH"
echo "Environment file: $ENV_FILE_PATH"

cd "$COMPOSE_PATH"

check_service_health() {
    local service_name="$1"
    local health_url="$2"
    local max_attempts=30
    local attempt=1
    
    echo "Checking health for $service_name at $health_url"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$health_url" > /dev/null 2>&1; then
            echo "$service_name is healthy"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: $service_name not ready yet..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: $service_name failed health check after $max_attempts attempts"
    return 1
}

check_external_database_connectivity() {
    echo "Checking external Oracle database connectivity through application..."
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "http://localhost:9091/actuator/health" | grep -q '"status":"UP"'; then
            echo "External Oracle database connectivity verified"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: Checking database connectivity..."
        sleep 15
        attempt=$((attempt + 1))
    done
    
    echo "WARNING: Could not verify external database connectivity"
    return 1
}

deploy_services() {
    echo "Starting deployment of docker-compose services..."
    
    echo "Copying environment-specific configuration..."
    cp environments/${ENVIRONMENT}/docker-compose.yml .
    cp environments/${ENVIRONMENT}/.env.example .env
    cp environments/${ENVIRONMENT}/docker-login.sh .
    cp -r environments/${ENVIRONMENT}/monitoring .
    
    echo "Logging into Azure Container Registry..."
    chmod +x docker-login.sh
    ./docker-login.sh
    
    echo "Pulling latest images..."
    docker-compose pull
    
    echo "Starting services..."
    docker-compose up -d
    
    echo "Waiting for ics-service to be ready..."
    sleep 45  # Initial delay for service startup
    
    check_service_health "ics-service-liveness" "http://localhost:9091/actuator/health/liveness"
    check_service_health "ics-service-readiness" "http://localhost:9091/actuator/health/readiness"
    
    echo "Waiting for monitoring services to be ready..."
    sleep 30  # Additional delay for monitoring stack
    
    check_service_health "prometheus" "http://localhost:9092/-/healthy"
    check_service_health "loki" "http://localhost:3100/ready"
    check_service_health "grafana" "http://localhost:3000/api/health"
    
    echo "Deployment completed successfully!"
}

rollback_services() {
    echo "Starting rollback of docker-compose services..."
    
    docker-compose down
    
    echo "Rollback completed. Manual intervention may be required to restore previous state."
}

stop_services() {
    echo "Stopping docker-compose services..."
    docker-compose down
    echo "Services stopped successfully!"
}

get_status() {
    echo "Getting service status..."
    docker-compose ps
}

case "$OPERATION" in
    "deploy")
        deploy_services
        ;;
    "rollback")
        rollback_services
        ;;
    "stop")
        stop_services
        ;;
    "status")
        get_status
        ;;
    *)
        echo "Usage: $0 {deploy|rollback|stop|status} [compose_path] [env_file_path] [timeout]"
        exit 1
        ;;
esac

echo "Operation $OPERATION completed successfully!"
