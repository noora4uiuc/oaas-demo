# Integration Overview

This document explains how SockShop and SigNoz are integrated in this deployment.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Docker Network: oaas-net                      │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                     SockShop Application                      │  │
│  │                                                               │  │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │  │
│  │  │  Front-End  │───▶│ Edge Router │───▶│  Catalogue  │     │  │
│  │  │  (Node.js)  │    │   (nginx)   │    │    (Go)     │     │  │
│  │  └─────────────┘    └─────────────┘    └─────┬───────┘     │  │
│  │                                               │              │  │
│  │                                          ┌────▼────────┐     │  │
│  │                                          │ Catalogue   │     │  │
│  │                                          │    DB       │     │  │
│  │                                          │  (MySQL)    │     │  │
│  │                                          └─────────────┘     │  │
│  │                                                               │  │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │  │
│  │  │    User     │    │   Payment   │    │    Carts    │────┐│  │
│  │  │    (Go)     │    │    (Go)     │    │   (Java)    │    ││  │
│  │  └──────┬──────┘    └─────────────┘    └──────┬──────┘    ││  │
│  │         │                                      │           ││  │
│  │    ┌────▼─────┐                           ┌───▼──────┐    ││  │
│  │    │ User DB  │                           │ Carts DB │    ││  │
│  │    │ (Mongo)  │                           │ (Mongo)  │    ││  │
│  │    └──────────┘                           └──────────┘    ││  │
│  │                                                            ││  │
│  │  ┌─────────────┐    ┌─────────────┐                      ││  │
│  │  │   Orders    │───▶│  Shipping   │                      ││  │
│  │  │   (Java)    │    │   (Java)    │                      ││  │
│  │  └──────┬──────┘    └──────┬──────┘                      ││  │
│  │         │                   │                             ││  │
│  │    ┌────▼─────┐        ┌───▼──────┐                      ││  │
│  │    │Orders DB │        │ RabbitMQ │                      ││  │
│  │    │ (Mongo)  │        └──────────┘                      ││  │
│  │    └──────────┘                                           ││  │
│  │                                                            ││  │
│  └────────────────────────────────────────────────────────────┘│  │
│                                                                 │  │
│         │ Zipkin Protocol (Spring Boot)                        │  │
│         │ Port 9411                                            │  │
│         └──────────────────┬──────────────────────────────────┘  │
│                            │                                      │
│         ┌──────────────────▼───────────────────────────────┐     │
│         │          Fluentd Log Collector                   │     │
│         │              Port 24224                          │     │
│         └──────────────────┬───────────────────────────────┘     │
│                            │                                      │
│         ┌──────────────────▼───────────────────────────────┐     │
│         │       SigNoz OpenTelemetry Collector             │     │
│         │  ┌────────────────────────────────────────┐      │     │
│         │  │ Receivers:                             │      │     │
│         │  │  • OTLP gRPC (4317)                   │      │     │
│         │  │  • OTLP HTTP (4318)                   │      │     │
│         │  │  • Zipkin (9411) ← Java Services      │      │     │
│         │  │  • Fluentd Forward (24225) ← Logs     │      │     │
│         │  └────────────────────────────────────────┘      │     │
│         │  ┌────────────────────────────────────────┐      │     │
│         │  │ Processors:                            │      │     │
│         │  │  • Batch                               │      │     │
│         │  │  • Resource Detection                  │      │     │
│         │  │  • Span Metrics                        │      │     │
│         │  │  • Attributes                          │      │     │
│         │  └────────────────────────────────────────┘      │     │
│         │  ┌────────────────────────────────────────┐      │     │
│         │  │ Exporters:                             │      │     │
│         │  │  • ClickHouse Traces                   │      │     │
│         │  │  • ClickHouse Metrics                  │      │     │
│         │  │  • ClickHouse Logs                     │      │     │
│         │  └────────────────────────────────────────┘      │     │
│         └──────────────────┬───────────────────────────────┘     │
│                            │                                      │
│         ┌──────────────────▼───────────────────────────────┐     │
│         │              ClickHouse Database                 │     │
│         │  ┌──────────────────────────────────────┐        │     │
│         │  │ • signoz_traces (Distributed Traces) │        │     │
│         │  │ • signoz_metrics (Metrics & APM)     │        │     │
│         │  │ • signoz_logs (Application Logs)     │        │     │
│         │  └──────────────────────────────────────┘        │     │
│         └──────────────────┬───────────────────────────────┘     │
│                            │                                      │
│         ┌──────────────────▼───────────────────────────────┐     │
│         │              SigNoz Application                  │     │
│         │         Query Service + UI (Port 3301)          │     │
│         │  ┌──────────────────────────────────────┐        │     │
│         │  │ Features:                            │        │     │
│         │  │  • Service Map                       │        │     │
│         │  │  • Trace Visualization               │        │     │
│         │  │  • APM Metrics                       │        │     │
│         │  │  • Log Analysis                      │        │     │
│         │  │  • Alerting                          │        │     │
│         │  └──────────────────────────────────────┘        │     │
│         └──────────────────────────────────────────────────┘     │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   Supporting Services                     │   │
│  │  • ZooKeeper (coordination for ClickHouse)               │   │
│  │  • Schema Migrators (database initialization)            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow

