# DevOps Assignment TODO List

## Assignment Overview
**Time Limit**: 3.5 hours
**Goal**: Build complete ecosystem with TiDB, CDC monitoring, Kafka messaging, and observability stack
**Deliverable**: Single `docker-compose up` command to run everything

---

## Part 1: TiDB Implementation

### ✅ Database & Infrastructure Setup
- [ ] Set up project structure and initialize Git repository
- [ ] Create docker-compose.yml with TiDB cluster setup
- [ ] Configure Apache Kafka brokers in Docker
- [ ] Create database schema and seed files for auto-initialization

### ✅ Change Data Capture (CDC)
- [ ] Configure TiDB CDC component in docker-compose
- [ ] Ensure CDC task auto-starts when Docker environment loads
- [ ] Test CDC captures all database operations (insert/update/delete)

---

## Part 2: Monitoring & Logging

### ✅ Real-time Data Processing
- [ ] Write Node.js consumer application for Kafka messages
- [ ] Integrate Prometheus metrics in Node.js app
  - Counter with dimensions: tablename, operation (insert/update/delete)

### ✅ Observability Stack
- [ ] Set up Elasticsearch and Filebeat for log collection
- [ ] Configure Prometheus and Grafana in Docker
- [ ] Create Grafana dashboards with auto-configuration:
  - Raw CDC events list (from Elasticsearch)
  - Pie chart: 1-hour operations by type (from Prometheus)

---

## Final Steps

### ✅ Documentation & Testing
- [ ] Write comprehensive README.md with setup instructions
- [ ] Test complete system with `docker-compose up`
- [ ] Verify all components are working together
- [ ] Prepare for follow-up interview questions

---

## Key Components Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    TiDB     │────│   CDC       │────│   Kafka     │
│  Database   │    │ Component   │    │   Broker    │
└─────────────┘    └─────────────┘    └─────────────┘
                                              │
                                              ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Grafana   │────│ Prometheus  │────│   Node.js   │
│ Dashboard   │    │  Metrics    │    │  Consumer   │
└─────────────┘    └─────────────┘    └─────────────┘
       │                                      │
       ▼                                      ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│Elasticsearch│────│  Filebeat   │────│    Logs     │
│   Search    │    │ Collector   │    │   Output    │
└─────────────┘    └─────────────┘    └─────────────┘
```

---

## Success Criteria
- [x] All services start with single command
- [ ] Database changes are captured by CDC
- [ ] Kafka messages are consumed and processed
- [ ] Prometheus metrics are collected
- [ ] Grafana dashboards display real-time data
- [ ] Elasticsearch stores and searches CDC events