# ICSDEV-DKRC-02 Server Environment

This directory contains the server-specific configuration for the ICS Service with integrated monitoring stack on icsdev-dkrc-02.incora.global.

## Quick Start

```bash
# Navigate to DKRC02 server environment
cd servers/icsdev-dkrc-02

# Copy and configure environment file
cp .env.example .env
# Edit .env with your server values

# Login to Azure Container Registry
./docker-login.sh

# Start services (including monitoring stack)
docker-compose up -d
# OR with podman
podman-compose up -d

# Check status
docker-compose ps
# OR with podman
podman-compose ps

# Access monitoring services
# Grafana: http://icsdev-dkrc-02.incora.global:3001 (admin/admin123)
# Prometheus: http://icsdev-dkrc-02.incora.global:9094
# Loki: http://icsdev-dkrc-02.incora.global:3101
```

## Development Features

### Configuration Differences from DKRC01:
- **Container Names**: Suffixed with `-dkrc02`
- **Networks**: Isolated server network (`ics-network-dkrc02`)
- **Volumes**: Separate server volumes with `-dkrc02` suffix
- **Ports**: Different external ports to avoid conflicts with DKRC01
- **External URLs**: Use `icsdev-dkrc-02.incora.global` hostname

### Port Assignments (Different from DKRC01):
- **Prometheus**: 9094 (vs 9092 on DKRC01)
- **Grafana**: 3001 (vs 3000 on DKRC01)
- **Alertmanager**: 9095 (vs 9093 on DKRC01)
- **Loki**: 3101 (vs 3100 on DKRC01)
- **Jaeger**: 16687 (vs 16686 on DKRC01)

## Services

### ICS Service (DKRC02)
- **Container**: `ics-service-dkrc02`
- **Ports**: 9090 (app), 9091 (management)
- **Image**: `incora.azurecr.io/ics-service:latest`
- **Profile**: `dev`
- **Server**: `icsdev-dkrc-02.incora.global`

### External Oracle Database
- **Host**: `infdev-ora01a.tcmis.com`
- **Port**: 1521
- **Service**: `ICSDEV`
- **Connection**: External database managed separately

## Monitoring Services

The DKRC02 environment includes a comprehensive observability stack:

- **Prometheus** (port 9094): Metrics collection and alerting
- **Alertmanager** (port 9095): Alert routing and notifications
- **Loki** (port 3101): Log aggregation
- **Promtail**: Log shipping to Loki
- **Grafana** (port 3001): Visualization and dashboards
- **Jaeger** (port 16687): Distributed tracing
  - Username: `admin`
  - Password: `admin123`

### Monitoring URLs

- Grafana: http://icsdev-dkrc-02.incora.global:3001
- Prometheus: http://icsdev-dkrc-02.incora.global:9094
- Alertmanager: http://icsdev-dkrc-02.incora.global:9095
- Loki: http://icsdev-dkrc-02.incora.global:3101
- Jaeger UI: http://icsdev-dkrc-02.incora.global:16687

### Available Dashboards

- **ICS Service Health**: API metrics, error rates, response times, infrastructure metrics
- **ICS Business KPIs**: Receipt processing, user operations, safety data sheet retrievals

### Alerting

The monitoring stack includes comprehensive alerting rules:
- High error rates (>5% for 5 minutes)
- Service downtime
- High response times (p99 > 2s for 10 minutes)
- Database connection failures
- High memory usage (>90% for 10 minutes)
- Business-specific alerts for receipt processing and authentication

### Chaos Testing

Use the provided chaos testing scripts to validate monitoring:
```bash
cd monitoring/chaos-tests/
./validate-monitoring.sh          # Full monitoring stack validation
./simulate-high-load.sh 5 10      # Simulate high load for 5 minutes
./simulate-database-failure.sh 3  # Simulate DB issues for 3 minutes
./simulate-memory-pressure.sh 5   # Simulate memory pressure for 5 minutes
```

## Server Workflow

### Starting DKRC02 Environment:
```bash
# Login to Azure Container Registry first
./docker-login.sh

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f ics-service

# Access application
curl http://icsdev-dkrc-02.incora.global:9090/chemicals/api/actuator/health
curl http://icsdev-dkrc-02.incora.global:9091/actuator/health
```

### Server Testing:
```bash
# Health checks
curl http://icsdev-dkrc-02.incora.global:9091/actuator/health/liveness
curl http://icsdev-dkrc-02.incora.global:9091/actuator/health/readiness

# Application endpoints
curl http://icsdev-dkrc-02.incora.global:9090/chemicals/api/actuator/info

# Monitoring endpoints
curl http://icsdev-dkrc-02.incora.global:9091/actuator/prometheus  # Prometheus metrics
curl http://icsdev-dkrc-02.incora.global:9094/api/v1/query?query=up  # Prometheus query
curl http://icsdev-dkrc-02.incora.global:3101/ready  # Loki readiness

# External database connection test (if you have access)
# sqlplus tcm_ops/devpassword123@//infdev-ora01a.tcmis.com:1521/ICSDEV
```

### Cleanup:
```bash
# Stop services
docker-compose down

# Remove volumes (WARNING: This will delete all data)
docker-compose down -v
```

## Troubleshooting

### Common Issues:
1. **Port conflicts**: Ensure ports 9090, 9091, 9094, 3001, 9095, 3101, 16687 are available
2. **Database connectivity**: Verify network access to infdev-ora01a.tcmis.com:1521
3. **Database credentials**: Ensure TCMIS_DB_SECRET is correctly configured
4. **Container naming**: Verify no conflicts with DKRC01 containers

### Logs:
```bash
# Application logs
docker-compose logs ics-service

# Database connectivity (check application logs for database errors)

# All logs
docker-compose logs
```

## Environment Variables

See `.env.example` for all available configuration options.

Key server variables:
- `TCMIS_DB_SECRET`: Database password
- `GRAFANA_ADMIN_PASSWORD`: Grafana admin password
- `JAEGER_AGENT_HOST`: jaeger-dkrc02
- `JAEGER_AGENT_PORT`: 6832

## Multi-Server Deployment

This server configuration is designed to work independently from DKRC01:
- **Independent monitoring stacks**: Each server has its own complete observability stack
- **No port conflicts**: DKRC02 uses different external ports
- **Isolated networks**: Separate Docker networks for each server
- **Server identification**: All alerts and logs include server identification

For cross-server monitoring federation, see the main repository documentation.
