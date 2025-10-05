# Complete Observability Guide - Sock Shop + SigNoz

This guide covers the complete observability setup for Sock Shop with distributed tracing and log aggregation in SigNoz.

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Sock Shop Services                        │
│  (carts, orders, shipping, catalogue, payment, user, etc)   │
└────────────┬────────────────────────────────────────────────┘
             │
             │ Spring Zipkin Traces (Java services)
             │ Docker JSON Logs (all containers)
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│            OpenTelemetry Collector                           │
│  • Receives Zipkin traces on port 9411                      │
│  • Collects Docker container logs                           │
│  • Processes and enriches data                              │
└────────────┬────────────────────────────────────────────────┘
             │
             │ OTLP (gRPC) - port 4317
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                     SigNoz                                   │
│  • UI on port 3301                                          │
│  • Stores traces in ClickHouse                              │
│  • Stores logs in ClickHouse                                │
│  • Correlates traces and logs                               │
└─────────────────────────────────────────────────────────────┘
```

## ✅ What's Integrated

### Traces
- ✅ **Java Services** (carts, orders, shipping)
  - Spring Boot Zipkin integration
  - Automatic span creation for HTTP requests
  - Database query spans
  - Inter-service call tracing

- ⚠️ **Go Services** (catalogue, payment, user)
  - Environment variables set
  - Requires code-level OTel SDK integration

- ⚠️ **Node.js Frontend** (front-end)
  - Environment variables set  
  - Requires code-level OTel SDK integration

### Logs
- ✅ **All Docker Containers**
  - Automatic collection via filelog receiver
  - Parses Docker JSON log format
  - Extracts container metadata
  - Correlates with traces by timestamp

## 🚀 Accessing Observability Data

### SigNoz UI
**URL**: http://localhost:3301

### Main Sections

#### 1. Services Tab
- View all microservices
- P50, P90, P99 latency metrics
- Error rates
- Requests per second
- Operations breakdown per service

**What to check**:
- Service health (green = healthy, red = errors)
- Latency trends over time
- Which services are slowest

#### 2. Traces Tab
- Distributed traces across services
- Trace waterfall visualization
- Filter by service, duration, status
- Search traces by trace ID

**What to check**:
- Complete request flow through services
- Where time is spent in each request
- Failed requests and error causes
- Slow queries and bottlenecks

**Useful Filters**:
```
service.name = carts
duration > 1000ms
status = error
```

#### 3. Logs Tab
- Aggregated logs from all containers
- Filter by service, severity, text
- View logs in context with traces
- Time-series log volume

**What to check**:
- Error logs from services
- Application behavior
- Debug information
- Correlation with traces

**Useful Filters**:
```
container_name contains "carts"
severity = ERROR
body contains "exception"
```

## 📊 Trace Examples

### Successful Shopping Cart Flow

```
span: GET /catalogue
  └─> span: MySQL query (catalogue-db)
      
span: POST /cart
  └─> span: MongoDB insert (carts-db)
      
span: POST /orders
  ├─> span: MongoDB insert (orders-db)
  ├─> span: RabbitMQ publish
  └─> span: POST /shipping
```

### Checkout Flow with Multiple Services

```
Frontend Request
  └─> Orders Service
      ├─> Shipping Service
      │   └─> RabbitMQ
      ├─> Payment Service
      └─> Orders Database
