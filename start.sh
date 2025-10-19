#!/bin/bash

echo "Starting Helfy DevSecOps CDC Pipeline..."

# Clean any existing containers and networks
echo "Cleaning up existing containers..."
docker compose down -v --remove-orphans 2>/dev/null || true
docker rm -f ticdc 2>/dev/null || true

# Create and set permissions for data directories
echo "Setting up data directories with correct permissions..."
sudo rm -rf ./data/* 2>/dev/null || true
sudo mkdir -p ./data/{elasticsearch,grafana,prometheus,pd0,tikv0,kafka}
sudo chown -R 1000:1000 ./data/elasticsearch
sudo chown -R 472:472 ./data/grafana
sudo chown -R 65534:65534 ./data/prometheus

# Start all services
echo "Starting all services..."
docker compose up -d

# Wait for services to initialize
echo "Waiting for services to initialize (30s)..."
sleep 30

# Check service status
echo "Checking service status..."
echo "Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "Endpoints available:"
echo "- TiDB Database: http://localhost:4000"
echo "- TiCDC: http://localhost:8300"
echo "- Kafka: http://localhost:9092"
echo "- Consumer App: http://localhost:8080"
echo "- Elasticsearch: http://localhost:9200"
echo "- Prometheus: http://localhost:9090"
echo "- Grafana: http://localhost:3000 (admin:admin123)"

echo ""
echo "CDC Pipeline deployment complete!"
echo "Use 'docker compose logs -f [service-name]' to view logs"