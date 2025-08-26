# Docker Compose Deployment for ICS Service

This directory contains Docker Compose configuration to deploy the ICS Service in a containerized environment, equivalent to the Kubernetes deployment.

## Prerequisites

- Docker and Docker Compose installed
- Access to the container registry `incora.azurecr.io` (or modify the image reference)
- Environment variables configured (see `.env.example`)

## Quick Start

1. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` file and set your database password:
   ```bash
   TCMIS_DB_SECRET=your_actual_database_password
   ```

3. Start the services:
   ```bash
   docker-compose up -d
   ```

4. Check service health:
   ```bash
   # Check if services are running
   docker-compose ps
   
   # Check application health
   curl http://localhost:9091/actuator/health
   ```

## Service Configuration

### ICS Service
- **Application Port**: 9090 (mapped to host)
- **Management Port**: 9091 (mapped to host)
- **Context Path**: `/chemicals/api`
- **Health Checks**: 
  - Liveness: `http://localhost:9091/actuator/health/liveness`
  - Readiness: `http://localhost:9091/actuator/health/readiness`

### Oracle Database
- **Port**: 1521 (mapped to host)
- **Enterprise Manager**: 5500 (mapped to host)
- **Database**: XE (Express Edition)
- **User**: tcm_ops (created automatically)

### Volumes
The following persistent volumes are created:
- `ics-service-msds`: Mounted at `/msds` in the container
- `ics-service-receiptimages`: Mounted at `/receiptimages` in the container  
- `ics-service-docimages`: Mounted at `/docimages` in the container
- `oracle-data`: Oracle database data files
- `oracle-backup`: Oracle backup location

## Environment Variables

The compose file translates the following Kubernetes configurations:

| Kubernetes Source | Docker Compose Variable | Description |
|------------------|------------------------|-------------|
| `tcmis-db-secret.TCMIS_DB_SECRET` | `TCMIS_DB_SECRET` | Database password |
| `ics-service-config` ConfigMap | Various `SPRING_*` variables | Application configuration |

## Security Features

The ICS service container includes security hardening:
- Runs with `no-new-privileges`
- Drops all Linux capabilities
- Non-root execution context

## Troubleshooting

### Database Connection Issues
```bash
# Check Oracle database logs
docker-compose logs oracle-db

# Test database connectivity
docker-compose exec oracle-db sqlplus tcm_ops/your_password@XE
```

### Application Issues
```bash
# Check application logs
docker-compose logs ics-service

# Check health endpoints
curl http://localhost:9091/actuator/health/liveness
curl http://localhost:9091/actuator/health/readiness
```

### Volume Issues
```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect ics-service-msds
```

## Stopping Services

```bash
# Stop services but keep volumes
docker-compose down

# Stop services and remove volumes (WARNING: data loss)
docker-compose down -v
```

## Equivalent Kubernetes Resources

This Docker Compose setup provides equivalent functionality to:
- Kubernetes Deployment: `ics-service`
- Kubernetes Service: Service discovery via Docker networks
- ConfigMap: `ics-service-config` → Environment variables
- Secret: `tcmis-db-secret` → `.env` file
- PersistentVolumeClaims: Named Docker volumes
- Health checks: Docker healthcheck configuration
