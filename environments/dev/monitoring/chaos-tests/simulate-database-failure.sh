#!/bin/bash


DURATION=${1:-3}  # Default 3 minutes

echo "Simulating database connectivity issues for $DURATION minutes"

simulate_network_failure() {
    echo "Blocking network traffic to database server..."
    
    sudo iptables -A OUTPUT -d infdev-ora01a.tcmis.com -j DROP
    
    echo "Database traffic blocked. Waiting $DURATION minutes..."
    sleep $((DURATION * 60))
    
    echo "Restoring database connectivity..."
    sudo iptables -D OUTPUT -d infdev-ora01a.tcmis.com -j DROP
    
    echo "Database connectivity restored"
}

simulate_config_failure() {
    echo "Modifying database configuration to cause failures..."
    
    docker exec ics-service-dev sh -c 'export DB_URL="jdbc:oracle:thin:@//invalid-host:1521/INVALID"'
    
    echo "Restarting service with invalid database configuration..."
    docker restart ics-service-dev
    
    echo "Waiting $DURATION minutes for alerts to trigger..."
    sleep $((DURATION * 60))
    
    echo "Restoring correct database configuration..."
    docker restart ics-service-dev
    
    echo "Service restarted with correct configuration"
}

simulate_connection_exhaustion() {
    echo "Attempting to exhaust database connection pool..."
    
    for i in $(seq 1 50); do
        curl -s "http://localhost:9090/chemicals/api/iam/user" &
    done
    
    echo "Connection pool exhaustion simulation running for $DURATION minutes..."
    sleep $((DURATION * 60))
    
    jobs -p | xargs -r kill
    
    echo "Connection exhaustion simulation completed"
}

echo "Choose simulation method:"
echo "1. Network failure (requires sudo)"
echo "2. Configuration failure"
echo "3. Connection pool exhaustion"
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        if [ "$EUID" -eq 0 ]; then
            simulate_network_failure
        else
            echo "Network failure simulation requires root privileges"
            echo "Run with: sudo $0"
            exit 1
        fi
        ;;
    2)
        simulate_config_failure
        ;;
    3)
        simulate_connection_exhaustion
        ;;
    *)
        echo "Invalid choice. Using connection pool exhaustion method."
        simulate_connection_exhaustion
        ;;
esac

echo "Database failure simulation completed"
echo "Check the following for alerts:"
echo "- Grafana: http://localhost:3000"
echo "- Alertmanager: http://localhost:9093"
echo "- Prometheus: http://localhost:9092"
