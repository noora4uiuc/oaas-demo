# SigNoz Local Deployment

## 🎉 Deployment Status: SUCCESS

SigNoz has been successfully deployed locally on Docker for Mac!

## Access Information

- **SigNoz UI**: http://localhost:3301
- **OTLP gRPC Endpoint**: localhost:4317
- **OTLP HTTP Endpoint**: localhost:4318

## Running Services

1. **signoz** - Main SigNoz application (port 3301)
2. **signoz-otel-collector** - OpenTelemetry Collector (ports 4317, 4318)
3. **signoz-clickhouse** - ClickHouse database
4. **signoz-zookeeper-1** - ZooKeeper for coordination

## Useful Commands

### View running containers
```bash
cd /Users/alamn/Developer/oaas-demo/signoz/signoz/deploy/docker
docker compose ps
```

### View logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f signoz
docker compose logs -f otel-collector
```

### Stop SigNoz
```bash
cd /Users/alamn/Developer/oaas-demo/signoz/signoz/deploy/docker
docker compose down
```

### Start SigNoz (after stopping)
```bash
cd /Users/alamn/Developer/oaas-demo/signoz/signoz/deploy/docker
docker compose up -d
```

### Restart SigNoz
```bash
cd /Users/alamn/Developer/oaas-demo/signoz/signoz/deploy/docker
docker compose restart
```

### Remove SigNoz completely (including volumes)
```bash
cd /Users/alamn/Developer/oaas-demo/signoz/signoz/deploy/docker
docker compose down -v
```

## First Time Setup

⚠️ **IMPORTANT**: On first launch, you need to complete the setup:

1. **Open SigNoz UI**: Navigate to http://localhost:3301 in your browser
2. **Complete Registration**: You'll see a registration form to create the first admin user
3. **Create Admin Account**: Fill in your details to create the initial administrator account

> **Note**: If you see a login screen instead of registration, the setup was completed in a previous session. You'll need to use the credentials you created earlier, or reset the deployment with `docker compose down -v` and start fresh.

## Next Steps

1. **Access the UI**: Open http://localhost:3301 in your browser
2. **Generate Sample Data**: 
   ```bash
   # Generate sample traces with HotROD
   cd /Users/alamn/Developer/oaas-demo/signoz/signoz/deploy/docker/generator/hotrod
   docker compose up -d
   
   # Generate infrastructure metrics
   cd /Users/alamn/Developer/oaas-demo/signoz/signoz/deploy/docker/generator/infra
   docker compose up -d
   ```

3. **Instrument Your Application**: Configure your application to send telemetry data to:
   - OTLP gRPC: `http://localhost:4317`
   - OTLP HTTP: `http://localhost:4318`

## Configuration

The deployment configuration is located at:
- Main config: `/Users/alamn/Developer/oaas-demo/signoz/signoz/deploy/docker/docker-compose.yaml`
- Port changed from 8080 to 3301 (due to port conflict)

## Troubleshooting

If you encounter issues:

1. Check container logs: `docker compose logs -f`
2. Verify all containers are healthy: `docker compose ps`
3. Restart services: `docker compose restart`
4. Clean restart: `docker compose down && docker compose up -d`

## Documentation

For more information, visit:
- Official docs: https://signoz.io/docs/
- GitHub: https://github.com/SigNoz/signoz

