#!/bin/bash

# Quick script to start everything
# Usage: ./run.sh

echo "Starting the TiDB CDC monitoring stack..."
echo "This will take a few minutes..."

# Check if docker-compose exists
if ! command -v docker-compose &> /dev/null; then
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker not found. Please install Docker first."
        exit 1
    fi
    # Use docker compose instead
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# Start everything
$COMPOSE_CMD up -d

echo ""
echo "Services starting up..."
echo "Check status with: $COMPOSE_CMD ps"
echo "View logs with: $COMPOSE_CMD logs -f"
echo ""
echo "Once everything is up (2-3 minutes), access:"
echo "  Grafana: http://localhost:3000 (admin/admin123)"
echo "  Prometheus: http://localhost:9090"
echo "  Elasticsearch: http://localhost:9200"
echo ""
echo "Happy monitoring! 🚀"