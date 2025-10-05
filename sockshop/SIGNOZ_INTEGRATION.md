# SigNoz Integration Guide

This guide explains how the Sock Shop application is integrated with SigNoz for distributed tracing.

## 🎯 Overview

The Sock Shop application has been configured to send traces to your locally running SigNoz instance using OpenTelemetry.

## 🏗️ Architecture

```
┌─────────────────┐
│  Sock Shop App  │
│   (Services)    │
└────────┬────────┘
         │
         │ Zipkin Protocol (Java services)
         │ OTLP (Go/Node services)
         │
         ▼
┌─────────────────┐        ┌──────────────────┐
│     Zipkin      │───────>│  SigNoz OTel     │
│  (Port 9411)    │        │   Collector      │
└─────────────────┘        │ (Ports 4317/4318)│
                           └─────────┬────────┘
                                     │
                                     ▼
                           ┌──────────────────┐
                           │   SigNoz UI      │
                           │  (Port 3301)     │
                           └──────────────────┘
```

## 🔧 Configuration Details

### Services with Tracing Enabled

All microservices are configured to send traces:

1. **Java Services** (Spring Boot with Zipkin):
   - `carts` - Shopping cart service
   - `orders` - Order processing service  
   - `shipping` - Shipping service
   - **Method**: Spring Zipkin integration → Zipkin bridge → SigNoz

2. **Go Services**:
   - `catalogue` - Product catalog
   - `payment` - Payment processing
   - `user` - User management
   - **Method**: Direct OTLP export to SigNoz (requires instrumentation)

3. **Node.js Service**:
   - `front-end` - Web UI
   - **Method**: Direct OTLP export to SigNoz (requires instrumentation)

### Environment Variables

Each service is configured with:

```yaml
environment:
  - OTEL_EXPORTER_OTLP_ENDPOINT=http://host.docker.internal:4318
  - OTEL_SERVICE_NAME=<service-name>
  - OTEL_RESOURCE_ATTRIBUTES=service.name=<service-name>,service.version=<version>
```

For Java services (using Zipkin):
```yaml
environment:
  - JAVA_OPTS=-Dspring.zipkin.enabled=true -Dspring.zipkin.baseUrl=http://host.docker.internal:9411
```

### Zipkin Bridge

A Zipkin container acts as a bridge to collect Zipkin-format traces and forward them to SigNoz:

```yaml
zipkin:
  image: openzipkin/zipkin-slim:latest
  ports:
    - "9411:9411"
  environment:
    - STORAGE_TYPE=mem
    - OTEL_EXPORTER_OTLP_ENDPOINT=http://host.docker.internal:4318
```

## 🚀 Usage

### 1. Access the Application

Visit the Sock Shop store:
- http://localhost
- http://localhost:8080
- http://localhost:8079

### 2. Generate Traces

Perform actions in the application:
- Browse products (hits `catalogue` service)
- Register/login (hits `user` service)
- Add items to cart (hits `carts` service)
- Complete checkout (hits `orders`, `shipping`, `payment` services)

### 3. View Traces in SigNoz

Open SigNoz UI:
- **URL**: http://localhost:3301
- Navigate to **Services** to see all microservices
- Navigate to **Traces** to see distributed traces
- Click on individual traces to see the complete request flow

## 📊 Expected Trace Flow

A typical checkout flow will create traces like:

```
front-end → edge-router → catalogue
                       → user
                       → carts
                       → orders → shipping → rabbitmq
                                → payment
```

## 🔍 Verifying Integration

### Check Service Discovery

In SigNoz, go to **Services** and you should see:
- ✅ carts
- ✅ orders
- ✅ shipping
- ✅ catalogue
- ✅ payment
- ✅ user
- ✅ front-end (if instrumented)
- ✅ zipkin-bridge

### Check Traces

1. Perform a few actions in the Sock Shop app
2. Wait 1-2 minutes for traces to appear
3. In SigNoz UI, go to **Traces**
4. Filter by service name (e.g., "carts", "orders")
5. You should see traces with multiple spans

### Check Logs

View service logs to confirm tracing:

