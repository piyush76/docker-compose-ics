#!/bin/bash
set -e


SERVICE_NAME="${1:-all}"
TARGET_HOST="${2:-localhost}"
MAX_RETRIES="${3:-10}"
RETRY_INTERVAL="${4:-30}"

echo "Starting health check for: $SERVICE_NAME"
echo "Target host: $TARGET_HOST"

check_http_endpoint() {
    local url="$1"
    local service_name="$2"
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        echo "Checking $service_name health at $url (attempt $((retry_count + 1))/$MAX_RETRIES)"
        
        if curl -f -s "$url" > /dev/null 2>&1; then
            echo "✅ $service_name is healthy"
            return 0
        fi
        
        echo "❌ $service_name health check failed, retrying in $RETRY_INTERVAL seconds..."
        sleep $RETRY_INTERVAL
        retry_count=$((retry_count + 1))
    done
    
    echo "🚨 $service_name health check failed after $MAX_RETRIES attempts"
    return 1
}

check_oracle_database() {
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        echo "Checking Oracle database health (attempt $((retry_count + 1))/$MAX_RETRIES)"
        
        if docker-compose exec -T oracle-db sqlplus -L sys/\$ORACLE_PWD@//localhost:1521/XE as sysdba <<< "SELECT 1 FROM DUAL;" > /dev/null 2>&1; then
            echo "✅ Oracle database is healthy"
            return 0
        fi
        
        echo "❌ Oracle database health check failed, retrying in $RETRY_INTERVAL seconds..."
        sleep $RETRY_INTERVAL
        retry_count=$((retry_count + 1))
    done
    
    echo "🚨 Oracle database health check failed after $MAX_RETRIES attempts"
    return 1
}

check_all_services() {
    local all_healthy=true
    
    echo "🔍 Checking all services health..."
    
    if ! check_oracle_database; then
        all_healthy=false
    fi
    
    if ! check_http_endpoint "http://$TARGET_HOST:9091/actuator/health/liveness" "ics-service-liveness"; then
        all_healthy=false
    fi
    
    if ! check_http_endpoint "http://$TARGET_HOST:9091/actuator/health/readiness" "ics-service-readiness"; then
        all_healthy=false
    fi
    
    if ! check_http_endpoint "http://$TARGET_HOST:9090/chemicals/api/actuator/health" "ics-service-application"; then
        all_healthy=false
    fi
    
    if [ "$all_healthy" = true ]; then
        echo "🎉 All services are healthy!"
        return 0
    else
        echo "💥 One or more services failed health checks"
        return 1
    fi
}

case "$SERVICE_NAME" in
    "oracle"|"database"|"db")
        check_oracle_database
        ;;
    "ics-service"|"app"|"application")
        check_http_endpoint "http://$TARGET_HOST:9091/actuator/health/liveness" "ics-service-liveness" &&
        check_http_endpoint "http://$TARGET_HOST:9091/actuator/health/readiness" "ics-service-readiness"
        ;;
    "liveness")
        check_http_endpoint "http://$TARGET_HOST:9091/actuator/health/liveness" "ics-service-liveness"
        ;;
    "readiness")
        check_http_endpoint "http://$TARGET_HOST:9091/actuator/health/readiness" "ics-service-readiness"
        ;;
    "all"|*)
        check_all_services
        ;;
esac

echo "Health check completed for: $SERVICE_NAME"
