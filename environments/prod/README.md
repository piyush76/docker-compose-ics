# Production Environment

This directory contains the production environment configuration for the ICS Service with integrated monitoring stack.

## ⚠️ Production Deployment

**IMPORTANT**: This is a production configuration. Ensure all security measures are in place before deployment.

## Quick Start

```bash
# Navigate to production environment
cd environments/prod

# Copy and configure environment file
cp .env.example .env
# IMPORTANT: Edit .env with secure production values

# Login to Azure Container Registry
./docker-login.sh

# Start services (including monitoring stack)
docker-compose up -d
# OR with podman
podman-compose up -d

# Verify deployment
docker-compose ps
curl https://your-domain.com:9091/actuator/health

# Access monitoring services
# Grafana: https://your-domain.com:3000 (admin/your-secure-password)
# Prometheus: https://your-domain.com:9092
# Loki: https://your-domain.com:3100
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

### External Oracle Database
- **Host**: `infdev-ora01a.tcmis.com`
- **Port**: 1521
- **Service**: `ICSDEV`
- **Connection**: External database managed separately

## Monitoring Services

The production environment includes a comprehensive observability stack with enhanced security:

- **Prometheus** (port 9092): Metrics collection and alerting
- **Alertmanager** (port 9093): Alert routing and notifications with PagerDuty integration
- **Loki** (port 3100): Log aggregation
- **Promtail**: Log shipping to Loki
- **Grafana** (port 3000): Visualization and dashboards
- **Jaeger** (port 16686): Distributed tracing
  - Username: `admin`
  - Password: Set via `GRAFANA_ADMIN_PASSWORD` environment variable

### Monitoring URLs

- Grafana: http://localhost:3000
- Prometheus: http://localhost:9092
- Alertmanager: http://localhost:9093
- Loki: http://localhost:3100
- Jaeger UI: http://localhost:16686

### Available Dashboards

- **ICS Service Health - Production**: API metrics, error rates, response times, infrastructure metrics
- **ICS Business KPIs - Production**: Receipt processing, user operations, safety data sheet retrievals

### Production Alerting

Enhanced alerting configuration for production:
- **Critical alerts**: PagerDuty, Slack, Email notifications
- **Warning alerts**: Slack and Email notifications
- **Alert grouping**: Intelligent grouping to reduce noise
- **Escalation**: Automatic escalation for unresolved critical alerts

### Alert Channels Configuration

Set the following environment variables for alert notifications:
```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
SMTP_HOST=smtp.yourcompany.com:587
SMTP_USERNAME=alerts@yourcompany.com
SMTP_PASSWORD=your-smtp-password
ALERT_EMAIL_TO=admin@yourcompany.com
PAGERDUTY_INTEGRATION_KEY=your-pagerduty-key
```

### Security Features

- Container security hardening (no-new-privileges, capability drops)
- Resource limits and reservations
- Secure credential management via environment variables
- Network isolation

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
# Login to Azure Container Registry first
./docker-login.sh

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
curl https://your-domain.com:9091/actuator/prometheus  # Prometheus format

# Monitoring stack health
curl https://your-domain.com:9092/-/healthy  # Prometheus
curl https://your-domain.com:3100/ready     # Loki
curl https://your-domain.com:3000/api/health # Grafana
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
