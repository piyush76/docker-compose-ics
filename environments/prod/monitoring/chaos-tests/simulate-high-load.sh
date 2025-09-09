#!/bin/bash


DURATION=${1:-3}  # Default 3 minutes for production
CONCURRENT=${2:-5}  # Default 5 concurrent requests for production
BASE_URL="http://localhost:9090/chemicals/api"

echo "Starting PRODUCTION high load simulation for $DURATION minutes with $CONCURRENT concurrent requests"
echo "Target URL: $BASE_URL"
echo "WARNING: This is a production environment test - use with caution"

make_requests() {
    local endpoint=$1
    local method=${2:-GET}
    local duration_seconds=$((DURATION * 60))
    local end_time=$(($(date +%s) + duration_seconds))
    
    while [ $(date +%s) -lt $end_time ]; do
        if [ "$method" = "GET" ]; then
            curl -s -o /dev/null -w "%{http_code}\n" "$BASE_URL$endpoint" || echo "FAILED"
        else
            curl -s -o /dev/null -w "%{http_code}\n" -X "$method" "$BASE_URL$endpoint" || echo "FAILED"
        fi
        sleep 0.5  # Longer delay for production
    done
}

read -p "Are you sure you want to run load testing on PRODUCTION? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Load testing cancelled"
    exit 0
fi

echo "Starting load simulation..."

for i in $(seq 1 $((CONCURRENT / 2))); do
    make_requests "/actuator/health" GET &
done

for i in $(seq 1 $((CONCURRENT / 4))); do
    make_requests "/iam/user" GET &
done

for i in $(seq 1 $((CONCURRENT / 4))); do
    make_requests "/non-existent-endpoint" GET &
done

echo "Load simulation started with $CONCURRENT concurrent processes"
echo "Simulation will run for $DURATION minutes"
echo "Monitor alerts in Grafana: http://localhost:3000"
echo "Monitor Prometheus: http://localhost:9092"
echo "Monitor Alertmanager: http://localhost:9093"

wait

echo "Load simulation completed"
echo "Check Grafana dashboards and Alertmanager for triggered alerts"
