# Load Testing Guide for Sock Shop

This guide explains how to perform comprehensive load testing on your Sock Shop deployment using **Locust** - a Python-based load testing framework.

## 📋 Overview

The load testing suite includes:
- **Quick Test**: 10 users, 2 minutes - Fast validation
- **Load Test**: 50 users, 5 minutes - Realistic behavior
- **Stress Test**: 100 users, 10 minutes - Push limits
- **Web UI Mode**: Interactive dashboard for custom tests

## 🛠️ Prerequisites

### Python Virtual Environment (Already Set Up!)

The virtual environment is already created with Locust installed:

```bash
# Activate the virtual environment
source venv/bin/activate

# Verify Locust is installed
locust --version
```

### Ensure Services are Running

```bash
# Check Sock Shop is running
docker-compose ps

# Check SigNoz is running
docker ps | grep signoz
```

## 🚀 Quick Start

### Option 1: Interactive Menu (Headless Mode)

```bash
source venv/bin/activate
./run-load-test.sh
```

This presents an interactive menu where you can choose:
1. **Quick Test** - 10 users, 2 minutes
2. **Load Test** - 50 users, 5 minutes  
3. **Stress Test** - 100 users, 10 minutes
4. **Web UI Mode** - Interactive dashboard
5. **Custom Test** - Your own parameters

### Option 2: Web UI Mode (Recommended for First Time)

```bash
source venv/bin/activate
locust -f locustfile.py --host=http://localhost
```

Then open **http://localhost:8089** in your browser and configure:
- Number of users
- Spawn rate (users started per second)
- Run time (optional)

### Option 3: Direct Command Line

```bash
source venv/bin/activate

# Quick test - 10 users, 2 minutes
locust -f locustfile.py --host=http://localhost --headless -u 10 -r 2 -t 2m

# Load test - 50 users, 5 minutes
locust -f locustfile.py --host=http://localhost --headless -u 50 -r 5 -t 5m

# Stress test - 100 users, 10 minutes
locust -f locustfile.py --host=http://localhost --headless -u 100 -r 10 -t 10m
```

## 📊 Test Scenarios

### User Behavior Simulation

Locust simulates **3 types of realistic users**:

**1. Browser Users (40% weight)**
- Just browsing, no purchases
- Views catalogue and products
- Think time: 2-5 seconds between actions
- Tasks:
  - Browse catalogue (high frequency)
  - View product details (medium)
  - Visit homepage (low)

**2. Shopper Users (50% weight)**
- Browse and add items to cart
- Think time: 1-3 seconds
- Tasks:
  - Browse and view products (high)
  - Add items to cart (medium)
  - View cart (low)

**3. Power Users (10% weight)**
- Complete full checkout flow
- Think time: 1-2 seconds (fast)
- Tasks:
  - Quick browse
  - Add multiple items rapidly
  - Attempt checkout (generates traces through orders → shipping → payment)

### Test Configurations

### 1. Quick Test (2 minutes)
**Purpose**: Fast validation

**Profile**:
- Users: 10 concurrent
- Spawn rate: 2 users/sec
- Duration: 2 minutes

**Use Case**: Quick health check, development testing

```bash
./run-load-test.sh  # Select option 1
```

### 2. Load Test (5 minutes)
**Purpose**: Realistic user behavior

**Profile**:
- Users: 50 concurrent
- Spawn rate: 5 users/sec
- Duration: 5 minutes
- Mix: 40% browsers, 50% shoppers, 10% power users

**Use Case**: Performance baseline, capacity planning

```bash
./run-load-test.sh  # Select option 2
```

**Expected Behavior**:
- Response time p95 < 1000ms
- Response time p99 < 2000ms
- Error rate < 5%

### 3. Stress Test (10 minutes)
**Purpose**: Find system limits

**Profile**:
- Users: 100 concurrent
- Spawn rate: 10 users/sec
- Duration: 10 minutes

**Use Case**: Capacity planning, finding bottlenecks

```bash
./run-load-test.sh  # Select option 3
```

**Expected Behavior**:
- System degrades gracefully
- Services remain responsive
- Error rate acceptable under load

### 4. Web UI Mode (Interactive)
**Purpose**: Custom testing with visual feedback

**Profile**:
- Configure dynamically via web interface
- Real-time charts and statistics
- Start/stop tests on demand

**Use Case**: Exploratory testing, demonstrations

```bash
./run-load-test.sh  # Select option 4
# Then open http://localhost:8089
```

## 📈 Monitoring During Tests

### Real-Time Monitoring

**Terminal 1: Run Load Test**
```bash
./run-load-tests.sh
```

**Terminal 2: Watch Docker Stats**
```bash
docker stats
```

**Terminal 3: Watch Service Logs**
```bash
# Watch all services
docker-compose logs -f

# Watch specific service
docker-compose logs -f carts
docker-compose logs -f orders
```

**Browser: SigNoz Dashboard**
```
http://localhost:3301
```

### Key Metrics to Watch

#### In k6 Output:
- `http_reqs`: Total requests
- `http_req_duration`: Response times (avg, p95, p99)
- `http_req_failed`: Error rate
- `iterations`: Completed user scenarios
- `vus`: Virtual users (concurrent)

#### In Docker Stats:
- CPU usage per container
- Memory usage
- Network I/O

