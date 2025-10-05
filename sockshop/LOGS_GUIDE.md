# Logs Integration Guide for Sock Shop + SigNoz

## 📋 Current Setup

### What's Working
- ✅ **Distributed Traces**: Fully working via Zipkin → OTel Collector → SigNoz
- ✅ **Container Logs**: Available via Docker commands

### Logs Architecture

```
┌─────────────────────────────────────┐
│      Sock Shop Containers           │
│  stdout/stderr → Docker logging      │
└─────────────┬───────────────────────┘
              │
              │ Docker JSON logs
              │
              ▼
┌─────────────────────────────────────┐
│      Docker Desktop (macOS)          │
│  Stores logs per container          │
└─────────────┬───────────────────────┘
              │
              │ View via docker logs
              │
              ▼
        User Terminal
```

## 🔍 Viewing Logs

### Method 1: Docker Logs Command (Recommended)

**View live logs from a service:**
```bash
docker-compose logs -f carts
docker-compose logs -f orders  
docker-compose logs -f shipping
```

**View last N lines:**
```bash
docker-compose logs --tail=100 carts
```

**View logs from all services:**
```bash
docker-compose logs -f
```

**View logs with timestamps:**
```bash
docker-compose logs -t carts
```

**Search logs for errors:**
```bash
docker-compose logs carts | grep -i error
docker-compose logs carts | grep -i exception
docker-compose logs orders | grep -i "status 500"
```

### Method 2: Docker Desktop Dashboard

1. Open Docker Desktop
2. Click on "Containers" tab
3. Click on any Sock Shop container
4. View logs in the built-in log viewer
5. Search, filter, and export logs

### Method 3: Direct Docker Command

```bash
# List all containers
docker ps

# View logs by container ID or name
docker logs sockshop-carts-1
docker logs -f sockshop-orders-1
docker logs --tail=50 sockshop-shipping-1
```

## 📊 Common Log Patterns

### Java Service Logs (carts, orders, shipping)

**Application startup:**
```
App now running in production mode
Started Application in X.XXX seconds
```

**Zipkin trace sending:**
```
Sending span to Zipkin
Successfully sent trace
```

**Database connections:**
```
HikariPool starting
```

**Errors:**
```
ERROR - Exception
java.lang.NullPointerException
Connection refused
```

### Go Service Logs (catalogue, payment, user)

**Startup:**
```
Starting server on port 80
```

**HTTP requests:**
```
GET /catalogue 200
POST /payment 500
```

### Node.js Frontend Logs

**Startup:**
```
App now running in production mode on port 8079
```

**HTTP requests logged by Express**

## 🔧 Log Aggregation with SigNoz (Advanced)

For full log integration with SigNoz, you have a few options:

### Option 1: Fluent Bit → SigNoz (Recommended)

Add Fluent Bit as a log forwarder:

```yaml
# Add to docker-compose.yml
  fluent-bit:
    image: fluent/fluent-bit:latest
    volumes:
      - ./fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    depends_on:
      - otel-collector
```

Create `fluent-bit.conf`:
```ini
[SERVICE]
    Flush 1
    Log_Level info

[INPUT]
    Name tail
    Path /var/lib/docker/containers/*/*.log
    Parser docker
    Tag docker.*

[OUTPUT]
    Name http
    Match *
    Host host.docker.internal
    Port 4318
    URI /v1/logs
    Format json
```

### Option 2: Docker Logging Driver

Configure Docker to send logs to SigNoz:

```yaml
services:
  carts:
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: "carts"
```

### Option 3: Application-Level Logging

Modify application code to send logs via OTLP:

**Java (Spring Boot)**:
```xml
<dependency>
    <groupId>io.opentelemetry.instrumentation</groupId>
    <artifactId>opentelemetry-logback-appender-1.0</artifactId>
</dependency>
```

## 📈 Log Analysis Patterns

### Finding Errors Across All Services

```bash
# Search all services for errors
docker-compose logs | grep -i error

# Count errors per service
docker-compose logs carts | grep -c ERROR
docker-compose logs orders | grep -c ERROR
docker-compose logs shipping | grep -c ERROR
```

