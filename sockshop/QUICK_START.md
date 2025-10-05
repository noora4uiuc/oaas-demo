# 🚀 Sock Shop - Quick Start Guide

## Prerequisites

- ✅ Docker Desktop installed and running
- ✅ k6 installed: `brew install k6`
- ✅ SigNoz running locally

## 1. Start Sock Shop

```bash
cd /Users/alamn/Developer/oaas-demo/sockshop
docker-compose up -d
```

**Wait 30 seconds for services to initialize**

## 2. Verify Everything is Running

```bash
# Check Sock Shop services
docker-compose ps

# Check SigNoz
docker ps | grep signoz
```

## 3. Access Applications

| Service | URL | Description |
|---------|-----|-------------|
| **Sock Shop Store** | http://localhost | Main application |
| **Sock Shop Alt** | http://localhost:8080 | Alternative port |
| **SigNoz Dashboard** | http://localhost:3301 | Observability & Traces |
| **Zipkin Bridge** | http://localhost:9411 | Zipkin UI (optional) |

## 4. Run Load Tests

### Interactive Menu
```bash
./run-load-tests.sh
```

### Individual Tests
```bash
# Quick smoke test (2 min)
k6 run loadtest/smoke-test.js

# Realistic load test (16 min)
k6 run loadtest/load-test.js

# Stress test (25 min)
k6 run loadtest/stress-test.js

# Spike test (6 min)
k6 run loadtest/spike-test.js
```

## 5. View Traces in SigNoz

1. Open http://localhost:3301
2. Navigate to **Services** tab
3. Look for these services:
   - `carts` (Shopping cart)
   - `orders` (Order processing)
   - `shipping` (Shipping)
   - `zipkin-bridge` (Trace collector)
4. Navigate to **Traces** tab to see distributed traces
5. Click on any trace to see the complete request flow

## 6. Monitor Performance

### Real-time Monitoring
```bash
# Terminal 1: Load test
./run-load-tests.sh

# Terminal 2: Docker stats
docker stats

# Terminal 3: Service logs
docker-compose logs -f carts orders shipping
```

### In SigNoz
- **Services**: Check latency, error rates, throughput
- **Traces**: Analyze slow requests
- **Service Map**: Visualize dependencies

## 7. Common Commands

```bash
# Stop all services
docker-compose stop

# Start stopped services
docker-compose start

# Restart services
docker-compose restart

# View logs
docker-compose logs -f [service-name]

# Remove everything
docker-compose down

# Remove everything including data
docker-compose down -v
```

## 8. Load Test Results

Results are saved to: `loadtest/results/`

Each test creates a timestamped file with metrics.

## 🎯 Recommended First Steps

1. **Start with Smoke Test** (2 min)
   ```bash
   k6 run loadtest/smoke-test.js
   ```

2. **Generate traces** and view in SigNoz:
   - Open http://localhost:3301
   - Wait 1-2 minutes for traces to appear

3. **Run Load Test** (16 min) to see realistic behavior:
   ```bash
   k6 run loadtest/load-test.js
   ```

4. **Analyze in SigNoz**:
   - Check service latencies
   - View distributed traces
   - Identify bottlenecks

## 📚 Documentation

- **[README.md](README.md)** - Complete setup guide
- **[LOAD_TESTING.md](LOAD_TESTING.md)** - Detailed load testing guide
- **[SIGNOZ_INTEGRATION.md](SIGNOZ_INTEGRATION.md)** - Tracing integration details
- **[DEPLOYMENT_STATUS.md](DEPLOYMENT_STATUS.md)** - Current deployment info

## 🆘 Troubleshooting

### Services not starting
```bash
docker-compose down
docker-compose up -d
```

### No traces in SigNoz
1. Verify SigNoz is running: `docker ps | grep signoz`
2. Check Zipkin bridge: `curl http://localhost:9411`
3. Run smoke test to generate traffic
4. Wait 1-2 minutes for traces to appear

### High error rates
1. Check service logs: `docker-compose logs carts`
2. Reduce concurrent users in load test
3. Verify resources: `docker stats`

### Port conflicts
If port 80 is in use, access via:
- http://localhost:8080
- http://localhost:8079

## 🎓 Learning Path

1. ✅ Deploy Sock Shop
2. ✅ Verify services are running
3. ✅ Browse the application
4. ✅ Run smoke test
5. ✅ View traces in SigNoz
6. ✅ Run load test
7. ✅ Analyze performance metrics
8. ✅ Experiment with stress and spike tests

---

**Need help?** Check the detailed documentation in:
- LOAD_TESTING.md
- SIGNOZ_INTEGRATION.md

