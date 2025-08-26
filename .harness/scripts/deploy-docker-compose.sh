#!/bin/bash
set -e


OPERATION="${1:-deploy}"
COMPOSE_PATH="${2:-/opt/ics-service}"
ENV_FILE_PATH="${3:-/opt/ics-service/.env}"
TIMEOUT="${4:-300}"

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

wait_for_database() {
    echo "Waiting for Oracle database to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec -T oracle-db sqlplus -L sys/\$ORACLE_PWD@//localhost:1521/XE as sysdba <<< "SELECT 1 FROM DUAL;" > /dev/null 2>&1; then
            echo "Oracle database is ready"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: Database not ready yet..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: Database failed to become ready after $max_attempts attempts"
    return 1
}

deploy_services() {
    echo "Starting deployment of docker-compose services..."
    
    echo "Pulling latest images..."
    docker-compose pull
    
    echo "Starting services..."
    docker-compose up -d
    
    wait_for_database
    
    echo "Waiting for ics-service to be ready..."
    sleep 45  # Initial delay for service startup
    
    check_service_health "ics-service-liveness" "http://localhost:9091/actuator/health/liveness"
    check_service_health "ics-service-readiness" "http://localhost:9091/actuator/health/readiness"
    
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
