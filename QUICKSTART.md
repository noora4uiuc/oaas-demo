# Quick Start Guide

Get SockShop + SigNoz running in 5 minutes!

## ⚡ One-Command Start

```bash
cd /Users/alamn/Developer/oaas-demo
docker compose up -d
```

## ⏱️ Wait for Services

Wait 2-3 minutes for all services to start. Check status:

```bash
docker compose ps
```

Look for these key services to be "healthy":
- `signoz-clickhouse` 
- `signoz`
- `signoz-otel-collector`

## 🌐 Access Applications

### 1. SockShop (E-commerce App)
**URL**: http://localhost

Try these actions:
- Browse products
- Register an account  
- Add items to cart
- Complete checkout

### 2. SigNoz (Observability Dashboard)
**URL**: http://localhost:3301

**First Time**: Create an admin account when prompted

Then:
- Go to **Services** → See `carts`, `orders`, `shipping`
- Go to **Traces** → See distributed traces from your shopping actions
- Click any trace → See the complete request flow

## 🎯 Quick Test Flow

1. **Generate Activity**:
   ```bash
   # Visit store
   open http://localhost
   
   # Browse products, add to cart, checkout
   ```

2. **View Traces** (wait 1-2 min):
   ```bash
   # Open SigNoz
   open http://localhost:3301
   
   # Navigate: Traces → Filter by service "carts" or "orders"
   ```

3. **See Results**:
   - Service map showing microservice connections
   - Trace timelines showing request flow
   - Performance metrics (latency, error rates)

## 🛑 Stop Everything

```bash
docker compose down
```

## 🔄 Start Again

```bash
docker compose up -d
```

## 🧹 Complete Reset

```bash
docker compose down -v  # Removes all data
docker compose up -d    # Fresh start
```

## ❓ Problems?

### Services won't start
```bash
# Check Docker resources (need 8GB RAM)
docker system df

# Clean up
docker system prune -a
```

### No traces appearing
```bash
# Check OTel Collector logs
docker compose logs signoz-otel-collector

# Verify Zipkin endpoint
curl http://localhost:9411/api/v2/services

# Wait 2-3 minutes (buffer delay)
```

### Port conflicts
```bash
# Check what's using ports
lsof -i :80
lsof -i :3301

# Edit docker-compose.yml to change ports
```

## 📚 Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Check [sockshop/OBSERVABILITY_GUIDE.md](sockshop/OBSERVABILITY_GUIDE.md) for observability details
- Run load tests: `cd sockshop && ./run-load-test.sh`

## 🎓 Key Concepts

**What's Happening?**
1. SockShop Java services send traces in Zipkin format
2. SigNoz OTel Collector receives traces on port 9411
3. Traces are stored in ClickHouse database
4. SigNoz UI visualizes the traces at port 3301

**Services with Tracing**:
- ✅ `carts` - Shopping cart (Java + Zipkin)
- ✅ `orders` - Order processing (Java + Zipkin)  
- ✅ `shipping` - Shipping (Java + Zipkin)

These are fully instrumented and will show up in SigNoz automatically!

---

**That's it! You now have a complete observability stack running!** 🎉

