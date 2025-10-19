#!/bin/bash
set -e

echo "Starting TiCDC server..."

# Start TiCDC server in background with proper flags
/cdc server \
    --addr=0.0.0.0:8300 \
    --advertise-addr=ticdc:8300 \
    --pd=http://pd0:2379 \
    --log-file=/dev/stdout \
    --log-level=info \
    --config=/ticdc-config.toml &

# Wait for TiCDC server to be ready - this can take a while
echo "Waiting for TiCDC server to be ready..."
sleep 30

# Check if TiCDC server is ready using CLI commands
for i in {1..30}; do
    if /cdc cli capture list --server=http://localhost:8300 > /dev/null 2>&1; then
        echo "TiCDC server is ready!"
        break
    fi
    echo "TiCDC server not ready yet, waiting... ($i/30)"
    sleep 5
done

# Create CDC changefeed with minimal configuration
echo "Creating changefeed to Kafka..."
/cdc cli changefeed create \
    --pd=http://pd0:2379 \
    --sink-uri="kafka://kafka:9092/cdc-events?protocol=canal-json&partition-num=1" \
    --changefeed-id="kafka-changefeed"

echo "Changefeed created successfully!"

# Keep the container running
wait