# Unified Docker Compose Deployment

This unified configuration eliminates duplicate docker-compose files by using a single configurable `docker-compose.unified.yml` with environment variables and configurable monitoring configurations.

## Overview

The unified solution provides:
- Single `docker-compose.unified.yml` for all server deployments
- Environment-specific `.env` files for server configuration
- Configurable monitoring configurations using environment variable substitution
- Automated deployment script with configuration processing

## Quick Start

### Deploy to DKRC01 (icsdev-dkrc-01.incora.global)
```bash
./deploy.sh dkrc01
```

### Deploy to DKRC02 (icsdev-dkrc-02.incora.global)
```bash
./deploy.sh dkrc02
```

## Configuration Files

### Environment Files
- `.env.dkrc01` - Configuration for icsdev-dkrc-01.incora.global
- `.env.dkrc02` - Configuration for icsdev-dkrc-02.incora.global

### Monitoring Configuration Templates
- `config/prometheus.yml` - Prometheus configuration template
- `config/alertmanager.yml` - Alertmanager configuration template
- `config/loki-config.yml` - Loki configuration
- `config/promtail-config.yml` - Promtail configuration
- `config/alert-rules.yml` - Prometheus alert rules
- `config/grafana/` - Grafana provisioning configurations

## Environment Variables

### Server Identification
- `SERVER_ID` - Unique server identifier (dkrc01, dkrc02)
- `SERVER_HOSTNAME` - Full server hostname
- `ENVIRONMENT` - Environment name (dev, prod)

### Port Configuration
- `ICS_APP_PORT` - ICS service application port (default: 9090)
- `ICS_MGMT_PORT` - ICS service management port (default: 9091)
- `PROMETHEUS_PORT` - Prometheus web UI port
- `GRAFANA_PORT` - Grafana web UI port
- `ALERTMANAGER_PORT` - Alertmanager web UI port
- `LOKI_PORT` - Loki API port
- `JAEGER_UI_PORT` - Jaeger UI port
- `JAEGER_HTTP_PORT` - Jaeger HTTP collector port
- `JAEGER_GRPC_PORT` - Jaeger gRPC collector port
- `JAEGER_UDP_PORT` - Jaeger UDP agent port

### Database Configuration
- `TCMIS_DB_USERNAME` - Database username
- `TCMIS_DB_SECRET` - Database password

### Azure Container Registry
- `ACR_USERNAME` - Azure Container Registry username
- `ACR_PASSWORD` - Azure Container Registry password

### Monitoring
- `GRAFANA_ADMIN_PASSWORD` - Grafana admin password
- `LOG_LEVEL` - Application log level
- `SLACK_WEBHOOK_URL` - Slack webhook for alerts
- `SLACK_CHANNEL` - Slack channel for alerts

## Port Assignments

### DKRC01 (Standard Ports)
- Grafana: 3000
- Prometheus: 9092
- Alertmanager: 9093
- Loki: 3100
- Jaeger UI: 16686

### DKRC02 (Offset Ports)
- Grafana: 3001
- Prometheus: 9094
- Alertmanager: 9095
- Loki: 3101
- Jaeger UI: 16687

## Deployment Process

The `deploy.sh` script performs the following steps:

1. **Load Environment Variables** - Sources the appropriate `.env` file
2. **Process Configuration Templates** - Uses `envsubst` to replace placeholders in monitoring configs
3. **Azure Container Registry Login** - Authenticates with ACR using provided credentials
4. **Deploy Services** - Runs `docker-compose up -d` with processed configurations

## Manual Deployment

If you prefer manual deployment:

```bash
# Load environment variables
source .env.dkrc01  # or .env.dkrc02

# Login to Azure Container Registry
./docker-login.sh

# Process monitoring configurations
mkdir -p config_processed
envsubst < config/prometheus.yml | sed "s/SERVER_ID_PLACEHOLDER/${SERVER_ID}/g" > config_processed/prometheus.yml
envsubst < config/alertmanager.yml | sed "s/SERVER_ID_PLACEHOLDER/${SERVER_ID}/g" > config_processed/alertmanager.yml
cp config/loki-config.yml config_processed/
cp config/promtail-config.yml config_processed/
cp config/alert-rules.yml config_processed/
cp -r config/grafana config_processed/

# Update docker-compose to use processed configs
sed "s|./config/|./config_processed/|g" docker-compose.unified.yml > config_processed/docker-compose.yml

# Deploy
docker-compose -f config_processed/docker-compose.yml up -d
```

## Monitoring and Management

### Check Deployment Status
```bash
docker-compose -f config_processed/docker-compose.yml ps
```

### View Logs
```bash
# All services
docker-compose -f config_processed/docker-compose.yml logs -f

# Specific service
docker-compose -f config_processed/docker-compose.yml logs -f ics-service-dkrc01
```

### Stop Services
```bash
docker-compose -f config_processed/docker-compose.yml down
```

## Access URLs

After deployment, access monitoring services at:

### DKRC01
- **Grafana**: http://icsdev-dkrc-01.incora.global:3000 (admin/admin123)
- **Prometheus**: http://icsdev-dkrc-01.incora.global:9092
- **Alertmanager**: http://icsdev-dkrc-01.incora.global:9093
- **Jaeger**: http://icsdev-dkrc-01.incora.global:16686

### DKRC02
- **Grafana**: http://icsdev-dkrc-02.incora.global:3001 (admin/admin123)
- **Prometheus**: http://icsdev-dkrc-02.incora.global:9094
- **Alertmanager**: http://icsdev-dkrc-02.incora.global:9095
- **Jaeger**: http://icsdev-dkrc-02.incora.global:16687

## Adding New Servers

To add a new server:

1. Create a new `.env.<server_name>` file with appropriate configuration
2. Ensure unique port assignments to avoid conflicts
3. Deploy using: `./deploy.sh <server_name>`

Example for a new production server:
```bash
# Create .env.prod01
cp .env.dkrc01 .env.prod01
# Edit .env.prod01 with production-specific values

# Deploy
./deploy.sh prod01
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**
   ```bash
   # Check port usage
   netstat -tulpn | grep :3000
   
   # Update .env file with different ports if needed
   ```

2. **Container Issues**
   ```bash
   # Check container status
   docker-compose -f config_processed/docker-compose.yml ps
   
   # View logs
   docker-compose -f config_processed/docker-compose.yml logs <service-name>
   ```

3. **Database Connectivity**
   ```bash
   # Test database connection
   docker-compose -f config_processed/docker-compose.yml exec ics-service-dkrc01 curl -f http://localhost:9091/actuator/health
   ```

4. **ACR Authentication Issues**
   ```bash
   # Verify ACR credentials
   echo "$ACR_PASSWORD" | docker login incora.azurecr.io --username "$ACR_USERNAME" --password-stdin
   ```

### Configuration Validation

Validate docker-compose configuration:
```bash
docker-compose -f docker-compose.unified.yml --env-file .env.dkrc01 config --quiet
```

## Benefits of Unified Configuration

1. **Eliminates Duplication** - Single source of truth for all server deployments
2. **Easy Maintenance** - Updates only need to be made in one place
3. **Consistent Deployments** - Same configuration logic across all servers
4. **Flexible Configuration** - Easy to add new servers or modify existing ones
5. **Environment Isolation** - Clear separation of server-specific settings
