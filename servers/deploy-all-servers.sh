#!/bin/bash

set -e

echo "=== Multi-Server ICS Observability Deployment Script ==="
echo "This script deploys the observability stack to both DKRC01 and DKRC02 servers"
echo

DKRC01_HOST="icsdev-dkrc-01.incora.global"
DKRC02_HOST="icsdev-dkrc-02.incora.global"
DEPLOY_USER="${DEPLOY_USER:-ubuntu}"
DEPLOY_PATH="${DEPLOY_PATH:-/opt/ics-service}"

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

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if [ ! -d "icsdev-dkrc-01" ]; then
        log_error "DKRC01 server directory not found"
        exit 1
    fi
    
    if [ ! -d "icsdev-dkrc-02" ]; then
        log_error "DKRC02 server directory not found"
        exit 1
    fi
    
    log_info "Testing SSH connectivity to servers..."
    
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "${DEPLOY_USER}@${DKRC01_HOST}" exit 2>/dev/null; then
        log_error "Cannot connect to ${DKRC01_HOST}"
        exit 1
    fi
    
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "${DEPLOY_USER}@${DKRC02_HOST}" exit 2>/dev/null; then
        log_error "Cannot connect to ${DKRC02_HOST}"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

deploy_to_server() {
    local server_host=$1
    local server_dir=$2
    local server_name=$3
    
    log_info "Deploying to ${server_name} (${server_host})..."
    
    ssh "${DEPLOY_USER}@${server_host}" "sudo mkdir -p ${DEPLOY_PATH} && sudo chown ${DEPLOY_USER}:${DEPLOY_USER} ${DEPLOY_PATH}"
    
    log_info "Copying configuration files to ${server_name}..."
    scp -r "${server_dir}/"* "${DEPLOY_USER}@${server_host}:${DEPLOY_PATH}/"
    
    log_info "Starting deployment on ${server_name}..."
    ssh "${DEPLOY_USER}@${server_host}" "
        cd ${DEPLOY_PATH}
        
        if [ ! -f .env ]; then
            echo 'Copying .env.example to .env - please update with actual credentials'
            cp .env.example .env
        fi
        
        chmod +x docker-login.sh
        
        if command -v docker >/dev/null 2>&1; then
            COMPOSE_CMD='docker-compose'
        elif command -v podman-compose >/dev/null 2>&1; then
            COMPOSE_CMD='podman-compose'
        else
            echo 'ERROR: Neither docker-compose nor podman-compose found'
            exit 1
        fi
        
        echo \"Using \$COMPOSE_CMD for deployment\"
        
        \$COMPOSE_CMD config --quiet
        
        echo 'Configuration validated successfully'
        echo 'Ready for deployment. Please:'
        echo '1. Update .env file with actual credentials'
        echo '2. Run: ./docker-login.sh'
        echo '3. Run: \$COMPOSE_CMD up -d'
    "
    
    if [ $? -eq 0 ]; then
        log_info "Deployment preparation completed for ${server_name}"
    else
        log_error "Deployment preparation failed for ${server_name}"
        return 1
    fi
}

verify_deployment() {
    local server_host=$1
    local server_name=$2
    local prometheus_port=$3
    local grafana_port=$4
    
    log_info "Verifying deployment on ${server_name}..."
    
    ssh "${DEPLOY_USER}@${server_host}" "
        cd ${DEPLOY_PATH}
        
        if command -v docker >/dev/null 2>&1; then
            COMPOSE_CMD='docker-compose'
        elif command -v podman-compose >/dev/null 2>&1; then
            COMPOSE_CMD='podman-compose'
        else
            echo 'ERROR: Neither docker-compose nor podman-compose found'
            exit 1
        fi
        
        echo 'Container status:'
        \$COMPOSE_CMD ps
        
        echo 'Checking service health...'
        sleep 10
        
        if curl -f -s http://localhost:9091/actuator/health/liveness >/dev/null; then
            echo 'ICS Service: HEALTHY'
        else
            echo 'ICS Service: UNHEALTHY'
        fi
        
        if curl -f -s http://localhost:${prometheus_port}/-/healthy >/dev/null; then
            echo 'Prometheus: HEALTHY'
        else
            echo 'Prometheus: UNHEALTHY'
        fi
    "
}

main() {
    echo "Starting multi-server deployment..."
    echo "DKRC01: ${DKRC01_HOST}"
    echo "DKRC02: ${DKRC02_HOST}"
    echo "Deploy User: ${DEPLOY_USER}"
    echo "Deploy Path: ${DEPLOY_PATH}"
    echo
    
    check_prerequisites
    
    deploy_to_server "${DKRC01_HOST}" "icsdev-dkrc-01" "DKRC01"
    
    deploy_to_server "${DKRC02_HOST}" "icsdev-dkrc-02" "DKRC02"
    
    log_info "Deployment preparation completed for both servers"
    echo
    echo "=== Next Steps ==="
    echo "1. SSH to each server and update the .env file with actual credentials:"
    echo "   ssh ${DEPLOY_USER}@${DKRC01_HOST}"
    echo "   ssh ${DEPLOY_USER}@${DKRC02_HOST}"
    echo
    echo "2. On each server, run the deployment:"
    echo "   cd ${DEPLOY_PATH}"
    echo "   ./docker-login.sh"
    echo "   docker-compose up -d  # or podman-compose up -d"
    echo
    echo "3. Access monitoring services:"
    echo "   DKRC01 Grafana: http://${DKRC01_HOST}:3000"
    echo "   DKRC02 Grafana: http://${DKRC02_HOST}:3001"
    echo
    echo "4. Verify deployment using the verification script:"
    echo "   ./verify-deployment.sh"
    echo
}

if [ ! -f "README-multi-server-deployment.md" ]; then
    log_error "Please run this script from the servers/ directory"
    exit 1
fi

main "$@"
