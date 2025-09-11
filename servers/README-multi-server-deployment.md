# Multi-Server Observability Deployment Guide

This guide covers deploying the comprehensive observability stack (Prometheus, Loki, Grafana, Alertmanager, Jaeger) as sidecar containers on both icsdev-dkrc-01.incora.global and icsdev-dkrc-02.incora.global servers.

## Overview

The multi-server deployment provides:
- **Independent monitoring stacks** for each server
- **Complete observability** with metrics, logs, traces, and alerts
- **Server-specific configurations** with proper isolation
- **Business metrics monitoring** for ICS service operations
- **Comprehensive alerting** for service health and business KPIs

## Server Configuration

### ICSDEV-DKRC-01 (Primary Server)
- **Hostname**: icsdev-dkrc-01.incora.global
- **Container Suffix**: `-dkrc01`
- **Network**: `ics-network-dkrc01`
- **Standard Ports**: Grafana 3000, Prometheus 9092, Alertmanager 9093, Jaeger 16686

### ICSDEV-DKRC-02 (Secondary Server)
- **Hostname**: icsdev-dkrc-02.incora.global
- **Container Suffix**: `-dkrc02`
- **Network**: `ics-network-dkrc02`
- **Offset Ports**: Grafana 3001, Prometheus 9094, Alertmanager 9095, Jaeger 16687

## Deployment Process

### Prerequisites

1. **Server Access**: Ensure you have access to both servers
2. **Docker/Podman**: Verify Docker or Podman is installed on both servers
3. **Network Access**: Confirm servers can access Azure Container Registry and external Oracle database
4. **Port Availability**: Verify required ports are available on both servers

### Step 1: Deploy to ICSDEV-DKRC-01

```bash
# Copy server configuration to DKRC01
scp -r servers/icsdev-dkrc-01/* user@icsdev-dkrc-01.incora.global:/opt/ics-service/

# SSH to DKRC01 server
ssh user@icsdev-dkrc-01.incora.global

# Navigate to deployment directory
cd /opt/ics-service

# Configure environment
cp .env.example .env
# Edit .env with actual credentials:
# - ACR_USERNAME=your-acr-username
# - ACR_PASSWORD=your-acr-password
# - TCMIS_DB_SECRET=actual-database-password

# Login to Azure Container Registry
./docker-login.sh

# Deploy observability stack
docker-compose up -d

# Verify deployment
docker-compose ps
docker-compose logs -f
```

### Step 2: Deploy to ICSDEV-DKRC-02

```bash
# Copy server configuration to DKRC02
scp -r servers/icsdev-dkrc-02/* user@icsdev-dkrc-02.incora.global:/opt/ics-service/

# SSH to DKRC02 server
ssh user@icsdev-dkrc-02.incora.global

# Navigate to deployment directory
cd /opt/ics-service

# Configure environment
cp .env.example .env
# Edit .env with actual credentials (same as DKRC01)

# Login to Azure Container Registry
./docker-login.sh

# Deploy observability stack
docker-compose up -d

# Verify deployment
docker-compose ps
docker-compose logs -f
```

## Verification and Testing

### Health Checks

#### DKRC01 Server
```bash
# ICS Service health
curl http://icsdev-dkrc-01.incora.global:9091/actuator/health/liveness
curl http://icsdev-dkrc-01.incora.global:9091/actuator/health/readiness

# Monitoring services
curl http://icsdev-dkrc-01.incora.global:9092/-/healthy  # Prometheus
curl http://icsdev-dkrc-01.incora.global:3100/ready     # Loki
curl http://icsdev-dkrc-01.incora.global:9093/-/healthy # Alertmanager
```

#### DKRC02 Server
```bash
# ICS Service health
curl http://icsdev-dkrc-02.incora.global:9091/actuator/health/liveness
curl http://icsdev-dkrc-02.incora.global:9091/actuator/health/readiness

# Monitoring services
curl http://icsdev-dkrc-02.incora.global:9094/-/healthy  # Prometheus
curl http://icsdev-dkrc-02.incora.global:3101/ready     # Loki
curl http://icsdev-dkrc-02.incora.global:9095/-/healthy # Alertmanager
```

### Monitoring Access

#### DKRC01 Monitoring URLs
- **Grafana**: http://icsdev-dkrc-01.incora.global:3000 (admin/admin123)
- **Prometheus**: http://icsdev-dkrc-01.incora.global:9092
- **Alertmanager**: http://icsdev-dkrc-01.incora.global:9093
- **Jaeger**: http://icsdev-dkrc-01.incora.global:16686

