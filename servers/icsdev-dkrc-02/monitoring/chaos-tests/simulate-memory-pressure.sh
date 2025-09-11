#!/bin/bash


DURATION=${1:-5}  # Default 5 minutes

echo "Simulating memory pressure for $DURATION minutes"

simulate_high_load() {
    echo "Generating high API load to increase memory usage..."
    
    for i in $(seq 1 20); do
        (
            local end_time=$(($(date +%s) + DURATION * 60))
            while [ $(date +%s) -lt $end_time ]; do
                curl -s "http://localhost:9090/chemicals/api/iam/users?role=admin" > /dev/null &
                curl -s "http://localhost:9090/chemicals/api/catalog/item/1/safetydatasheets" > /dev/null &
                sleep 0.1
            done
        ) &
    done
    
    echo "High load simulation running..."
    wait
    echo "High load simulation completed"
}

simulate_heap_pressure() {
    echo "Reducing JVM heap size to create memory pressure..."
    
    docker stop ics-service-dev
    
    docker run -d --name ics-service-dev-temp \
        --network ics-network-dev \
        -p 9090:9090 -p 9091:9091 \
        -e JAVA_OPTS="-Xmx256m -Xms256m" \
        -e DB_URL="jdbc:oracle:thin:@//infdev-ora01a.tcmis.com:1521/ICSDEV" \
        -e DB_PASSWORD="${TCMIS_DB_SECRET:-devpassword}" \
        incora.azurecr.io/ics-service:latest
    
    echo "Service running with reduced heap size for $DURATION minutes..."
    sleep $((DURATION * 60))
    
    echo "Restoring original service configuration..."
    docker stop ics-service-dev-temp
    docker rm ics-service-dev-temp
    docker start ics-service-dev
    
    echo "Original service configuration restored"
}

simulate_external_pressure() {
    echo "Creating external memory pressure on the host..."
    
    if command -v stress >/dev/null 2>&1; then
        echo "Using stress tool to create memory pressure..."
        stress --vm 2 --vm-bytes 512M --timeout $((DURATION * 60))s &
        STRESS_PID=$!
        
        echo "External memory pressure created for $DURATION minutes..."
        wait $STRESS_PID
        echo "External memory pressure simulation completed"
    else
        echo "stress tool not available, using alternative method..."
        
        echo "Creating memory pressure using dd..."
        dd if=/dev/zero of=/tmp/memory_pressure bs=1M count=512 &
        DD_PID=$!
        
        sleep $((DURATION * 60))
        
        kill $DD_PID 2>/dev/null
        rm -f /tmp/memory_pressure
        echo "Memory pressure simulation completed"
    fi
}

echo "Choose memory pressure simulation method:"
echo "1. High API load"
echo "2. Reduced JVM heap size"
echo "3. External memory pressure"
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        simulate_high_load
        ;;
    2)
        simulate_heap_pressure
        ;;
    3)
        simulate_external_pressure
        ;;
    *)
        echo "Invalid choice. Using high API load method."
        simulate_high_load
        ;;
esac

echo "Memory pressure simulation completed"
echo "Check the following for memory-related alerts:"
echo "- Grafana JVM Memory Dashboard: http://localhost:3000"
echo "- Alertmanager: http://localhost:9093"
echo "- Prometheus JVM Metrics: http://localhost:9092"
echo ""
echo "Expected alerts:"
echo "- HighMemoryUsage (if heap usage > 90%)"
echo "- OutOfMemoryError (if OOM occurs)"
