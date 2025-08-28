# Development Environment

This directory contains the development environment configuration for the ICS Service with integrated monitoring stack.

## Quick Start

```bash
# Navigate to development environment
cd environments/dev

# Copy and configure environment file
cp .env.example .env
# Edit .env with your development values

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
# Grafana: http://localhost:3000 (admin/admin123)
# Prometheus: http://localhost:9092
# Loki: http://localhost:3100
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

### ICS Service (Development)
- **Container**: `ics-service-dev`
- **Ports**: 9090 (app), 9091 (management)
- **Image**: `incora.azurecr.io/ics-service:latest`
- **Profile**: `dev`

### External Oracle Database
- **Host**: `infdev-ora01a.tcmis.com`
- **Port**: 1521
- **Service**: `ICSDEV`
- **Connection**: External database managed separately

### Monitoring Stack
- **Prometheus**: Metrics collection and storage (port 9092)
- **Loki**: Log aggregation and storage (port 3100)
- **Promtail**: Log collection agent
- **Grafana**: Visualization and dashboards (port 3000)
  - Default credentials: admin/admin123
  - Pre-configured datasources: Prometheus and Loki

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
curl http://localhost:9090/chemicals/api/actuator/health
curl http://localhost:9091/actuator/health
```

### Development Testing:
```bash
# Health checks
curl http://localhost:9091/actuator/health/liveness
curl http://localhost:9091/actuator/health/readiness

# Application endpoints
curl http://localhost:9090/chemicals/api/actuator/info

# Monitoring endpoints
curl http://localhost:9091/actuator/prometheus  # Prometheus metrics
curl http://localhost:9092/api/v1/query?query=up  # Prometheus query
curl http://localhost:3100/ready  # Loki readiness

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
