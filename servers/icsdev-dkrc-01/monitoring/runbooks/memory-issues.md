# Memory Issues Runbook

## Alert: HighMemoryUsage

### Description
This alert fires when JVM heap memory usage exceeds 90% for more than 10 minutes.

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
   docker logs ics-service-dev | grep -i "outofmemory\|oom"
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
   - Restart the service if memory usage is critical
   - Reduce application load if possible

2. **Short-term fixes**:
   - Increase JVM heap size if resources allow
   - Tune garbage collection parameters
   - Implement request throttling if needed

3. **Long-term solutions**:
   - Optimize memory-intensive code paths
   - Implement proper resource cleanup
   - Consider application architecture improvements

### Prevention
- Regular memory usage monitoring
- Implement proper resource management patterns
- Regular performance testing with realistic loads

### Escalation
- If memory usage reaches 95% or OutOfMemoryError occurs
- If service becomes unresponsive due to memory issues
- Contact: Development team and DevOps team via Slack #alerts-critical
