const express = require('express');
const { Kafka } = require('kafkajs');
const { Client } = require('@elastic/elasticsearch');
const client = require('prom-client');
const winston = require('winston');

// TODO: maybe move these to a config file later
const KAFKA_BROKER = process.env.KAFKA_BROKER || 'localhost:9092';
const ELASTICSEARCH_URL = process.env.ELASTICSEARCH_URL || 'http://localhost:9200';
const PROMETHEUS_PORT = process.env.PROMETHEUS_PORT || 8080;

// yeah, globals aren't great but this works for now
let retryCount = 0;

// Configure Winston logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: '/app/logs/consumer.log' })
  ]
});

// Initialize Prometheus metrics
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Custom metrics for database operations
const dbOperationCounter = new client.Counter({
  name: 'tidb_cdc_operations_total',
  help: 'Total number of TiDB CDC operations processed',
  labelNames: ['table_name', 'operation_type'],
  registers: [register]
});

const cdcEventsProcessed = new client.Counter({
  name: 'cdc_events_processed_total',
  help: 'Total number of CDC events processed',
  registers: [register]
});

const cdcEventsErrors = new client.Counter({
  name: 'cdc_events_errors_total',
  help: 'Total number of CDC event processing errors',
  registers: [register]
});

// Initialize Kafka client
const kafka = new Kafka({
  clientId: 'cdc-consumer',
  brokers: [KAFKA_BROKER],
  retry: {
    initialRetryTime: 100,
    retries: 8
  }
});

// Initialize Elasticsearch client
const esClient = new Client({
  node: ELASTICSEARCH_URL
});

// Express app for metrics endpoint
const app = express();

app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.end(metrics);
  } catch (error) {
    logger.error('Error generating metrics:', error);
    res.status(500).end('Error generating metrics');
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Create Elasticsearch index
async function createElasticsearchIndex() {
  try {
    const indexExists = await esClient.indices.exists({ index: 'cdc-events' });

    if (!indexExists) {
      await esClient.indices.create({
        index: 'cdc-events',
        body: {
          mappings: {
            properties: {
              '@timestamp': { type: 'date' },
              table_name: { type: 'keyword' },
              operation_type: { type: 'keyword' },
              database: { type: 'keyword' },
              data: { type: 'object' },
              old_data: { type: 'object' },
              sql_type: { type: 'object' },
              mysql_type: { type: 'object' },
              pk_names: { type: 'keyword' }
            }
          }
        }
      });
      logger.info('Created Elasticsearch index: cdc-events');
    }
  } catch (error) {
    logger.error('Error creating Elasticsearch index:', error);
  }
}

// Process CDC message - this was a pain to debug initially
async function processCDCMessage(message) {
  try {
    const messageValue = JSON.parse(message.value.toString());

    // console.log('Raw message:', messageValue); // uncomment for debugging

    // Canal JSON format - took me a while to figure this structure out
    if (messageValue.data && Array.isArray(messageValue.data)) {
      for (const record of messageValue.data) {
        const cdcEvent = {
          '@timestamp': new Date().toISOString(),
          table_name: messageValue.table || 'unknown',
          operation_type: messageValue.type || 'unknown',
          database: messageValue.database || 'unknown',
          data: record,
          old_data: messageValue.old ? messageValue.old[messageValue.data.indexOf(record)] : null,
          sql_type: messageValue.sqlType || {},
          mysql_type: messageValue.mysqlType || {},
          pk_names: messageValue.pkNames || []
        };

        // Send to Elasticsearch
        await esClient.index({
          index: 'cdc-events',
          body: cdcEvent
        });

        // Update Prometheus metrics
        dbOperationCounter.inc({
          table_name: cdcEvent.table_name,
          operation_type: cdcEvent.operation_type
        });

        cdcEventsProcessed.inc();

        logger.info('Processed CDC event:', {
          table: cdcEvent.table_name,
          operation: cdcEvent.operation_type,
          timestamp: cdcEvent['@timestamp']
        });
      }
    }
  } catch (error) {
    logger.error('Error processing CDC message:', error);
    // console.error('Full error:', error); // uncomment if you need more details
    cdcEventsErrors.inc();
  }
}

// Start Kafka consumer
async function startConsumer() {
  const consumer = kafka.consumer({ groupId: 'cdc-consumer-group' });

  try {
    await consumer.connect();
    logger.info('Connected to Kafka');

    // Subscribe to CDC events topic
    await consumer.subscribe({ topic: 'cdc-events', fromBeginning: false });
    logger.info('Subscribed to cdc-events topic');

    await consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        logger.debug(`Received message from topic ${topic}, partition ${partition}`);
        await processCDCMessage(message);
      },
    });

  } catch (error) {
    logger.error('Error in Kafka consumer:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('Received SIGTERM, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', async () => {
  logger.info('Received SIGINT, shutting down gracefully');
  process.exit(0);
});

// Main function
async function main() {
  try {
    logger.info('Starting CDC Consumer Application');

    // Wait for dependencies - learned this the hard way
    logger.info('Waiting for dependencies to be ready...');
    await new Promise(resolve => setTimeout(resolve, 30000)); // 30s should be enough, right?

    // Initialize Elasticsearch
    await createElasticsearchIndex();

    // Start Kafka consumer
    await startConsumer();

    // Start metrics server
    app.listen(PROMETHEUS_PORT, () => {
      logger.info(`Metrics server listening on port ${PROMETHEUS_PORT}`);
    });

  } catch (error) {
    logger.error('Error starting application:', error);
    process.exit(1);
  }
}

main();