### Debugging Failed Requests

1. **Find the error in traces** (SigNoz UI)
2. **Note the timestamp**
3. **Check logs** at that time:
```bash
docker-compose logs --since="2025-10-04T19:30:00" carts | grep ERROR
```

### Monitoring Service Health

```bash
# Watch logs in real-time
watch -n 1 'docker-compose logs --tail=5 carts'

# Check for connection issues
docker-compose logs | grep -i "connection refused"
docker-compose logs | grep -i "timeout"
```

## 🎯 Best Practices

### Log Levels

**Use appropriate log levels in code**:
- `DEBUG`: Detailed debug information
- `INFO`: General informational messages
- `WARN`: Warning messages
- `ERROR`: Error events
- `FATAL`: Critical failures

### Structured Logging

**Good log format** (JSON):
```json
{
  "timestamp": "2025-10-04T19:30:00Z",
  "level": "ERROR",
  "service": "carts",
  "message": "Failed to add item to cart",
  "user_id": "123",
  "error": "Database connection timeout"
}
```

### Log Retention

**Docker logs rotation**:
```yaml
services:
  carts:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 🔗 Correlating Logs and Traces

### Manual Correlation

1. **In SigNoz**: Find trace with error
2. **Note timestamp** and `service.name`
3. **In terminal**:
```bash
docker-compose logs --since="TIMESTAMP" SERVICE_NAME
```

### Automatic Correlation (Future)

With proper instrumentation, logs can include `trace_id`:

```log
2025-10-04 19:30:00 ERROR [trace_id=abc123] Failed to process order
```

Then search in SigNoz logs by `trace_id`.

## 📊 Log Monitoring Dashboard

Create a simple monitoring script:

```bash
#!/bin/bash
# monitor-logs.sh

echo "=== Error Summary ==="
echo "Carts errors:" $(docker-compose logs carts | grep -c ERROR)
echo "Orders errors:" $(docker-compose logs orders | grep -c ERROR)  
echo "Shipping errors:" $(docker-compose logs shipping | grep -c ERROR)

echo ""
echo "=== Recent Errors ==="
docker-compose logs --tail=10 | grep ERROR
```

## 🆘 Troubleshooting

### No Logs Appearing

```bash
# Check if container is running
docker-compose ps

# Check if logs are being generated
docker-compose logs --tail=1 carts
```

### Logs Too Verbose

```bash
# Filter out noise
docker-compose logs carts | grep -v "DEBUG"
docker-compose logs carts | grep -E "ERROR|WARN"
```

### Can't Find Specific Log

```bash
# Search across all containers
docker-compose logs | grep "specific error message"

# Search with context (5 lines before/after)
docker-compose logs carts | grep -C 5 "error message"
```

## 💡 Quick Reference

### Essential Commands

```bash
# View live logs
docker-compose logs -f [service-name]

# View recent logs
docker-compose logs --tail=100 [service-name]

# Search for errors
docker-compose logs [service-name] | grep ERROR

# View logs since time
docker-compose logs --since="2025-10-04T19:00:00" [service-name]

# Save logs to file
docker-compose logs [service-name] > logs.txt

# Follow multiple services
docker-compose logs -f carts orders shipping
```

### Service Names

- `carts` - Shopping cart service
- `orders` - Order processing
- `shipping` - Shipping management
- `catalogue` - Product catalog
- `payment` - Payment processing
- `user` - User management
- `front-end` - Web UI
- `otel-collector` - Trace collector

## 🎓 Next Steps

1. **Start simple**: Use `docker-compose logs -f` while testing
2. **Search effectively**: Master `grep` for log analysis
3. **Correlate with traces**: Use timestamps to connect logs and traces
4. **Consider aggregation**: If logs become unwieldy, add Fluent Bit
5. **Monitor proactively**: Set up log monitoring scripts

---

**Remember**: Even without centralized logging, Docker logs + SigNoz traces give you powerful observability!

