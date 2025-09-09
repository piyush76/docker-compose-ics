# Database Connectivity Issues Runbook - Production

## Alert: DatabaseConnectionFailure

### Description
This alert fires when database connection creation fails or connection pool issues are detected in production.

### Immediate Actions
1. **Check database connection pool status**:
   ```bash
   curl http://localhost:9091/actuator/metrics/hikaricp.connections.active
   curl http://localhost:9091/actuator/metrics/hikaricp.connections.pending
   ```

2. **Test database connectivity**:
   ```bash
   # From within the container
   docker exec ics-service-prod curl -f http://localhost:9091/actuator/health/db
   ```

3. **Check application logs for database errors**:
   ```bash
   docker logs ics-service-prod | grep -i "database\|connection\|oracle"
   ```

### Investigation Steps
1. **Verify database server status**:
   - Check if Oracle database at `infdev-ora01a.tcmis.com:1521/ICSDEV` is accessible
   - Verify network connectivity to database server
   - Contact database team for server status

2. **Check connection pool configuration**:
   - Review HikariCP settings in application configuration
   - Check for connection leaks or long-running transactions

3. **Review database performance**:
   - Check for slow queries or locks
   - Verify database server resource usage

### Resolution Steps
1. **If network connectivity issues**:
   - Verify DNS resolution for database hostname
   - Check firewall rules and network policies
   - Contact network team if needed

2. **If authentication issues**:
   - Verify database credentials in environment variables
   - Check if database user account is locked or expired
   - Contact database team for credential verification

3. **If connection pool exhaustion**:
   - Temporarily increase connection pool size
   - Identify and fix connection leaks in application code
   - Consider horizontal scaling

### Escalation
- **CRITICAL**: If database is completely unreachable for more than 2 minutes
- **HIGH**: If connection pool exhaustion persists after configuration changes
- **Contacts**:
  - PagerDuty: Automatic escalation for critical alerts
  - Database team: Immediate contact for server issues
  - Slack: #alerts-critical-prod

### Prevention
- Regular connection pool monitoring
- Database health checks in CI/CD pipeline
- Automated failover procedures
