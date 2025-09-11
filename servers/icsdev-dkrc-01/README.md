# ICSDEV-DKRC-01 Server Environment

This directory contains the server-specific configuration for the ICS Service with integrated monitoring stack on icsdev-dkrc-01.incora.global.

## Quick Start

```bash
# Navigate to DKRC01 server environment
cd servers/icsdev-dkrc-01

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
# Grafana: http://icsdev-dkrc-01.incora.global:3000 (admin/admin123)
# Prometheus: http://icsdev-dkrc-01.incora.global:9092
# Loki: http://icsdev-dkrc-01.incora.global:3100
```

## Development Features

### Configuration Differences from Production:
- **Image Tags**: Uses `latest` for development builds
- **Logging**: Debug level logging enabled
- **Container Names**: Suffixed with `-dev`
- **Networks**: Isolated development network (`ics-network-dev`)
- **Volumes**: Separate development volumes
- **Health Checks**: More frequent checks for faster feedback
- **Security**: Relaxed settings for development convenience

### Development-Specific Settings:
- `SPRING_PROFILES_ACTIVE=dev`
- `LOGGING_LEVEL_ROOT=DEBUG`
- `LOGGING_LEVEL_COM_INCORA=DEBUG`
- Default passwords for quick setup
- All management endpoints exposed

## Services

### ICS Service (DKRC01)
- **Container**: `ics-service-dkrc01`
- **Ports**: 9090 (app), 9091 (management)
- **Image**: `incora.azurecr.io/ics-service:latest`
- **Profile**: `dev`
- **Server**: `icsdev-dkrc-01.incora.global`

### External Oracle Database
- **Host**: `infdev-ora01a.tcmis.com`
- **Port**: 1521
- **Service**: `ICSDEV`
- **Connection**: External database managed separately

## Monitoring Services

The development environment includes a comprehensive observability stack:

- **Prometheus** (port 9092): Metrics collection and alerting
- **Alertmanager** (port 9093): Alert routing and notifications
- **Loki** (port 3100): Log aggregation
- **Promtail**: Log shipping to Loki
- **Grafana** (port 3000): Visualization and dashboards
- **Jaeger** (port 16686): Distributed tracing
  - Username: `admin`
  - Password: `admin123`

### Monitoring URLs

- Grafana: http://icsdev-dkrc-01.incora.global:3000
- Prometheus: http://icsdev-dkrc-01.incora.global:9092
- Alertmanager: http://icsdev-dkrc-01.incora.global:9093
- Loki: http://icsdev-dkrc-01.incora.global:3100
- Jaeger UI: http://icsdev-dkrc-01.incora.global:16686

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

## Development Workflow

### Starting Development Environment:
```bash
# Login to Azure Container Registry first
./docker-login.sh

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f ics-service

# Access application
curl http://icsdev-dkrc-01.incora.global:9090/chemicals/api/actuator/health
curl http://icsdev-dkrc-01.incora.global:9091/actuator/health
```

### Development Testing:
```bash
# Health checks
curl http://icsdev-dkrc-01.incora.global:9091/actuator/health/liveness
curl http://icsdev-dkrc-01.incora.global:9091/actuator/health/readiness

# Application endpoints
curl http://icsdev-dkrc-01.incora.global:9090/chemicals/api/actuator/info

# Monitoring endpoints
curl http://icsdev-dkrc-01.incora.global:9091/actuator/prometheus  # Prometheus metrics
curl http://icsdev-dkrc-01.incora.global:9092/api/v1/query?query=up  # Prometheus query
curl http://icsdev-dkrc-01.incora.global:3100/ready  # Loki readiness

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
1. **Port conflicts**: Ensure ports 9090, 9091 are available
2. **Database connectivity**: Verify network access to infdev-ora01a.tcmis.com:1521
3. **Database credentials**: Ensure TCMIS_DB_SECRET is correctly configured

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

Key development variables:
- `TCMIS_DB_SECRET`: Database password
- `ORACLE_ROOT_PASSWORD`: Oracle root password
- `LOG_LEVEL`: Logging level (DEBUG for development)
