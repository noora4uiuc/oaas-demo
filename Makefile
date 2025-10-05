.PHONY: help up down restart logs health status clean clean-all test

# Default target
help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  OaaS Demo - SockShop + SigNoz Management"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Available commands:"
	@echo ""
	@echo "  make up          - Start all services"
	@echo "  make down        - Stop all services"
	@echo "  make restart     - Restart all services"
	@echo "  make logs        - View logs (all services)"
	@echo "  make health      - Check system health"
	@echo "  make status      - Show service status"
	@echo "  make clean       - Stop and remove containers"
	@echo "  make clean-all   - Stop and remove containers + volumes (RESETS DATA)"
	@echo "  make test        - Run load test"
	@echo ""
	@echo "Service-specific logs:"
	@echo "  make logs-signoz     - SigNoz application logs"
	@echo "  make logs-collector  - OTel Collector logs"
	@echo "  make logs-carts      - Carts service logs"
	@echo "  make logs-orders     - Orders service logs"
	@echo "  make logs-shipping   - Shipping service logs"
	@echo ""
	@echo "Quick access:"
	@echo "  make open-sockshop   - Open SockShop in browser"
	@echo "  make open-signoz     - Open SigNoz in browser"
	@echo ""

# Start all services
up:
	@echo "🚀 Starting all services..."
	docker compose up -d
	@echo ""
	@echo "⏱️  Waiting for services to be ready (this may take 2-3 minutes)..."
	@sleep 5
	@echo ""
	@echo "✅ Services are starting. Check status with: make health"
	@echo ""
	@echo "🌐 Access points:"
	@echo "   SockShop:  http://localhost"
	@echo "   SigNoz:    http://localhost:3301"

# Stop all services
down:
	@echo "🛑 Stopping all services..."
	docker compose down
	@echo "✅ All services stopped"

# Restart all services
restart:
	@echo "🔄 Restarting all services..."
	docker compose restart
	@echo "✅ Services restarted"

# View logs for all services
logs:
	docker compose logs -f

# View logs for specific services
logs-signoz:
	docker compose logs -f signoz

logs-collector:
	docker compose logs -f signoz-otel-collector

logs-carts:
	docker compose logs -f carts

logs-orders:
	docker compose logs -f orders

logs-shipping:
	docker compose logs -f shipping

logs-frontend:
	docker compose logs -f front-end

# Check system health
health:
	@./check-health.sh

# Show service status
status:
	@echo "📊 Service Status:"
	@echo ""
	@docker compose ps
	@echo ""
	@echo "💾 Volume Usage:"
	@docker volume ls | grep signoz

# Clean containers (keeps volumes)
clean:
	@echo "🧹 Cleaning up (keeping data volumes)..."
	docker compose down
	@echo "✅ Containers removed, data preserved"

# Clean everything including volumes
clean-all:
	@echo "⚠️  WARNING: This will remove all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "🧹 Removing all containers and volumes..."; \
		docker compose down -v; \
		echo "✅ Complete cleanup done"; \
	else \
		echo "Cancelled"; \
	fi

# Pull latest images
pull:
	@echo "📥 Pulling latest images..."
	docker compose pull
	@echo "✅ Images updated"

# Update and restart
update: pull down up
	@echo "✅ System updated and restarted"

# Run load test
test:
	@echo "🧪 Running load test..."
	@cd sockshop && ./run-load-test.sh

# Open SockShop in browser
open-sockshop:
	@echo "🌐 Opening SockShop..."
	@open http://localhost || xdg-open http://localhost

# Open SigNoz in browser
open-signoz:
	@echo "🌐 Opening SigNoz..."
	@open http://localhost:3301 || xdg-open http://localhost:3301

# Show resource usage
resources:
	@echo "💾 Docker Resource Usage:"
	@echo ""
	@docker system df
	@echo ""
	@echo "📊 Container Resource Usage:"
	@docker stats --no-stream

# Backup data
backup:
	@echo "💾 Creating backup..."
	@mkdir -p backups
	@docker run --rm -v signoz-clickhouse:/data -v $(PWD)/backups:/backup alpine tar czf /backup/clickhouse-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz /data
	@docker run --rm -v signoz-sqlite:/data -v $(PWD)/backups:/backup alpine tar czf /backup/sqlite-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz /data
	@echo "✅ Backup created in ./backups/"

# Quick start (for first time)
quickstart: up
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  🎉 Quick Start Complete!"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "📖 Next Steps:"
	@echo ""
	@echo "1. Wait 2-3 minutes for services to be ready"
	@echo "   Check status: make health"
	@echo ""
	@echo "2. Open SockShop store:"
	@echo "   http://localhost"
	@echo ""
	@echo "3. Browse, shop, and checkout to generate traces"
	@echo ""
	@echo "4. Open SigNoz (create admin account on first visit):"
	@echo "   http://localhost:3301"
	@echo ""
	@echo "5. View traces in SigNoz:"
	@echo "   Navigate to Services → Traces"
	@echo ""
	@echo "📚 More commands: make help"
	@echo ""

