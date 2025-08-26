# Harness Deployment Configuration for ICS Service

This directory contains comprehensive Harness deployment configurations for deploying the ICS Service docker-compose setup using Harness Custom Deployment Templates.

## 📁 Directory Structure

```
.harness/
├── pipelines/
│   └── ics-service-deployment.yaml     # Main deployment pipeline
├── templates/
│   └── docker-compose-deployment-template.yaml  # Custom deployment template
├── scripts/
│   ├── fetch-docker-compose-instances.sh        # Instance discovery script
│   ├── deploy-docker-compose.sh                 # Deployment operations
│   └── health-check.sh                          # Service health verification
├── input-sets/
│   ├── development.yaml                         # Development environment config
│   └── production.yaml                          # Production environment config
├── connectors/
│   └── target-infrastructure.yaml               # Infrastructure connectors
└── README-harness-deployment.md                 # This documentation
```

## 🚀 Quick Start

### Prerequisites

1. **Harness Account Setup**
   - Harness CD & GitOps module enabled
   - Project created with identifier: `ics_service_project`
   - Organization identifier: `default`

2. **Secrets Configuration**
   Create the following secrets in Harness Secret Manager:
   ```
   TCMIS_DB_SECRET              # Database password for tcm_ops user
   ORACLE_ROOT_PASSWORD         # Oracle root password
   ssh_private_key              # SSH private key for target hosts
   docker_registry_username     # Docker registry username
   docker_registry_password     # Docker registry password
   github_personal_access_token # GitHub PAT for source access
   ```

3. **Target Infrastructure**
   - Target host with Docker and Docker Compose installed
   - SSH access configured for deployment user
   - Ports 9090, 9091, 1521, 5500 available

### Deployment Process

1. **Import Harness Configurations**
   ```bash
   # Clone the repository
   git clone https://github.com/piyush76/docker-compose-ics.git
   cd docker-compose-ics
   
   # Import configurations to Harness (via UI or CLI)
   ```

2. **Configure Connectors**
   - Import connector configurations from `.harness/connectors/`
   - Update target host information and credentials
   - Test connectivity to all connectors

3. **Import Custom Deployment Template**
   - Import `.harness/templates/docker-compose-deployment-template.yaml`
   - Verify template validation passes

4. **Import Pipeline**
   - Import `.harness/pipelines/ics-service-deployment.yaml`
   - Configure input sets for your environments

5. **Execute Deployment**
   ```bash
   # Via Harness UI: Run pipeline with appropriate input set
   # Via CLI: harness pipeline execute --pipeline-id ics_service_deployment_pipeline
   ```

## 🏗️ Architecture Overview

### Deployment Strategy

The pipeline uses a **two-stage deployment approach**:

1. **Database Deployment Stage**
   - Deploys Oracle Express Edition database
   - Configures persistent volumes for data storage
   - Runs database initialization scripts
   - Performs health checks before proceeding

2. **Application Deployment Stage**
   - Deploys ICS Service application
   - Configures environment variables and secrets
   - Mounts application volumes (msds, receiptimages, docimages)
   - Performs comprehensive health verification

### Custom Deployment Template

Since Harness doesn't natively support docker-compose, we use **Custom Deployment Templates** with:

- **Fetch Instances Script**: Discovers running docker-compose services
- **Instance Attributes**: Maps service properties (name, ports, health status)
- **Deployment Steps**: Handles docker-compose operations and health checks

### Health Check Strategy

Comprehensive health verification includes:
- **Oracle Database**: SQL connectivity test
- **ICS Service Liveness**: `/actuator/health/liveness` endpoint
- **ICS Service Readiness**: `/actuator/health/readiness` endpoint
- **Application Health**: Main application endpoint verification

## 🔧 Configuration Details

### Pipeline Variables

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `target_host` | Target deployment host | `<+input>` |
| `deployment_path` | Deployment directory | `/opt/ics-service` |
| `ssh_user` | SSH user for deployment | `ubuntu` |
| `environment` | Deployment environment | `<+input>` |
| `image_tag` | ICS Service image tag | `d22e942` |

### Environment Variables

The pipeline automatically configures all required environment variables:

