# Service Down Runbook

## Alert: ServiceDown

### Description
This alert fires when the ICS service is completely unavailable and not responding to health checks.

### Immediate Actions
1. **Check service status**:
   ```bash
   docker ps | grep ics-service
   docker logs ics-service-dev --tail=50
   ```

2. **Verify container health**:
   ```bash
   docker inspect ics-service-dev | grep -A 10 "Health"
   ```

3. **Check system resources**:
   ```bash
   docker stats ics-service-dev --no-stream
   ```

### Investigation Steps
1. **Determine failure cause**:
   - Review container exit code and logs
   - Check for application startup errors
   - Verify configuration and environment variables

2. **Check dependencies**:
   - Verify database connectivity
   - Check Azure AD authentication service
   - Ensure required volumes are mounted

3. **Review system resources**:
   - Check available disk space
   - Verify memory and CPU availability
   - Check Docker daemon status

### Resolution Steps
1. **If container crashed**:
   ```bash
   docker restart ics-service-dev
   ```

2. **If startup issues**:
   - Review and fix configuration errors
   - Verify environment variables are set correctly
   - Check for missing dependencies

3. **If resource issues**:
   - Free up system resources
   - Restart Docker daemon if necessary
   - Check for resource limits

### Recovery Verification
1. **Verify service startup**:
   ```bash
   curl http://localhost:9091/actuator/health/liveness
   curl http://localhost:9091/actuator/health/readiness
   ```

2. **Check application functionality**:
   - Test key API endpoints
   - Verify database connectivity
   - Check authentication flow

3. **Monitor for stability**:
   - Watch logs for errors
   - Monitor resource usage
   - Verify alert resolution

### Escalation
- If service cannot be restarted within 10 minutes
- If repeated failures occur
- If underlying infrastructure issues are suspected
- Contact: DevOps team and Development team via Slack #alerts-critical
