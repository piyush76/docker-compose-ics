# Production Environment

This directory contains the production environment configuration for the ICS Service.

## ⚠️ Production Deployment

**IMPORTANT**: This is a production configuration. Ensure all security measures are in place before deployment.

## Quick Start

```bash
# Navigate to production environment
cd environments/prod

# Copy and configure environment file
cp .env.example .env
# IMPORTANT: Edit .env with secure production values

# Start services
docker-compose up -d
# OR with podman
podman-compose up -d

# Verify deployment
docker-compose ps
curl https://your-domain.com:9091/actuator/health
```

## Production Features

### Configuration Differences from Development:
- **Image Tags**: Uses `stable` for production builds
- **Logging**: WARN level logging for performance
- **Container Names**: Suffixed with `-prod`
- **Networks**: Isolated production network (`ics-network-prod`)
- **Volumes**: Separate production volumes
- **Health Checks**: Optimized intervals for production
- **Security**: Hardened security settings
- **Resource Limits**: CPU and memory limits defined
- **Restart Policy**: `always` for high availability

### Production-Specific Settings:
- `SPRING_PROFILES_ACTIVE=prod`
- `LOGGING_LEVEL_ROOT=WARN`
- `LOGGING_LEVEL_COM_INCORA=INFO`
- Limited management endpoint exposure
- JVM tuning with G1GC
- Resource constraints and reservations

## Services

### ICS Service (Production)
- **Container**: `ics-service-prod`
- **Ports**: 9090 (app), 9091 (management)
- **Image**: `incora.azurecr.io/ics-service:stable`
- **Profile**: `prod`
- **Resources**: 2-4GB RAM, 1-2 CPU cores

### Oracle Database (Production)
- **Container**: `oracle-db-prod`
- **Ports**: 1521 (database), 5500 (EM)
- **Image**: `container-registry.oracle.com/database/express:21.3.0-xe`
- **Resources**: 1-2GB RAM, 0.5-1 CPU cores

## Production Deployment Checklist

### Pre-Deployment:
- [ ] Secure passwords configured in `.env`
- [ ] SSL/TLS certificates configured
- [ ] Firewall rules configured
- [ ] Backup strategy implemented
- [ ] Monitoring configured
- [ ] Log aggregation configured
- [ ] Resource limits appropriate for hardware

### Security Checklist:
- [ ] Strong database passwords
- [ ] Azure AD production credentials
- [ ] Container security options enabled
- [ ] Network isolation configured
- [ ] Management endpoints secured
- [ ] File permissions restricted

### Monitoring Checklist:
- [ ] Health check endpoints accessible
- [ ] Log monitoring configured
- [ ] Performance metrics collection
- [ ] Alert thresholds configured
- [ ] Backup verification automated

## Production Operations

### Starting Production Environment:
```bash
# Start all services
docker-compose up -d

# Verify services are running
docker-compose ps

# Check health
curl https://your-domain.com:9091/actuator/health
```

### Production Monitoring:
```bash
# Service status
docker-compose ps

# Resource usage
docker stats

# Health checks
curl https://your-domain.com:9091/actuator/health/liveness
curl https://your-domain.com:9091/actuator/health/readiness

# Application metrics
curl https://your-domain.com:9091/actuator/metrics
```

### Backup Operations:
```bash
# Database backup
docker-compose exec oracle-db-prod expdp system/password@XE directory=backup_dir dumpfile=backup_$(date +%Y%m%d).dmp

# Volume backup
docker run --rm -v oracle-data-prod:/data -v /backup:/backup alpine tar czf /backup/oracle-data-$(date +%Y%m%d).tar.gz -C /data .
```

### Rolling Updates:
```bash
# Pull new images
docker-compose pull

# Restart services with new images
docker-compose up -d

# Verify deployment
docker-compose ps
curl https://your-domain.com:9091/actuator/health
```

## Security Considerations

### Network Security:
- Use reverse proxy (nginx/traefik) for SSL termination
- Restrict database port access
- Configure firewall rules
- Use private networks where possible

### Container Security:
- Run containers as non-root user
- Drop unnecessary capabilities
- Use read-only root filesystem where possible
- Regular security updates

### Data Security:
- Encrypt data at rest
- Secure backup storage
- Regular security audits
- Access logging and monitoring

## Troubleshooting

### Performance Issues:
```bash
# Check resource usage
docker stats

# Application metrics
curl https://your-domain.com:9091/actuator/metrics/jvm.memory.used
curl https://your-domain.com:9091/actuator/metrics/system.cpu.usage
```

### Database Issues:
```bash
# Database logs
docker-compose logs oracle-db-prod

# Database connection test
docker-compose exec oracle-db-prod sqlplus tcm_ops/password@XE
```

### Application Issues:
```bash
# Application logs
docker-compose logs ics-service

# Health check details
curl https://your-domain.com:9091/actuator/health
```

## Environment Variables

See `.env.example` for all available configuration options.

Critical production variables:
- `TCMIS_DB_SECRET`: Secure database password
- `ORACLE_ROOT_PASSWORD`: Secure Oracle root password
- `AZURE_AD_CLIENT_SECRET`: Production Azure AD secret
- `JAVA_OPTS`: JVM tuning parameters
