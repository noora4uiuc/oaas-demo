#!/bin/bash

# Health Check Script for OaaS Demo (SockShop + SigNoz)
# This script checks if all critical services are running properly

set -e

echo "🔍 Checking OaaS Demo Health..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a port is open
check_port() {
    local port=$1
    local service=$2
    if nc -z localhost $port 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $service (port $port) is accessible"
        return 0
    else
        echo -e "${RED}✗${NC} $service (port $port) is NOT accessible"
        return 1
    fi
}

# Function to check HTTP endpoint
check_http() {
    local url=$1
    local service=$2
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|301\|302"; then
        echo -e "${GREEN}✓${NC} $service is responding at $url"
        return 0
    else
        echo -e "${RED}✗${NC} $service is NOT responding at $url"
        return 1
    fi
}

# Check if Docker Compose is running
echo "📦 Checking Docker Compose services..."
if ! docker compose ps &>/dev/null; then
    echo -e "${RED}✗${NC} Docker Compose is not running or no services are up"
    echo "Run: docker compose up -d"
    exit 1
fi

# Count running services
RUNNING=$(docker compose ps --filter "status=running" --format json 2>/dev/null | wc -l | tr -d ' ')
TOTAL=$(docker compose ps --format json 2>/dev/null | wc -l | tr -d ' ')
echo -e "${GREEN}✓${NC} Docker Compose: $RUNNING/$TOTAL services running"
echo ""

# Check critical SigNoz services
echo "🔍 Checking SigNoz Services..."
check_port 3301 "SigNoz UI"
check_port 4317 "OTLP gRPC Receiver"
check_port 4318 "OTLP HTTP Receiver"
check_port 9411 "Zipkin Receiver"
echo ""

# Check SockShop services
echo "🔍 Checking SockShop Services..."
check_port 80 "SockShop Store"
check_port 8080 "SockShop Alt Port"
check_port 8079 "Front-end Service"
echo ""

# Check HTTP endpoints
echo "🌐 Checking HTTP Endpoints..."
check_http "http://localhost:3301" "SigNoz UI"
check_http "http://localhost" "SockShop Store"
check_http "http://localhost:8079" "SockShop Front-end"
echo ""

# Check specific container health
echo "🏥 Checking Container Health..."
CONTAINERS=(
    "signoz-clickhouse:ClickHouse Database"
    "signoz:SigNoz Application"
    "signoz-otel-collector:OTel Collector"
    "carts:Carts Service"
    "orders:Orders Service"
    "shipping:Shipping Service"
)

for container_info in "${CONTAINERS[@]}"; do
    IFS=: read -r container name <<< "$container_info"
    if docker compose ps "$container" --format json 2>/dev/null | grep -q "running"; then
        health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-healthcheck")
        if [ "$health" = "healthy" ] || [ "$health" = "no-healthcheck" ]; then
            echo -e "${GREEN}✓${NC} $name is running"
        else
            echo -e "${YELLOW}⚠${NC} $name is running but health is: $health"
        fi
    else
        echo -e "${RED}✗${NC} $name is NOT running"
    fi
done
echo ""

# Check if traces are being collected
echo "📊 Checking Trace Collection..."
if curl -s http://localhost:9411/api/v2/services 2>/dev/null | grep -q "\["; then
    echo -e "${GREEN}✓${NC} Zipkin endpoint is responding"
    SERVICES=$(curl -s http://localhost:9411/api/v2/services 2>/dev/null | jq -r '.[]' 2>/dev/null | wc -l | tr -d ' ')
    if [ "$SERVICES" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} $SERVICES service(s) reporting traces"
    else
        echo -e "${YELLOW}⚠${NC} No services reporting traces yet (may take 1-2 min)"
    fi
else
    echo -e "${RED}✗${NC} Zipkin endpoint not responding"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Access Points:"
echo "   SockShop Store:  http://localhost"
echo "   SigNoz UI:       http://localhost:3301"
echo ""
echo "🔧 Useful Commands:"
echo "   View logs:       docker compose logs -f"
echo "   Restart:         docker compose restart"
echo "   Stop:            docker compose down"
echo ""

# Check if everything is OK
ALL_OK=true
for port in 80 3301 4317 9411; do
    if ! nc -z localhost $port 2>/dev/null; then
        ALL_OK=false
        break
    fi
done

if [ "$ALL_OK" = true ]; then
    echo -e "${GREEN}✓ All critical services are running!${NC}"
    echo ""
    echo "🎉 System is ready to use!"
    exit 0
else
    echo -e "${YELLOW}⚠ Some services are not fully ready yet${NC}"
    echo ""
    echo "💡 Tips:"
    echo "   - Wait 2-3 minutes for all services to start"
    echo "   - Check logs: docker compose logs -f"
    echo "   - Verify resources: docker system df"
    exit 1
fi

