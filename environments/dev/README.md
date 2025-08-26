# Development Environment

This directory contains the development environment configuration for the ICS Service.

## Quick Start

```bash
# Navigate to development environment
cd environments/dev

# Copy and configure environment file
cp .env.example .env
# Edit .env with your development values

# Start services
docker-compose up -d
# OR with podman
podman-compose up -d

# Check status
docker-compose ps
# OR with podman
podman-compose ps
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

### Oracle Database (Development)
- **Container**: `oracle-db-dev`
- **Ports**: 1521 (database), 5500 (EM)
- **Image**: `container-registry.oracle.com/database/express:21.3.0-xe`
- **Default Password**: `DevOraclePassword123`

## Development Workflow

### Starting Development Environment:
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f ics-service
docker-compose logs -f oracle-db-dev

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

# Database connection test
docker-compose exec oracle-db-dev sqlplus tcm_ops/devpassword123@XE
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
1. **Port conflicts**: Ensure ports 9090, 9091, 1521, 5500 are available
2. **Database startup**: Oracle may take 2-3 minutes to fully initialize
3. **Memory**: Ensure sufficient memory for Oracle (minimum 2GB recommended)

### Logs:
```bash
# Application logs
docker-compose logs ics-service

# Database logs
docker-compose logs oracle-db-dev

# All logs
docker-compose logs
```

## Environment Variables

See `.env.example` for all available configuration options.

Key development variables:
- `TCMIS_DB_SECRET`: Database password
- `ORACLE_ROOT_PASSWORD`: Oracle root password
- `LOG_LEVEL`: Logging level (DEBUG for development)
