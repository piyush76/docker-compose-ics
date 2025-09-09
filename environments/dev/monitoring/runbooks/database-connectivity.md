# Database Connectivity Issues Runbook

## Alert: DatabaseConnectionFailure

### Description
This alert fires when database connection creation fails or connection pool issues are detected.

### Immediate Actions
1. **Check database connection pool status**:
   ```bash
   curl http://localhost:9091/actuator/metrics/hikaricp.connections.active
   curl http://localhost:9091/actuator/metrics/hikaricp.connections.pending
   ```

2. **Test database connectivity**:
   ```bash
   # From within the container
   docker exec ics-service-dev curl -f http://localhost:9091/actuator/health/db
   ```

3. **Check application logs for database errors**:
   ```bash
   docker logs ics-service-dev | grep -i "database\|connection\|oracle"
   ```

### Investigation Steps
1. **Verify database server status**:
   - Check if Oracle database at `infdev-ora01a.tcmis.com:1521/ICSDEV` is accessible
   - Verify network connectivity to database server

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

2. **If authentication issues**:
   - Verify database credentials in environment variables
   - Check if database user account is locked or expired

3. **If connection pool exhaustion**:
   - Increase connection pool size if needed
   - Identify and fix connection leaks in application code

### Escalation
- If database is completely unreachable for more than 5 minutes
- If connection pool exhaustion persists after configuration changes
- Contact: Database team and DevOps team via Slack #alerts-critical
