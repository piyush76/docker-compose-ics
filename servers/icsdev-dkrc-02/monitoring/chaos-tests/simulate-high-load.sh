#!/bin/bash


DURATION=${1:-5}  # Default 5 minutes
CONCURRENT=${2:-10}  # Default 10 concurrent requests
BASE_URL="http://localhost:9090/chemicals/api"

echo "Starting high load simulation for $DURATION minutes with $CONCURRENT concurrent requests"
echo "Target URL: $BASE_URL"

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
        sleep 0.1  # Small delay between requests
    done
}

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

wait

echo "Load simulation completed"
echo "Check Grafana dashboards and Alertmanager for triggered alerts"