### Trace Data Flow

1. **Generation**: Java services (carts, orders, shipping) automatically generate Zipkin-format traces using Spring Boot Sleuth
2. **Collection**: Traces sent to SigNoz OTel Collector on port 9411
3. **Processing**: 
   - Batch processor aggregates spans
   - Resource detector adds system metadata
   - Span metrics processor generates APM metrics
4. **Storage**: Traces stored in ClickHouse `signoz_traces` database
5. **Visualization**: SigNoz UI queries ClickHouse and displays traces

### Log Data Flow

1. **Generation**: Docker logs from `carts` service
2. **Collection**: Fluentd collects logs on port 24224
3. **Forwarding**: Fluentd forwards to OTel Collector on port 24225
4. **Processing**:
   - Batch processor aggregates logs
   - Attributes processor adds metadata
5. **Storage**: Logs stored in ClickHouse `signoz_logs` database
6. **Visualization**: SigNoz UI provides log search and analysis

### Metrics Data Flow

1. **Generation**: 
   - Span metrics derived from traces
   - OTel Collector self-monitoring metrics
2. **Processing**: Batch processor aggregates metrics
3. **Storage**: Metrics stored in ClickHouse `signoz_metrics` database
4. **Visualization**: SigNoz UI displays RED metrics (Rate, Errors, Duration)

## 🔌 Integration Points

### SockShop → SigNoz Integration

#### Java Services (Automatic)
Services with built-in instrumentation:
- **carts**: `JAVA_OPTS=-Dspring.zipkin.baseUrl=http://signoz-otel-collector:9411`
- **orders**: `JAVA_OPTS=-Dspring.zipkin.baseUrl=http://signoz-otel-collector:9411`
- **shipping**: `JAVA_OPTS=-Dspring.zipkin.baseUrl=http://signoz-otel-collector:9411`

These services use Spring Cloud Sleuth which automatically:
- Creates spans for HTTP requests
- Propagates trace context
- Sends traces to Zipkin endpoint
- Includes service name, operation name, timing, tags

#### Log Integration
- **carts** service uses Fluentd logging driver
- Logs forwarded to Fluentd on port 24224
- Fluentd forwards to OTel Collector
- Logs correlated with traces via trace ID

### Network Configuration

All services run on a shared Docker network: `oaas-net`

This allows:
- Service-to-service communication by container name
- SockShop services to reach OTel Collector
- OTel Collector to reach ClickHouse
- SigNoz to query ClickHouse

## 📊 What Gets Monitored

### Services Fully Instrumented
| Service | Type | Instrumentation | Status |
|---------|------|-----------------|--------|
| carts | Java | Spring Boot Zipkin | ✅ Active |
| orders | Java | Spring Boot Zipkin | ✅ Active |
| shipping | Java | Spring Boot Zipkin | ✅ Active |

### Services Partially Instrumented
| Service | Type | Notes |
|---------|------|-------|
| catalogue | Go | Needs OTel SDK integration |
| payment | Go | Needs OTel SDK integration |
| user | Go | Needs OTel SDK integration |
| front-end | Node.js | Needs OTel SDK integration |

### Observable Operations

In SigNoz, you can see:

1. **Service Health**:
   - Request rate (requests/sec)
   - Error rate (%)
   - Latency percentiles (P50, P90, P99)

2. **Distributed Traces**:
   - Complete request flows across services
   - Individual span timings
   - Error traces with stack traces
   - Database query spans

3. **Example Trace Flow**:
   ```
   HTTP POST /orders
   ├─ orders service (50ms)
   │  ├─ MongoDB query (10ms)
   │  ├─ HTTP POST /shipping (30ms)
   │  │  └─ shipping service
   │  │     └─ RabbitMQ publish (5ms)
   │  └─ HTTP POST /payment (15ms)
   └─ Response 200 OK
   ```

## 🎯 Observability Features

### Available in SigNoz