```yaml
# Database Configuration
TCMIS_DB_SECRET: <+secrets.getValue("TCMIS_DB_SECRET")>
ORACLE_ROOT_PASSWORD: <+secrets.getValue("ORACLE_ROOT_PASSWORD")>

# Spring Boot Configuration
SPRING_PROFILES_ACTIVE: docker
SPRING_DATASOURCE_URL: jdbc:oracle:thin:@oracle-db:1521:ORCL
SPRING_DATASOURCE_USERNAME: tcm_ops
SPRING_DATASOURCE_PASSWORD: <+secrets.getValue("TCMIS_DB_SECRET")>

# Server Configuration
SERVER_PORT: 9090
MANAGEMENT_SERVER_PORT: 9091
SERVER_SERVLET_CONTEXT_PATH: /chemicals/api
```

### Volume Management

Persistent volumes are automatically created and managed:
- `ics-service-msds`: Application MSDS files
- `ics-service-receiptimages`: Receipt images storage
- `ics-service-docimages`: Document images storage
- `oracle-data`: Oracle database files
- `oracle-backup`: Oracle backup location

## 🔍 Monitoring and Notifications

### Health Monitoring

The pipeline includes comprehensive health monitoring:
- Database connectivity verification
- Application liveness and readiness checks
- Endpoint availability testing
- Service status monitoring

### Notification Configuration

Slack notifications are configured for:
- **Deployment Success**: Notifies successful deployments
- **Deployment Failure**: Alerts on deployment failures
- **Health Check Failures**: Warns about service health issues

Configure webhook URLs in input sets:
```yaml
notificationRules:
  - name: Deployment Success Notification
    notificationMethod:
      type: Slack
      spec:
        webhookUrl: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

## 🛠️ Troubleshooting

### Common Issues

1. **Database Connection Failures**
   ```bash
   # Check Oracle database logs
   docker-compose logs oracle-db
   
   # Verify database connectivity
   docker-compose exec oracle-db sqlplus tcm_ops/password@XE
   ```

2. **Application Health Check Failures**
   ```bash
   # Check application logs
   docker-compose logs ics-service
   
   # Test health endpoints manually
   curl http://target-host:9091/actuator/health/liveness
   curl http://target-host:9091/actuator/health/readiness
   ```

3. **Volume Mount Issues**
   ```bash
   # Check volume status
   docker volume ls
   docker volume inspect ics-service-msds
   
   # Verify permissions
   ls -la /opt/ics-service/volumes/
   ```

### Pipeline Debugging

1. **Enable Debug Logging**
   - Add `set -x` to shell scripts for verbose output
   - Check Harness execution logs for detailed information

2. **Manual Verification**
   ```bash
   # Run health check script manually
   bash .harness/scripts/health-check.sh all
   
   # Test deployment script
   bash .harness/scripts/deploy-docker-compose.sh deploy
   ```

3. **Rollback Procedures**
   ```bash
   # Manual rollback
   bash .harness/scripts/deploy-docker-compose.sh rollback
   
   # Stop services
   bash .harness/scripts/deploy-docker-compose.sh stop
   ```

## 🔐 Security Considerations

### Secret Management
- All sensitive data stored in Harness Secret Manager
- No hardcoded credentials in pipeline configurations
- SSH key-based authentication for target hosts

### Container Security
- Maintains security settings from docker-compose:
  - `no-new-privileges: true`
  - Capability drops (`cap_drop: ALL`)
  - Non-root execution context

### Network Security
- Services communicate via Docker networks
- Exposed ports limited to required endpoints
- Health checks use internal service discovery

## 📚 Additional Resources

- [Harness Custom Deployment Templates Documentation](https://developer.harness.io/docs/continuous-delivery/deploy-srv-diff-platforms/custom/custom-deployment-tutorial)
- [Docker Compose Deployment Guide](./README-docker.md)
- [ICS Service Configuration Reference](../README-docker.md)

## 🤝 Support

For deployment issues or questions:
1. Check pipeline execution logs in Harness UI
2. Review health check script outputs
3. Verify connector configurations and connectivity
4. Consult troubleshooting section above

---

**Link to Devin run**: https://app.devin.ai/sessions/165aec6fb4454ef38d036f9844f915ba  
**Requested by**: Piyush Gupta (@piyush76)
