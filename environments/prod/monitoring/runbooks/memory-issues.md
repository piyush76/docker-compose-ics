# Memory Issues Runbook - Production

## Alert: HighMemoryUsage

### Description
This alert fires when JVM heap memory usage exceeds 90% for more than 10 minutes in production.

### Immediate Actions
1. **Check current memory usage**:
   ```bash
   curl http://localhost:9091/actuator/metrics/jvm.memory.used
   curl http://localhost:9091/actuator/metrics/jvm.memory.max
   ```

2. **Review garbage collection activity**:
   ```bash
   curl http://localhost:9091/actuator/metrics/jvm.gc.pause
   ```

3. **Check for OutOfMemoryError in logs**:
   ```bash
   docker logs ics-service-prod | grep -i "outofmemory\|oom"
   ```

### Investigation Steps
1. **Analyze memory usage patterns**:
   - Check Grafana JVM memory dashboard
   - Review heap dump if available
   - Identify memory-intensive operations

2. **Check for memory leaks**:
   - Review application code for potential leaks
   - Check for unclosed resources (connections, streams, etc.)
   - Analyze object retention patterns

3. **Review application load**:
   - Check request volume and patterns
   - Identify any unusual traffic spikes
   - Review concurrent user activity

### Resolution Steps
1. **Immediate relief**:
   - Scale horizontally by adding more instances
   - Implement circuit breakers to reduce load
   - Consider temporary request throttling

2. **Short-term fixes**:
   - Increase JVM heap size if resources allow
   - Tune garbage collection parameters
   - Implement request rate limiting

3. **Long-term solutions**:
   - Optimize memory-intensive code paths
   - Implement proper resource cleanup
   - Consider application architecture improvements
   - Add memory profiling to CI/CD pipeline

### Escalation
- **CRITICAL**: If memory usage reaches 95% or OutOfMemoryError occurs
- **HIGH**: If service becomes unresponsive due to memory issues
- **Contacts**:
  - PagerDuty: Automatic escalation configured
  - Development team: For code-related memory issues
  - Infrastructure team: For scaling and resource allocation

### Prevention
- Regular memory usage monitoring and trending
- Implement proper resource management patterns
- Regular performance testing with realistic production loads
- Memory leak detection in development and staging
