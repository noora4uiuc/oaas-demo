# OaaS Demo - Integrated SockShop & SigNoz Deployment

This repository contains a fully integrated deployment of the SockShop microservices application with SigNoz observability platform, all running on Docker Compose.

## 🎯 Overview

This setup provides:
- **SockShop**: A complete microservices e-commerce application
- **SigNoz**: Full observability platform with traces, metrics, and logs
- **Full Integration**: Automatic trace collection from SockShop services to SigNoz
- **Unified Network**: All services communicate on a single Docker network

## 📋 Prerequisites

- Docker Desktop for Mac (or Docker Engine + Docker Compose)
- At least 8GB RAM available for Docker
- Ports available: 80, 3301, 4317, 4318, 8079, 8080, 9411, 24224

## 🚀 Quick Start

### 1. Start Everything

From the root directory (`/Users/alamn/Developer/oaas-demo`):

```bash
docker compose up -d
```

This will start:
- All SigNoz components (ClickHouse, ZooKeeper, OTel Collector, SigNoz UI)
- All SockShop microservices
- Supporting services (Fluentd, RabbitMQ, databases)

### 2. Wait for Services to be Ready

Check the status of all services:

```bash
docker compose ps
```

Wait until all services are healthy (this may take 2-3 minutes on first startup).

### 3. Access the Applications

| Service | URL | Description |
|---------|-----|-------------|
| **SockShop Store** | http://localhost | Main e-commerce application |
| **SockShop Alt** | http://localhost:8080 | Alternative access point |
| **Front-end Direct** | http://localhost:8079 | Direct front-end access |
| **SigNoz UI** | http://localhost:3301 | Observability dashboard |

### 4. First Time SigNoz Setup

On first launch, you need to create an admin account:

1. Open http://localhost:3301
2. Fill in the registration form to create your admin user
3. Log in with your credentials

## 🎮 Using the System

### Generate Traces

1. **Browse Products**: Visit http://localhost and browse the catalog
2. **User Registration**: Register a new account
3. **Shopping Flow**:
   - Add items to your cart
   - Proceed to checkout
   - Complete an order

These actions will generate distributed traces across multiple microservices.

### View Observability Data in SigNoz

1. Open http://localhost:3301
2. Navigate to **Services** to see all microservices
3. Navigate to **Traces** to see distributed traces
4. Click on individual traces to see the complete request flow
5. Navigate to **Logs** to see application logs

### Expected Services in SigNoz

You should see traces from these Java services (with built-in Zipkin support):
- ✅ **carts** - Shopping cart operations
- ✅ **orders** - Order processing
- ✅ **shipping** - Shipping management

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        SockShop Application                  │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Front-End│  │ Catalogue│  │  Carts   │  │  Orders  │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │             │              │             │          │
│       │             │              │ (Zipkin)    │ (Zipkin) │
│       │             │              └──────┬──────┘          │
│       │             │                     │                 │
│  ┌────┴─────┐  ┌───┴────┐  ┌──────────┐  │  ┌──────────┐  │
│  │   User   │  │Payment │  │ Shipping │  │  │ RabbitMQ │  │
│  └──────────┘  └────────┘  └────┬─────┘  │  └──────────┘  │
│                                  │(Zipkin)│                 │
└──────────────────────────────────┼────────┼────────────────┘
                                   │        │
                                   ▼        ▼
                    ┌──────────────────────────────────┐
                    │   SigNoz OTel Collector          │
                    │  - Zipkin Receiver (9411)        │
                    │  - OTLP gRPC (4317)              │
                    │  - OTLP HTTP (4318)              │
                    │  - Fluentd Forward (24225)       │
                    └────────────┬─────────────────────┘
                                 │
                    ┌────────────▼─────────────────────┐
                    │         ClickHouse DB            │
                    │  - Traces                        │
                    │  - Metrics                       │
                    │  - Logs                          │
                    └────────────┬─────────────────────┘
                                 │
                    ┌────────────▼─────────────────────┐
                    │         SigNoz UI                │
                    │       (Port 3301)                │
                    └──────────────────────────────────┘
```

## 📊 What's Being Monitored

### Traces
- **Java Services** (with Spring Boot Zipkin):
  - `carts`: Shopping cart operations → MongoDB
  - `orders`: Order processing → shipping, payment, MongoDB
  - `shipping`: Shipping operations → RabbitMQ

### Logs
- Application logs from `carts` service via Fluentd

### Metrics
- OTel Collector self-monitoring metrics
- Span metrics derived from traces (RED metrics: Rate, Errors, Duration)

## 🛠️ Management Commands

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f signoz
docker compose logs -f signoz-otel-collector
docker compose logs -f carts
docker compose logs -f orders
```