```bash
# Check if Zipkin is receiving traces
docker-compose logs zipkin | grep -i span

# Check Java service logs
docker-compose logs carts | grep -i zipkin
docker-compose logs orders | grep -i zipkin
docker-compose logs shipping | grep -i zipkin
```

## 🛠️ Troubleshooting

### No Traces Appearing

**Issue**: Traces not showing up in SigNoz

**Solutions**:
1. Verify SigNoz is running:
   ```bash
   docker ps | grep signoz
   ```

2. Check SigNoz OTel Collector is accessible:
   ```bash
   curl http://localhost:4318/v1/traces
   ```

3. Check Zipkin is receiving traces:
   ```bash
   curl http://localhost:9411/api/v2/services
   ```

4. Verify service logs:
   ```bash
   docker-compose logs carts | tail -20
   ```

### Partial Traces

**Issue**: Only some services appear in traces

**Explanation**: 
- Java services (carts, orders, shipping) have **built-in** Zipkin support via Spring Boot
- Go services (catalogue, payment, user) require **manual instrumentation** with OTel SDK
- Node.js front-end requires **manual instrumentation** with OTel SDK

**Current Status**:
- ✅ Java services: Fully instrumented (via Spring Zipkin)
- ⚠️ Go services: Environment variables set, but require code-level OTel SDK integration
- ⚠️ Node.js front-end: Environment variables set, but require code-level OTel SDK integration

### Connection Errors

**Issue**: Services can't connect to SigNoz

**Solutions**:
1. Ensure `host.docker.internal` resolves correctly (macOS should support this by default)
2. Check firewall settings
3. Verify SigNoz ports are not blocked:
   ```bash
   lsof -i :4317
   lsof -i :4318
   lsof -i :9411
   ```

## 🎯 What's Working Now

### ✅ Fully Traced Services (Out of the Box)

These Java services are sending traces to SigNoz right now:

1. **carts** (Shopping Cart)
   - Operations: Add to cart, view cart, update quantities
   - Database: MongoDB

2. **orders** (Order Processing)
   - Operations: Create order, view orders, order status
   - Database: MongoDB
   - Downstream: shipping, payment

3. **shipping** (Shipping)
   - Operations: Create shipment, track shipment
   - Integration: RabbitMQ

### ⚠️ Partially Configured Services

These services have environment variables set but need code-level instrumentation:

- **catalogue** (Go) - Product listing
- **payment** (Go) - Payment processing
- **user** (Go) - User authentication
- **front-end** (Node.js) - Web UI

## 📈 Test Scenarios

### Scenario 1: Browse Products
1. Visit http://localhost
2. Browse products
3. **Expected trace**: front-end → catalogue → catalogue-db

### Scenario 2: User Registration
1. Click "Register"
2. Create a new account
3. **Expected trace**: front-end → user → user-db

### Scenario 3: Add to Cart
1. Select a product
2. Click "Add to Cart"
3. **Expected trace**: front-end → carts → carts-db

### Scenario 4: Complete Purchase
1. Go to cart
2. Proceed to checkout
3. Complete order
4. **Expected trace**: front-end → orders → [shipping, payment, orders-db]

## 🔗 Useful Links

- **Sock Shop**: http://localhost
- **SigNoz UI**: http://localhost:3301
- **Zipkin UI**: http://localhost:9411 (optional, for debugging)

## 📝 Next Steps

To get **complete end-to-end traces** including Go and Node.js services, you would need to:

1. Add OpenTelemetry SDK to the Go services
2. Add OpenTelemetry SDK to the Node.js front-end
3. Rebuild the Docker images with instrumentation

For now, you'll get excellent trace coverage of:
- ✅ Order flows (orders service)
- ✅ Shopping cart operations (carts service)
- ✅ Shipping operations (shipping service)
- ✅ Inter-service communication between Java services

## 🎓 Learning Resources

- [SigNoz Documentation](https://signoz.io/docs/)
- [OpenTelemetry Go](https://opentelemetry.io/docs/instrumentation/go/)
- [OpenTelemetry JavaScript](https://opentelemetry.io/docs/instrumentation/js/)
- [Spring Boot + Zipkin](https://spring.io/projects/spring-cloud-sleuth)

