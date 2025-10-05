# Sock Shop Microservices Demo

This is a microservices demonstration application that shows a complete e-commerce platform for selling socks.

## Architecture

The application consists of multiple microservices:
- **Front-end**: Web UI (port 8079)
- **Edge Router**: API Gateway (ports 80 and 8080)
- **Catalogue**: Product catalog service with MySQL database
- **Carts**: Shopping cart service with MongoDB
- **Orders**: Order processing service with MongoDB
- **Shipping**: Shipping service
- **Payment**: Payment processing service
- **User**: User management service with MongoDB
- **Queue-Master**: Queue management service
- **RabbitMQ**: Message broker

## Prerequisites

- Docker Desktop installed and running on macOS
- At least 4GB of RAM allocated to Docker Desktop (recommended: 8GB)
- Available disk space for container images (~2-3 GB)

## Deployment Instructions

### 1. Start the Application

From the `sockshop` directory, run:

```bash
docker-compose up -d
```

This will:
- Download all required Docker images
- Create and start all microservices
- Set up the networking between services

### 2. Check Status

To see if all containers are running:

```bash
docker-compose ps
```

To view logs:

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f front-end
```

### 3. Access the Application

Once all services are running, access the Sock Shop application at:

- **Main Application**: http://localhost
- **Alternative Port**: http://localhost:8080
- **Front-end Direct**: http://localhost:8079

### 4. Test the Application

You can:
- Browse the product catalog
- Register a new user (or use test credentials if pre-loaded)
- Add items to cart
- Complete a purchase

Default test users (if available):
- Username: `user` / Password: `password`
- Username: `user1` / Password: `password`

## Management Commands

### Stop the Application

```bash
docker-compose stop
```

### Start Stopped Containers

```bash
docker-compose start
```

### Restart All Services

```bash
docker-compose restart
```

### Remove Everything

```bash
docker-compose down
```

To also remove volumes (databases will be reset):

```bash
docker-compose down -v
```

### Scale Services

You can scale specific services:

```bash
docker-compose up -d --scale front-end=3
```

## Monitoring

### Resource Usage

Check Docker Desktop Dashboard for:
- CPU usage
- Memory consumption
- Network activity

### Container Health

```bash
# See which containers are running
docker-compose ps

# Check logs for specific service
docker-compose logs [service-name]

# Follow logs in real-time
docker-compose logs -f [service-name]
```

## Troubleshooting

### Port Conflicts

If port 80 is already in use, you can modify the `docker-compose.yml` to change the edge-router port mapping:

```yaml
edge-router:
  ports:
    - "8081:80"  # Change 80 to 8081
    - "8080:8080"
```

### Services Not Starting

1. Check Docker Desktop is running
2. Ensure enough resources are allocated (Settings → Resources)
3. Check logs: `docker-compose logs [service-name]`
4. Try pulling images manually: `docker-compose pull`

### Reset Everything

```bash
docker-compose down -v
docker-compose up -d
```

## Architecture Diagram

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Edge Router │ :80, :8080
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Front-end  │ :8079
└──────┬──────┘
       │
       ├─────► Catalogue ──► Catalogue DB (MySQL)
       │
       ├─────► Carts ──────► Carts DB (MongoDB)
       │
       ├─────► Orders ─────► Orders DB (MongoDB)
       │              │
       │              └────► Shipping ──► RabbitMQ
       │                                      ▲
       ├─────► Payment                        │
       │                                      │
       ├─────► User ────────► User DB (MongoDB)
       │
       └─────► Queue-Master ──────────────────┘
```

## 📊 Load Testing

Python-based load testing with **Locust**! See **[LOAD_TESTING.md](LOAD_TESTING.md)** for details.

### Quick Start

```bash
# Activate virtual environment
source venv/bin/activate

# Run interactive load test menu
./run-load-test.sh

# Or start web UI
locust -f locustfile.py --host=http://localhost
# Then open http://localhost:8089
```

### Available Tests
- **Quick Test** (2 min, 10 users): Fast validation
- **Load Test** (5 min, 50 users): Realistic behavior
- **Stress Test** (10 min, 100 users): Find limits
- **Web UI Mode**: Interactive dashboard

## 🔍 Observability with SigNoz

Distributed tracing is **enabled and configured** for SigNoz! See **[SIGNOZ_INTEGRATION.md](SIGNOZ_INTEGRATION.md)** for details.

### View Traces
- **SigNoz UI**: http://localhost:3301
- Java services (carts, orders, shipping) are fully instrumented
- All services send traces via OpenTelemetry/Zipkin

### Generate Traces
```bash
# Run test traffic
./test-traces.sh

# Or run load tests
./run-load-tests.sh
```

## Additional Resources

- [Original Sock Shop Project](https://github.com/microservices-demo/microservices-demo)
- [Microservices Architecture](https://microservices.io/)
- [k6 Load Testing](https://k6.io/docs/)
- [SigNoz Documentation](https://signoz.io/docs/)

## Notes

- This setup uses production-ready images from Weaveworks
- Security capabilities are properly configured with minimal privileges
- All services use restart policies for resilience
- Read-only file systems are used where possible for security
- Distributed tracing enabled via Zipkin/OpenTelemetry → SigNoz
- Comprehensive load testing suite with k6