#### DKRC02 Monitoring URLs
- **Grafana**: http://icsdev-dkrc-02.incora.global:3001 (admin/admin123)
- **Prometheus**: http://icsdev-dkrc-02.incora.global:9094
- **Alertmanager**: http://icsdev-dkrc-02.incora.global:9095
- **Jaeger**: http://icsdev-dkrc-02.incora.global:16687

### Metrics Validation

#### Verify Prometheus Targets
1. Access Prometheus UI on each server
2. Navigate to Status → Targets
3. Confirm all targets are "UP":
   - ics-service (metrics endpoint)
   - ics-service-actuator
   - prometheus (self-monitoring)

#### Verify Grafana Dashboards
1. Access Grafana on each server
2. Check pre-configured dashboards:
   - ICS Service Health Dashboard
   - ICS Business KPIs Dashboard
3. Verify data is being collected and displayed

#### Verify Alerting
1. Access Alertmanager UI on each server
2. Check alert rules are loaded
3. Verify Slack/email notification configuration

## Monitoring Features

### Business Metrics
- **Receipt Processing**: Success/failure rates, processing times
- **User Authentication**: Login success rates, authentication failures
- **Safety Data Sheets**: Retrieval success rates, response times
- **Database Operations**: Connection health, query performance

### Infrastructure Metrics
- **Application Health**: JVM metrics, memory usage, CPU utilization
- **Container Health**: Container restarts, resource usage
- **Network Health**: Request rates, response times, error rates

### Alerting Rules
- **Critical Alerts**: Service down, high error rates, database failures
- **Warning Alerts**: High latency, memory pressure, authentication issues
- **Business Alerts**: Low processing success rates, API failures

### Distributed Tracing
- **OpenTelemetry Integration**: Automatic trace collection
- **Trace Correlation**: Link traces with logs and metrics
- **Performance Analysis**: Request flow analysis across services

## Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check port usage
netstat -tulpn | grep -E ':(3000|3001|9092|9093|9094|9095|16686|16687)'

# Stop conflicting services if needed
sudo systemctl stop <conflicting-service>
```

#### Container Issues
```bash
# Check container status
docker-compose ps

# View container logs
docker-compose logs <service-name>

# Restart specific service
docker-compose restart <service-name>
```

#### Database Connectivity
```bash
# Test database connection from container
docker-compose exec ics-service curl -f http://localhost:9091/actuator/health

# Check database-specific health
docker-compose exec ics-service curl -f http://localhost:9091/actuator/health/db
```

#### Monitoring Data Issues
```bash
# Check Prometheus targets
curl http://server:port/api/v1/targets

# Check Loki logs ingestion
curl http://server:3100/loki/api/v1/label

# Verify Grafana datasource connectivity
# Access Grafana → Configuration → Data Sources → Test
```

### Log Analysis
```bash
# Application logs
docker-compose logs -f ics-service

# Monitoring service logs
docker-compose logs -f prometheus
docker-compose logs -f loki
docker-compose logs -f grafana
```

## Maintenance

### Regular Tasks
1. **Monitor disk usage**: Prometheus and Loki data retention
2. **Update images**: Regular updates for security patches
3. **Backup configurations**: Grafana dashboards and Prometheus rules
4. **Review alerts**: Tune alert thresholds based on operational experience

### Scaling Considerations
- **Storage**: Monitor Prometheus and Loki storage usage
- **Performance**: Adjust scrape intervals based on load
- **Retention**: Configure appropriate data retention policies
- **Federation**: Consider Prometheus federation for cross-server monitoring

## Security

### Access Control
- **Grafana**: Change default admin password
- **Network**: Use firewall rules to restrict access
- **Secrets**: Store sensitive credentials securely
- **Updates**: Keep monitoring stack images updated

### Monitoring Security
- **TLS**: Configure HTTPS for production deployments
- **Authentication**: Integrate with corporate SSO if available
- **Audit**: Monitor access to monitoring interfaces
- **Backup**: Regular backup of monitoring configurations

## Support

For issues or questions:
1. Check server-specific README files
2. Review monitoring runbooks in `monitoring/runbooks/`
3. Use chaos testing scripts to validate monitoring
4. Check Grafana dashboards for system health

## Next Steps

After successful deployment:
1. **Customize Dashboards**: Adapt dashboards to specific business needs
2. **Tune Alerts**: Adjust alert thresholds based on operational patterns
3. **Integrate Notifications**: Configure Slack, email, or PagerDuty integration
4. **Monitor Performance**: Track monitoring stack performance and optimize
5. **Document Procedures**: Create operational runbooks for your environment