#### In SigNoz:
- **Services**: Latency, error rate, requests/sec
- **Traces**: End-to-end request flows
- **Service Map**: Dependencies and bottlenecks

## 🎯 Expected Results

### Smoke Test
```
✓ http_req_duration........: avg=150ms p95=300ms
✓ http_req_failed..........: 0.00%
✓ http_reqs................: 600
```

### Load Test (20 users)
```
✓ http_req_duration........: avg=250ms p95=800ms p99=1500ms
✓ http_req_failed..........: 2.00%
✓ http_reqs................: ~12,000
✓ cart_operations..........: 2,400
✓ checkout_attempts........: 240
```

### Load Test (50 users)
```
⚠ http_req_duration........: avg=450ms p95=1200ms p99=2500ms
⚠ http_req_failed..........: 5.00%
✓ http_reqs................: ~30,000
```

### Stress Test (Peak 400 users)
```
⚠ http_req_duration........: avg=2000ms p95=4500ms
⚠ http_req_failed..........: 15-25%
✓ http_reqs................: ~150,000
```

## 🔍 Analyzing Results

### 1. Check Test Summary

At the end of each test, k6 provides a summary:

```
     ✓ homepage status is 200
     ✓ catalogue has products
     ✓ added to cart

     checks.........................: 95.00% ✓ 9500  ✗ 500
     data_received..................: 120 MB  8.0 MB/s
     data_sent......................: 15 MB   1.0 MB/s
     http_req_duration..............: avg=450ms p95=1200ms p99=2500ms
     http_req_failed................: 5.00%  ✓ 500   ✗ 9500
     http_reqs......................: 10000  666/s
     iterations.....................: 2000   133/s
```

### 2. Review Traces in SigNoz

Navigate to http://localhost:3301:

**Services View**:
- Check P99 latency for each service
- Identify services with high error rates
- Compare performance across services

**Traces View**:
- Filter by service: `service.name = carts`
- Sort by duration to find slow requests
- Look for failed traces (status = error)

**Service Map**:
- Visualize dependencies
- Identify bottlenecks
- See call patterns

### 3. Identify Bottlenecks

Common bottlenecks to look for:

**Database Connections**:
```bash
docker-compose logs carts-db | grep -i "connection"
docker-compose logs orders-db | grep -i "connection"
```

**Memory Issues**:
```bash
docker stats --no-stream | grep -E "carts|orders|shipping"
```

**Network Saturation**:
```bash
docker stats --format "table {{.Container}}\t{{.NetIO}}"
```

## 🎓 Advanced Usage

### Custom Test Configuration

Create your own k6 script:

```javascript
// custom-test.js
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 50,
  duration: '5m',
};

export default function () {
  const res = http.get('http://localhost/catalogue');
  check(res, { 'status is 200': (r) => r.status === 200 });
}
```

Run it:
```bash
k6 run custom-test.js
```

### Environment Variables

Customize tests with environment variables:

```bash
# Change base URL
k6 run -e BASE_URL=http://localhost:8080 loadtest/smoke-test.js

# Increase users
k6 run -e VUS=100 loadtest/load-test.js
```

### Cloud Integration

Export results to k6 Cloud for detailed analysis:

```bash
k6 run --out cloud loadtest/load-test.js
```

### JSON Output

Save results in JSON format:

```bash
k6 run --out json=results.json loadtest/load-test.js
```

## 🐛 Troubleshooting

### Problem: High Error Rate

**Symptoms**: `http_req_failed` > 10%

**Solutions**:
1. Check if services are healthy: `docker-compose ps`
2. Review logs: `docker-compose logs carts orders`
3. Reduce concurrent users
4. Increase service resources

### Problem: Timeouts

**Symptoms**: Many requests timeout

**Solutions**:
1. Check network connectivity
2. Increase Docker resources (CPU/Memory)
3. Add `timeout: '60s'` to k6 options
4. Check database connections

### Problem: Connection Refused

**Symptoms**: Can't connect to http://localhost

**Solutions**:
1. Verify Sock Shop is running: `docker-compose ps`
2. Check port binding: `lsof -i :80`
3. Try alternative port: `http://localhost:8080`
4. Check firewall settings

### Problem: Inconsistent Results

**Symptoms**: Results vary widely between runs

**Solutions**:
1. Ensure no other load on system
2. Let services warm up (run smoke test first)
3. Run longer tests for stability
4. Check background processes

## 📋 Best Practices

1. **Start Small**: Always run smoke test first
2. **Warm Up**: Give services time to initialize
3. **Baseline First**: Establish performance baseline with load test
4. **Incremental Load**: Increase load gradually
5. **Monitor Everything**: Watch metrics in real-time
6. **Document Results**: Save test results for comparison
7. **Clean State**: Restart services between major tests if needed

## 🔗 Resources

- **k6 Documentation**: https://k6.io/docs/
- **SigNoz Docs**: https://signoz.io/docs/
- **Sock Shop GitHub**: https://github.com/microservices-demo/microservices-demo

## 📊 Test Results Directory

All test results are saved to: `loadtest/results/`

Each run creates a timestamped file:
```
loadtest/results/
  ├── smoke-test_20251004_153000.txt
  ├── load-test_20251004_153300.txt
  └── stress-test_20251004_155500.txt
```

Review these files to compare performance across runs.