```

## 🔍 Using Traces

### Finding Slow Requests

1. Go to **Traces** tab
2. Add filter: `duration > 1000`
3. Sort by duration (descending)
4. Click on a trace to see waterfall

### Understanding Service Dependencies

1. Go to **Services** tab
2. Click on a service (e.g., "orders")
3. View "Database Calls" section
4. View "External Calls" section

### Debugging Errors

1. Go to **Traces** tab
2. Add filter: `status = error`
3. Click on failed trace
4. See error message and stack trace
5. View related logs at the same timestamp

## 📝 Using Logs

### Viewing Service Logs

1. Go to **Logs** tab
2. Filter by `container_name` or `service.name`
3. Select time range
4. View log stream

### Searching for Errors

```
severity IN (ERROR, FATAL)
```

### Finding Specific Events

```
body contains "OutOfMemoryError"
body contains "connection refused"
body contains "timeout"
```

### Correlating Logs with Traces

1. Find a trace in Traces tab
2. Note the timestamp
3. Go to Logs tab
4. Filter by same service and time range
5. See logs around that request

## 🎓 Common Investigation Patterns

### Pattern 1: Slow Checkout

**Symptom**: Users complain checkout is slow

**Investigation**:
1. Traces → filter `service.name = orders`
2. Sort by duration
3. Find slow traces
4. Look at waterfall - which span is slow?
5. If database: check query span details
6. If external service: check downstream span

**Logs to check**:
```
container_name = "sockshop-orders-1"
time_range = [when slow request occurred]
```

### Pattern 2: Cart Items Not Saving

**Symptom**: Items disappear from cart

**Investigation**:
1. Traces → filter `service.name = carts AND status = error`
2. Find failed POST /cart requests
3. Check error message in span
4. Go to Logs → filter `container_name contains "carts"`
5. Look for MongoDB connection errors

### Pattern 3: High Error Rate

**Symptom**: Dashboard shows 5% error rate

**Investigation**:
1. Services → click service with errors
2. View error rate graph
3. Traces → filter by that service + errors
4. Group errors by error message
5. Logs → search for stack traces

## 📈 Key Metrics to Monitor

### Service Health
- **Error Rate**: Should be < 1%
- **P95 Latency**: Should be < 1000ms
- **P99 Latency**: Should be < 2000ms
- **Throughput**: Requests per second

### Database Performance
- **Query Duration**: Check slow queries
- **Connection Pool**: Monitor connections
- **Lock Waits**: MongoDB/MySQL contention

### Infrastructure
- **Container Restarts**: Check for crashes
- **Memory Usage**: OOM errors
- **CPU Usage**: Performance degradation

## 🔧 Troubleshooting

### No Traces Appearing

**Check 1**: Is OTel Collector running?
```bash
docker ps | grep otel-collector
```

**Check 2**: Are services sending traces?
```bash
docker-compose logs carts | grep -i zipkin
```

**Check 3**: Is collector forwarding to SigNoz?
```bash
docker-compose logs otel-collector | grep -i "otlp"
```

**Check 4**: Is SigNoz receiving data?
```bash
docker logs signoz-otel-collector | grep -i traces
```

### No Logs Appearing

**Check 1**: Is filelog receiver working?
```bash
docker-compose logs otel-collector | grep -i "filelog"
```

**Check 2**: Are logs being read?
```bash
docker-compose logs otel-collector | grep -i "log"
```

**Check 3**: Check Docker log path exists?
```bash
ls -la /var/lib/docker/containers/
```

### Partial Traces

**Symptom**: Only seeing carts, orders, shipping - not catalogue, payment, user

**Reason**: Go services need manual OTel SDK integration

**Solution**: The pre-built images don't have OTel instrumentation. Java services work because Spring Boot has built-in Zipkin support.

For complete traces, you would need to:
1. Fork the service repos
2. Add OpenTelemetry SDK
3. Rebuild Docker images
4. Update docker-compose.yml

**Current Coverage**:
- ✅ Full traces: carts → orders → shipping → payment
- ⚠️ No auto-instrumentation: catalogue, user (would need code changes)

### High Cardinality Issues

**Symptom**: SigNoz UI slow, high memory usage

**Cause**: Too many unique attribute values

**Solution**: 
- Avoid trace IDs in labels
- Limit user IDs in attributes
- Use sampling for high-traffic services

## 🎯 Best Practices

### Trace Attributes
- Add business context (user_id, order_id)
- Keep attribute count reasonable (< 20 per span)
- Use consistent naming (snake_case)

### Log Levels
- **DEBUG**: Development only
- **INFO**: Important business events
- **WARN**: Recoverable errors
- **ERROR**: Failures needing attention
- **FATAL**: System crashes

### Sampling
For high-traffic services:
```yaml
# In otel-collector-config.yaml
processors:
  probabilistic_sampler:
    sampling_percentage: 10  # Sample 10% of traces
```

### Retention
- **Traces**: Keep 7-15 days
- **Logs**: Keep 30-90 days
- **Metrics**: Keep 6-12 months

## 📚 Advanced Topics

### Custom Span Attributes

If you modify the Java services, add custom attributes:
```java
Span.current().setAttribute("order.id", orderId);
Span.current().setAttribute("cart.items", itemCount);
```

### Log-Trace Correlation

SigNoz automatically correlates by:
- Timestamp matching
- Service name matching
- trace_id in logs (if instrumented)

### Alerting

In SigNoz, set up alerts for:
- Error rate > 5%
- P95 latency > 2000ms
- Service down (no traces for 5min)

## 🔗 Useful Links

- **SigNoz UI**: http://localhost:3301
- **SigNoz Docs**: https://signoz.io/docs/
- **OpenTelemetry Docs**: https://opentelemetry.io/docs/
- **Zipkin Format**: https://zipkin.io/pages/instrumenting.html

## 💡 Quick Tips

1. **Use filters aggressively** - SigNoz is fast with filters
2. **Bookmark common queries** - Save time on repeated searches
3. **Check logs AND traces** - Full picture needs both
4. **Monitor P95/P99** - Better than average latency
5. **Set up alerts early** - Don't wait for problems

## 🎓 Learning Path

1. **Day 1**: Explore Services tab, understand metrics
2. **Day 2**: View traces, understand waterfall
3. **Day 3**: Search logs, filter by service
4. **Day 4**: Correlate logs and traces
5. **Day 5**: Debug a real issue end-to-end

---

**Remember**: Good observability = traces + logs + metrics. Use all three together for the complete picture!

