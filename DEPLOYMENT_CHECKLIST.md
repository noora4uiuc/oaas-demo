# Deployment Checklist

Use this checklist to ensure successful deployment of the OaaS Demo stack.

## ✅ Pre-Deployment

### System Requirements
- [ ] Docker Desktop installed (or Docker Engine + Docker Compose)
- [ ] At least 8GB RAM allocated to Docker
- [ ] At least 20GB free disk space
- [ ] macOS, Linux, or Windows with WSL2

### Port Availability
Check these ports are available (not in use):
- [ ] Port 80 (SockShop main)
- [ ] Port 3301 (SigNoz UI)
- [ ] Port 4317 (OTLP gRPC)
- [ ] Port 4318 (OTLP HTTP)
- [ ] Port 8079 (SockShop frontend)
- [ ] Port 8080 (SockShop alt)
- [ ] Port 9411 (Zipkin)
- [ ] Port 24224 (Fluentd)

**Check command:**
```bash
lsof -i :80 -i :3301 -i :4317 -i :4318 -i :8079 -i :8080 -i :9411 -i :24224
```

### Project Files
- [ ] `docker-compose.yml` exists
- [ ] `signoz-otel-collector-config.yaml` exists
- [ ] `sockshop/fluent.conf` exists
- [ ] SigNoz config files in `signoz/signoz/deploy/common/` exist

## 🚀 Deployment Steps

### 1. Initial Startup
- [ ] Navigate to project root: `cd /Users/alamn/Developer/oaas-demo`
- [ ] Start services: `docker compose up -d` or `make up`
- [ ] Wait 2-3 minutes for initialization

### 2. Verify Services
- [ ] Run health check: `./check-health.sh` or `make health`
- [ ] Check all containers running: `docker compose ps`
- [ ] Verify critical services are healthy:
  - [ ] signoz-clickhouse (healthy)
  - [ ] signoz (healthy)
  - [ ] signoz-otel-collector (running)
  - [ ] carts (running)
  - [ ] orders (running)
  - [ ] shipping (running)

### 3. Access Applications
- [ ] Open SockShop: http://localhost
  - [ ] Can see product catalog
  - [ ] Can navigate the store
- [ ] Open SigNoz: http://localhost:3301
  - [ ] Can access the UI (may show login/registration)

### 4. First-Time SigNoz Setup
- [ ] Register admin account (first time only)
- [ ] Log in successfully
- [ ] Can access dashboard

### 5. Verify Integration

#### Generate Test Traffic
- [ ] Browse SockShop products
- [ ] Register a user account
- [ ] Add items to cart
- [ ] Complete checkout flow

#### Check Traces in SigNoz
- [ ] Wait 1-2 minutes after generating traffic
- [ ] Navigate to **Services** in SigNoz
- [ ] Verify services appear:
  - [ ] `carts` service visible
  - [ ] `orders` service visible
  - [ ] `shipping` service visible
- [ ] Navigate to **Traces**
- [ ] Can see traces from SockShop services
- [ ] Can drill down into individual traces
- [ ] Traces show multiple spans across services

#### Check Logs
- [ ] Navigate to **Logs** in SigNoz
- [ ] Can see log entries (if logging is configured)

## 🧪 Testing

### Manual Testing
- [ ] Complete a full shopping flow:
  1. [ ] Browse products
  2. [ ] Add to cart
  3. [ ] View cart
  4. [ ] Checkout
  5. [ ] Verify order
- [ ] Check corresponding traces appear in SigNoz

### Load Testing (Optional)
- [ ] Navigate to sockshop directory
- [ ] Activate Python venv: `source venv/bin/activate`
- [ ] Run load test: `./run-load-test.sh`
- [ ] Verify high volume of traces in SigNoz

## 📊 Post-Deployment Verification

### Service Health
- [ ] All containers show "Up" status
- [ ] No containers in restart loop
- [ ] No error messages in logs: `docker compose logs`

### Network Connectivity
- [ ] SockShop services can reach each other
- [ ] Java services can send traces to OTel Collector
- [ ] OTel Collector can reach ClickHouse
- [ ] SigNoz can query ClickHouse

### Data Flow
- [ ] Traces flowing from SockShop → OTel Collector → ClickHouse → SigNoz UI
- [ ] Metrics being collected
- [ ] Logs being forwarded (from carts service)

### Resource Usage
- [ ] Docker memory usage under limits: `docker stats`
- [ ] Disk usage reasonable: `docker system df`
- [ ] No out-of-memory errors

## 🔍 Troubleshooting Checklist

If something doesn't work:

### Services Won't Start
- [ ] Check Docker Desktop is running
- [ ] Verify Docker has enough resources (Settings → Resources)
- [ ] Check for port conflicts: `lsof -i :<port>`
- [ ] Review logs: `docker compose logs -f`
- [ ] Try clean restart: `docker compose down && docker compose up -d`

### No Traces Appearing
- [ ] Wait full 2-3 minutes (buffering delay)
- [ ] Verify traffic was generated in SockShop
- [ ] Check OTel Collector logs: `docker compose logs signoz-otel-collector`
- [ ] Verify Zipkin endpoint: `curl http://localhost:9411/api/v2/services`
- [ ] Check Java service logs for Zipkin config: `docker compose logs carts | grep zipkin`
- [ ] Restart OTel Collector: `docker compose restart signoz-otel-collector`

### SigNoz UI Not Loading
- [ ] Check SigNoz container is healthy: `docker compose ps signoz`
- [ ] Check logs: `docker compose logs signoz`
- [ ] Try restarting: `docker compose restart signoz`
- [ ] Verify port 3301 is accessible: `curl http://localhost:3301`

### Memory Issues
- [ ] Stop and restart Docker Desktop
- [ ] Increase memory allocation (8GB minimum)
- [ ] Clean up unused resources: `docker system prune`
- [ ] Consider running fewer services

## 📝 Success Criteria

Your deployment is successful if:

- ✅ All core services are running (SigNoz, OTel Collector, SockShop)
- ✅ Can access SockShop at http://localhost
- ✅ Can access SigNoz at http://localhost:3301
- ✅ Can complete shopping flow in SockShop
- ✅ Traces from `carts`, `orders`, and `shipping` appear in SigNoz
- ✅ Can drill down into traces and see span details
- ✅ No containers in crash loop
- ✅ Resource usage is stable

## 🎯 Optional Enhancements

After successful deployment, consider:

- [ ] Set up custom dashboards in SigNoz
- [ ] Configure alerts for error rates
- [ ] Add more services to monitoring
- [ ] Instrument Go services (catalogue, payment, user)
- [ ] Instrument Node.js front-end
- [ ] Set up log collection from more services
- [ ] Configure retention policies
- [ ] Set up regular backups: `make backup`

## 📚 Reference

### Key URLs
- SockShop: http://localhost
- SigNoz: http://localhost:3301
- OTLP gRPC: http://localhost:4317
- OTLP HTTP: http://localhost:4318
- Zipkin: http://localhost:9411

### Key Commands
```bash
# Start
make up

# Check health
make health

# View logs
make logs

# Stop
make down

# Clean reset
make clean-all
```

### Documentation
- Main README: [README.md](README.md)
- Quick Start: [QUICKSTART.md](QUICKSTART.md)
- SockShop Observability: [sockshop/OBSERVABILITY_GUIDE.md](sockshop/OBSERVABILITY_GUIDE.md)

---

**Last Updated**: October 2025  
**Stack Version**: SigNoz v0.96.1, OTel Collector v0.129.6

