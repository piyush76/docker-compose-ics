#!/bin/bash


echo "=== ICS Service Monitoring Stack Validation ==="
echo "Starting comprehensive monitoring validation..."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_service() {
    local service_name=$1
    local health_url=$2
    local expected_status=${3:-200}
    
    echo -n "Checking $service_name... "
    
    if response=$(curl -s -w "%{http_code}" -o /dev/null "$health_url" 2>/dev/null); then
        if [ "$response" = "$expected_status" ]; then
            echo -e "${GREEN}✓ HEALTHY${NC}"
            return 0
        else
            echo -e "${RED}✗ UNHEALTHY (HTTP $response)${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ UNREACHABLE${NC}"
        return 1
    fi
}

check_metrics() {
    local service_name=$1
    local metrics_url=$2
    local metric_name=$3
    
    echo -n "Checking $service_name metrics ($metric_name)... "
    
    if curl -s "$metrics_url" | grep -q "$metric_name"; then
        echo -e "${GREEN}✓ AVAILABLE${NC}"
        return 0
    else
        echo -e "${RED}✗ MISSING${NC}"
        return 1
    fi
}

check_dashboard() {
    local dashboard_name=$1
    local dashboard_uid=$2
    
    echo -n "Checking Grafana dashboard ($dashboard_name)... "
    
    if curl -s -u admin:admin123 "http://localhost:3000/api/dashboards/uid/$dashboard_uid" | grep -q "\"title\""; then
        echo -e "${GREEN}✓ AVAILABLE${NC}"
        return 0
    else
        echo -e "${RED}✗ MISSING${NC}"
        return 1
    fi
}

test_alert_rules() {
    echo -n "Checking Prometheus alert rules... "
    
    if curl -s "http://localhost:9092/api/v1/rules" | grep -q "HighErrorRate"; then
        echo -e "${GREEN}✓ LOADED${NC}"
        return 0
    else
        echo -e "${RED}✗ NOT LOADED${NC}"
        return 1
    fi
}

check_log_ingestion() {
    echo -n "Checking Loki log ingestion... "
    
    if curl -s "http://localhost:3100/loki/api/v1/query_range?query={job=\"ics-service\"}&start=$(date -d '5 minutes ago' +%s)000000000&end=$(date +%s)000000000" | grep -q "values"; then
        echo -e "${GREEN}✓ LOGS INGESTED${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ NO RECENT LOGS${NC}"
        return 1
    fi
}

check_tracing() {
    echo -n "Checking Jaeger tracing... "
    
    if curl -s "http://localhost:16686/api/services" | grep -q "ics-service"; then
        echo -e "${GREEN}✓ SERVICE TRACED${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ NO TRACES YET${NC}"
        return 1
    fi
}

echo ""
echo "1. Service Health Checks"
echo "========================"

HEALTH_CHECKS=0
HEALTH_PASSED=0

if check_service "ICS Service" "http://localhost:9091/actuator/health/liveness"; then
    ((HEALTH_PASSED++))
fi
((HEALTH_CHECKS++))

if check_service "Prometheus" "http://localhost:9092/-/healthy"; then
    ((HEALTH_PASSED++))
fi
((HEALTH_CHECKS++))

if check_service "Alertmanager" "http://localhost:9093/-/healthy"; then
    ((HEALTH_PASSED++))
fi
((HEALTH_CHECKS++))

if check_service "Grafana" "http://localhost:3000/api/health"; then
    ((HEALTH_PASSED++))
fi
((HEALTH_CHECKS++))

if check_service "Loki" "http://localhost:3100/ready"; then
    ((HEALTH_PASSED++))
fi
((HEALTH_CHECKS++))

if check_service "Jaeger" "http://localhost:16686/api/services"; then
    ((HEALTH_PASSED++))
fi
((HEALTH_CHECKS++))

echo ""
echo "2. Metrics Availability"
echo "======================"

METRICS_CHECKS=0
METRICS_PASSED=0

if check_metrics "ICS Service" "http://localhost:9091/actuator/prometheus" "http_server_requests_seconds"; then
    ((METRICS_PASSED++))
fi
((METRICS_CHECKS++))

if check_metrics "ICS Service JVM" "http://localhost:9091/actuator/prometheus" "jvm_memory_used_bytes"; then
    ((METRICS_PASSED++))
fi
((METRICS_CHECKS++))

if check_metrics "ICS Service DB" "http://localhost:9091/actuator/prometheus" "hikaricp_connections"; then
    ((METRICS_PASSED++))
fi
((METRICS_CHECKS++))

echo ""
echo "3. Grafana Dashboards"
echo "===================="

DASHBOARD_CHECKS=0
DASHBOARD_PASSED=0

if check_dashboard "ICS Service Health" "ics-service-health"; then
    ((DASHBOARD_PASSED++))
fi
((DASHBOARD_CHECKS++))

if check_dashboard "ICS Business KPIs" "ics-business-kpis"; then
    ((DASHBOARD_PASSED++))
fi
((DASHBOARD_CHECKS++))

echo ""
echo "4. Alerting Configuration"
echo "========================"

ALERT_CHECKS=0
ALERT_PASSED=0

if test_alert_rules; then
    ((ALERT_PASSED++))
fi
((ALERT_CHECKS++))

echo ""
echo "5. Log Aggregation"
echo "=================="

LOG_CHECKS=0
LOG_PASSED=0

if check_log_ingestion; then
    ((LOG_PASSED++))
fi
((LOG_CHECKS++))

echo ""
echo "6. Distributed Tracing"
echo "====================="

TRACE_CHECKS=0
TRACE_PASSED=0

if check_tracing; then
    ((TRACE_PASSED++))
fi
((TRACE_CHECKS++))

echo ""
echo "=== VALIDATION SUMMARY ==="
echo "Service Health: $HEALTH_PASSED/$HEALTH_CHECKS"
echo "Metrics: $METRICS_PASSED/$METRICS_CHECKS"
echo "Dashboards: $DASHBOARD_PASSED/$DASHBOARD_CHECKS"
echo "Alerting: $ALERT_PASSED/$ALERT_CHECKS"
echo "Logging: $LOG_PASSED/$LOG_CHECKS"
echo "Tracing: $TRACE_PASSED/$TRACE_CHECKS"

TOTAL_CHECKS=$((HEALTH_CHECKS + METRICS_CHECKS + DASHBOARD_CHECKS + ALERT_CHECKS + LOG_CHECKS + TRACE_CHECKS))
TOTAL_PASSED=$((HEALTH_PASSED + METRICS_PASSED + DASHBOARD_PASSED + ALERT_PASSED + LOG_PASSED + TRACE_PASSED))

echo ""
echo "Overall: $TOTAL_PASSED/$TOTAL_CHECKS checks passed"

if [ $TOTAL_PASSED -eq $TOTAL_CHECKS ]; then
    echo -e "${GREEN}✓ ALL CHECKS PASSED - Monitoring stack is fully operational${NC}"
    exit 0
elif [ $TOTAL_PASSED -gt $((TOTAL_CHECKS * 3 / 4)) ]; then
    echo -e "${YELLOW}⚠ MOSTLY OPERATIONAL - Some components need attention${NC}"
    exit 1
else
    echo -e "${RED}✗ MULTIPLE FAILURES - Monitoring stack needs investigation${NC}"
    exit 2
fi
