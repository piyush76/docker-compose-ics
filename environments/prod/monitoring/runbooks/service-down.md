# Service Down Runbook - Production

## Alert: ServiceDown

### Description
This alert fires when the ICS service is completely unavailable and not responding to health checks in production.

### Immediate Actions
1. **Check service status**:
   ```bash
   docker ps | grep ics-service
   docker logs ics-service-prod --tail=50
   ```

2. **Verify container health**:
   ```bash
   docker inspect ics-service-prod | grep -A 10 "Health"
   ```

3. **Check system resources**:
   ```bash
   docker stats ics-service-prod --no-stream
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
   docker restart ics-service-prod
   ```

2. **If startup issues**:
   - Review and fix configuration errors
   - Verify environment variables are set correctly
   - Check for missing dependencies

3. **If resource issues**:
   - Free up system resources
   - Scale to additional nodes if available
   - Check for resource limits and quotas

4. **If persistent failures**:
   - Rollback to previous working version
   - Activate disaster recovery procedures
   - Switch to backup infrastructure if available

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
- **IMMEDIATE**: Service cannot be restarted within 5 minutes
- **CRITICAL**: Repeated failures occur
- **HIGH**: If underlying infrastructure issues are suspected
- **Contacts**:
  - PagerDuty: Automatic escalation configured
  - Incident Commander: For major outages
  - Infrastructure team: For system-level issues
  - Development team: For application issues

### Post-Incident
- Conduct post-mortem analysis
- Update monitoring and alerting thresholds
- Implement additional safeguards
- Update disaster recovery procedures