1. **Services Dashboard**:
   - All monitored microservices
   - RED metrics per service
   - Service dependency map

2. **Traces Dashboard**:
   - Search traces by service, operation, tags
   - Filter by latency, errors, time range
   - Drill down into span details

3. **Logs Dashboard**:
   - Search logs by service, level, message
   - Correlate logs with traces
   - Filter by time range and attributes

4. **Alerts** (Optional):
   - Create alerts on metrics
   - Notification channels (email, Slack, etc.)
   - Alert rules based on thresholds

## 🔧 Configuration Files

### Key Configuration Files

1. **docker-compose.yml**:
   - Defines all services
   - Sets up networks and volumes
   - Configures environment variables
   - Establishes dependencies

2. **signoz-otel-collector-config.yaml**:
   - Receiver configurations (OTLP, Zipkin, Fluentd)
   - Processor pipelines
   - Exporter configurations
   - Service pipelines (traces, metrics, logs)

3. **sockshop/fluent.conf**:
   - Fluentd input configuration
   - Forward output to OTel Collector

## 📈 Performance Characteristics

### Expected Performance

- **Trace Latency**: 1-2 minutes from generation to visibility
- **Log Latency**: 1-5 seconds from generation to storage
- **Query Performance**: Sub-second for most queries
- **Data Retention**: Configurable (default: 15 days)

### Resource Usage

Typical resource consumption:
- **Memory**: 6-8GB total
- **CPU**: 2-4 cores under load
- **Disk**: ~500MB/hour with moderate traffic
- **Network**: Minimal (internal Docker network)

## 🛡️ Data Privacy & Security

### Local Deployment
- All data stays on your machine
- No external data transmission
- No telemetry sent to external services (can be disabled)

### Access Control
- SigNoz UI requires authentication
- Admin account created on first launch
- Additional users can be added in UI

## 🚀 Extension Points

### Add More Services
To add observability to other services:

1. **For Go Services**:
   ```go
   import "go.opentelemetry.io/otel"
   // Add OTel SDK instrumentation
   ```

2. **For Node.js Services**:
   ```javascript
   const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
   // Add OTel SDK instrumentation
   ```

3. **For Other Services**:
   - Use OTel auto-instrumentation libraries
   - Or send OTLP directly to port 4317/4318

### Add Custom Metrics
Send custom metrics via OTLP:
```bash
# Example: Send metric to OTel Collector
curl -X POST http://localhost:4318/v1/metrics \
  -H "Content-Type: application/json" \
  -d '{ ... }'
```

### Add Custom Dashboards
1. Open SigNoz UI
2. Navigate to Dashboards
3. Create new dashboard
4. Add panels with PromQL queries

## 📚 Reference

### Service Dependencies

```
SigNoz Startup Order:
1. init-clickhouse (init container)
2. zookeeper-1
3. clickhouse
4. schema-migrator-sync
5. signoz
6. signoz-otel-collector
7. schema-migrator-async

SockShop Startup Order:
1. Databases: catalogue-db, carts-db, orders-db, user-db
2. RabbitMQ
3. Basic services: catalogue, payment, user
4. Java services: carts, orders, shipping (need signoz-otel-collector)
5. Front-end services: front-end, edge-router
```

### Port Mapping

| Port | Service | Protocol | Purpose |
|------|---------|----------|---------|
| 80 | edge-router | HTTP | SockShop main entry |
| 3301 | signoz | HTTP | SigNoz UI |
| 4317 | otel-collector | gRPC | OTLP gRPC receiver |
| 4318 | otel-collector | HTTP | OTLP HTTP receiver |
| 8079 | front-end | HTTP | Direct frontend access |
| 8080 | edge-router | HTTP | Alternative entry |
| 9411 | otel-collector | HTTP | Zipkin receiver |
| 24224 | fluentd | TCP | Fluentd log collection |
| 24225 | otel-collector | TCP | Fluentd forward receiver |

## 🎓 Best Practices

### For Production Use

If adapting this for production:

1. **Security**:
   - Use secrets management
   - Enable TLS/SSL
   - Implement proper authentication
   - Use network policies

2. **Scalability**:
   - Use ClickHouse cluster mode
   - Scale OTel Collector horizontally
   - Use load balancers

3. **Reliability**:
   - Set up monitoring for monitoring (meta-monitoring)
   - Configure backup strategies
   - Implement disaster recovery
   - Set up health checks

4. **Cost Optimization**:
   - Configure data retention policies
   - Use sampling for high-volume traces
   - Optimize ClickHouse storage

---

**Last Updated**: October 2025  
**Maintained By**: OaaS Demo Project

