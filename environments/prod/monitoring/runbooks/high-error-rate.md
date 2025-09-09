# High Error Rate Runbook - Production

## Alert: HighErrorRate

### Description
This alert fires when the HTTP 5xx error rate exceeds 5% for more than 5 minutes in production.

### Immediate Actions
1. **Check service status**:
   ```bash
   curl http://localhost:9091/actuator/health
   ```

2. **Review recent logs**:
   ```bash
   docker logs ics-service-prod --tail=100
   ```

3. **Check Grafana dashboards**:
   - Navigate to http://localhost:3000
   - Open "ICS Service Health Dashboard - Production"
   - Review error rate and response time panels

### Investigation Steps
1. **Identify error patterns**:
   - Check which endpoints are failing
   - Look for common error messages in logs
   - Verify database connectivity

2. **Check external dependencies**:
   - Verify Oracle database connectivity: `jdbc:oracle:thin:@//infdev-ora01a.tcmis.com:1521/ICSDEV`
   - Check Azure AD authentication service status

3. **Review resource usage**:
   - Check CPU and memory usage in Grafana
   - Verify JVM heap usage and GC activity

### Resolution Steps
1. **If database issues**:
   - Check database connection pool metrics
   - Verify database server status
   - Review database query performance

2. **If authentication issues**:
   - Check Azure AD service status
   - Verify client credentials and configuration

3. **If resource exhaustion**:
   - Scale the service horizontally
   - Review memory leaks or inefficient queries

### Escalation
- **CRITICAL**: If error rate exceeds 10% for more than 5 minutes
- **IMMEDIATE**: If service becomes completely unavailable
- **Contacts**: 
  - PagerDuty: Automatic escalation configured
  - Slack: #alerts-critical-prod
  - Email: Production support team

### Post-Incident
- Document root cause analysis
- Update monitoring thresholds if needed
- Review and improve error handling