### Restart Services

```bash
# Restart everything
docker compose restart

# Restart specific service
docker compose restart signoz-otel-collector
docker compose restart carts
```

### Stop Everything

```bash
docker compose down
```

### Stop and Remove All Data

```bash
docker compose down -v
```

### Check Service Health

```bash
docker compose ps
```

## 🔍 Troubleshooting

### Services Not Starting

1. Check available resources:
   ```bash
   docker system df
   docker system prune  # Clean up if needed
   ```

2. Check logs:
   ```bash
   docker compose logs -f
   ```

3. Restart Docker Desktop

### No Traces Appearing in SigNoz

1. Verify SigNoz OTel Collector is running:
   ```bash
   docker compose ps signoz-otel-collector
   ```

2. Check if Zipkin endpoint is accessible:
   ```bash
   curl http://localhost:9411/api/v2/services
   ```

3. Check Java service logs for Zipkin configuration:
   ```bash
   docker compose logs carts | grep -i zipkin
   ```

4. Wait 1-2 minutes for traces to appear (there's a buffer delay)

### Port Conflicts

If you get port binding errors, check what's using the ports:

```bash
lsof -i :80
lsof -i :3301
lsof -i :4317
```

Edit the `docker-compose.yml` to change port mappings if needed.

### Out of Memory

SigNoz with ClickHouse requires significant memory. Increase Docker Desktop memory:
1. Open Docker Desktop
2. Go to Settings → Resources
3. Increase Memory to at least 8GB
4. Click Apply & Restart

## 📁 Project Structure

```
oaas-demo/
├── docker-compose.yml              # Main integrated compose file
├── signoz-otel-collector-config.yaml  # OTel Collector configuration
├── README.md                       # This file
├── sockshop/                       # SockShop specific configs
│   ├── fluent.conf                # Fluentd configuration
│   ├── locustfile.py              # Load testing script
│   └── ...
└── signoz/                         # SigNoz deployment files
    └── signoz/deploy/
        ├── common/                # Shared configs
        └── ...
```

## 🧪 Load Testing

The repository includes a Locust-based load testing script:

```bash
# Install Python dependencies (if not already done)
cd sockshop
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run load test
./run-load-test.sh
```

This will generate traffic to the SockShop application, creating traces visible in SigNoz.

## 🔗 Useful Endpoints

| Endpoint | Port | Description |
|----------|------|-------------|
| http://localhost | 80 | SockShop Store |
| http://localhost:3301 | 3301 | SigNoz UI |
| http://localhost:4317 | 4317 | OTLP gRPC Receiver |
| http://localhost:4318 | 4318 | OTLP HTTP Receiver |
| http://localhost:9411 | 9411 | Zipkin Receiver |
| http://localhost:24224 | 24224 | Fluentd Receiver |

## 📚 Documentation

### SockShop
- See `sockshop/README.md` for SockShop-specific documentation
- See `sockshop/OBSERVABILITY_GUIDE.md` for observability details
- See `sockshop/LOAD_TESTING.md` for load testing guide

### SigNoz
- Official Docs: https://signoz.io/docs/
- GitHub: https://github.com/SigNoz/signoz
- See `signoz/DEPLOYMENT_INFO.md` for deployment details

## 🎓 Learning Resources

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [SigNoz Documentation](https://signoz.io/docs/)
- [Spring Boot + Zipkin](https://spring.io/projects/spring-cloud-sleuth)
- [Microservices Observability](https://microservices.io/patterns/observability/distributed-tracing.html)

## ⚠️ Important Notes

1. **First Start**: The first startup will take longer as Docker pulls all images
2. **Resource Usage**: This setup uses ~6-8GB of RAM when fully running
3. **Data Persistence**: Data is stored in Docker volumes and persists across restarts
4. **Clean Reset**: Use `docker compose down -v` to completely reset everything
5. **Production**: This is a demo setup - not recommended for production use

## 🔄 Update & Maintenance

### Update Images

```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d
```

### Backup Data

```bash
# Backup volumes
docker run --rm -v signoz-clickhouse:/data -v $(pwd):/backup alpine tar czf /backup/clickhouse-backup.tar.gz /data
docker run --rm -v signoz-sqlite:/data -v $(pwd):/backup alpine tar czf /backup/sqlite-backup.tar.gz /data
```

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review service logs: `docker compose logs -f`
3. Verify system resources are sufficient
4. Try a clean restart: `docker compose down && docker compose up -d`

## 📝 License

- SockShop: https://github.com/microservices-demo/microservices-demo
- SigNoz: Apache 2.0 License

