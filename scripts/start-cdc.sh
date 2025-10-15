#!/bin/bash
set -e

echo "Starting TiCDC server..."

# Start TiCDC server in background
/cdc server --config=/ticdc-config.toml &

# Wait for TiCDC server to be ready - this can take a while
echo "Waiting for TiCDC server to be ready..."
while ! curl -f http://localhost:8300/status > /dev/null 2>&1; do
    sleep 2
    echo "Still waiting for TiCDC server..."
done

echo "TiCDC server is ready!"

# Create CDC changefeed
echo "Creating changefeed to Kafka..."
/cdc cli changefeed create \
    --pd=http://pd0:2379 \
    --sink-uri="kafka://kafka:9092/cdc-events?protocol=canal-json&partition-num=1" \
    --changefeed-id="kafka-changefeed" \
    --config=/dev/stdin << 'EOF'
{
    "filter": {
        "rules": ["*.*"]
    },
    "sink": {
        "protocol": "canal-json",
        "dispatchers": [
            {
                "matcher": ["*.*"],
                "topic": "cdc-events",
                "partition": "default"
            }
        ]
    }
}
EOF

echo "Changefeed created successfully!"

# Keep the container running
wait