#!/bin/bash

set -e

echo "=== Multi-Server ICS Observability Verification Script ==="
echo

DKRC01_HOST="icsdev-dkrc-01.incora.global"
DKRC02_HOST="icsdev-dkrc-02.incora.global"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

check_service() {
    local url=$1
    local service_name=$2
    local timeout=${3:-10}
    
    if curl -f -s --max-time $timeout "$url" >/dev/null 2>&1; then
        log_success "$service_name is healthy"
        return 0
    else
        log_error "$service_name is not responding"
        return 1
    fi
}

verify_server() {
    local server_host=$1
    local server_name=$2
    local prometheus_port=$3
    local grafana_port=$4
    local alertmanager_port=$5
    local loki_port=$6
    local jaeger_port=$7
    
    echo
    log_info "Verifying ${server_name} (${server_host})..."
    echo "----------------------------------------"
    
    local success_count=0
    local total_checks=7
    
    if check_service "http://${server_host}:9091/actuator/health/liveness" "ICS Service Liveness"; then
        ((success_count++))
    fi
    
    if check_service "http://${server_host}:9091/actuator/health/readiness" "ICS Service Readiness"; then
        ((success_count++))
    fi
    
    if check_service "http://${server_host}:${prometheus_port}/-/healthy" "Prometheus"; then
        ((success_count++))
    fi
    
    if check_service "http://${server_host}:${grafana_port}/api/health" "Grafana"; then
        ((success_count++))
    fi
    
    if check_service "http://${server_host}:${alertmanager_port}/-/healthy" "Alertmanager"; then
        ((success_count++))
    fi
    
    if check_service "http://${server_host}:${loki_port}/ready" "Loki"; then
        ((success_count++))
    fi
    
    if check_service "http://${server_host}:${jaeger_port}/" "Jaeger"; then
        ((success_count++))
    fi
    
    echo
    if [ $success_count -eq $total_checks ]; then
        log_success "${server_name}: All services healthy (${success_count}/${total_checks})"
    elif [ $success_count -gt $((total_checks / 2)) ]; then
        log_warn "${server_name}: Partially healthy (${success_count}/${total_checks})"
    else
        log_error "${server_name}: Mostly unhealthy (${success_count}/${total_checks})"
    fi
    
    return $((total_checks - success_count))
}

check_metrics() {
    local server_host=$1
    local server_name=$2
    local prometheus_port=$3
    
    log_info "Checking metrics collection on ${server_name}..."
    
    local targets_up=$(curl -s "http://${server_host}:${prometheus_port}/api/v1/query?query=up" | grep -o '"value":\[.*,"1"\]' | wc -l)
    
    if [ "$targets_up" -gt 0 ]; then
        log_success "${server_name}: Prometheus is collecting metrics from ${targets_up} targets"
    else
        log_error "${server_name}: No metrics targets are up"
    fi
    
    if curl -s "http://${server_host}:9091/actuator/prometheus" | grep -q "http_server_requests_seconds"; then
        log_success "${server_name}: ICS service metrics are available"
    else
        log_error "${server_name}: ICS service metrics not found"
    fi
}

check_logs() {
    local server_host=$1
    local server_name=$2
    local loki_port=$3
    
    log_info "Checking log collection on ${server_name}..."
    
    if curl -s "http://${server_host}:${loki_port}/loki/api/v1/label" | grep -q "job"; then
        log_success "${server_name}: Loki is collecting logs"
    else
        log_warn "${server_name}: Loki may not be collecting logs yet"
    fi
}

show_access_urls() {
    echo
    log_info "Monitoring Access URLs:"
    echo "========================================"
    echo
    echo "DKRC01 (${DKRC01_HOST}):"
    echo "  Grafana:      http://${DKRC01_HOST}:3000"
    echo "  Prometheus:   http://${DKRC01_HOST}:9092"
    echo "  Alertmanager: http://${DKRC01_HOST}:9093"
    echo "  Jaeger:       http://${DKRC01_HOST}:16686"
    echo "  ICS Service:  http://${DKRC01_HOST}:9090/chemicals/api"
    echo
    echo "DKRC02 (${DKRC02_HOST}):"
    echo "  Grafana:      http://${DKRC02_HOST}:3001"
    echo "  Prometheus:   http://${DKRC02_HOST}:9094"
    echo "  Alertmanager: http://${DKRC02_HOST}:9095"
    echo "  Jaeger:       http://${DKRC02_HOST}:16687"
    echo "  ICS Service:  http://${DKRC02_HOST}:9090/chemicals/api"
    echo
    echo "Default Grafana credentials: admin/admin123"
}

main() {
    echo "Verifying multi-server ICS observability deployment..."
    echo "Servers: ${DKRC01_HOST}, ${DKRC02_HOST}"
    echo
    
    local dkrc01_errors=0
    local dkrc02_errors=0
    
    verify_server "${DKRC01_HOST}" "DKRC01" "9092" "3000" "9093" "3100" "16686"
    dkrc01_errors=$?
    
    verify_server "${DKRC02_HOST}" "DKRC02" "9094" "3001" "9095" "3101" "16687"
    dkrc02_errors=$?
    
    echo
    log_info "Checking metrics and logs collection..."
    echo "----------------------------------------"
    check_metrics "${DKRC01_HOST}" "DKRC01" "9092"
    check_metrics "${DKRC02_HOST}" "DKRC02" "9094"
    
    check_logs "${DKRC01_HOST}" "DKRC01" "3100"
    check_logs "${DKRC02_HOST}" "DKRC02" "3101"
    
    show_access_urls
    
    echo
    echo "========================================"
    if [ $dkrc01_errors -eq 0 ] && [ $dkrc02_errors -eq 0 ]; then
        log_success "All services are healthy on both servers!"
        echo "Your multi-server observability deployment is ready."
    elif [ $dkrc01_errors -eq 0 ] || [ $dkrc02_errors -eq 0 ]; then
        log_warn "One server is fully healthy, the other has issues."
        echo "Check the logs and troubleshoot the failing services."
    else
        log_error "Both servers have issues."
        echo "Please check the deployment and troubleshoot the failing services."
    fi
    
    echo
    echo "For troubleshooting, check:"
    echo "1. Container logs: docker-compose logs <service-name>"
    echo "2. Service status: docker-compose ps"
    echo "3. Network connectivity between containers"
    echo "4. Environment variables in .env file"
    
    return $((dkrc01_errors + dkrc02_errors))
}

main "$@"
