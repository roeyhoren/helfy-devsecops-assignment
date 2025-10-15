# Debug Notes

## Common Issues I Ran Into

### TiCDC Won't Start
- Make sure TiDB is fully up before CDC tries to connect
- Check that Kafka is reachable from the CDC container
- The changefeed creation sometimes fails on first try, just restart the ticdc container

### No Events in Kafka
- Verify the changefeed is created: `docker exec ticdc /cdc cli changefeed list --pd=http://pd0:2379`
- Check TiDB logs for CDC-related errors
- Make sure you're actually making changes to the `helfy_db` database

### Consumer App Crashes
- Usually it's because Elasticsearch isn't ready yet
- Check the logs: `docker-compose logs consumer-app`
- The 30-second wait might not be enough if your machine is slow

### Grafana Shows No Data
- Check if Prometheus is scraping the consumer app: http://localhost:9090/targets
- Verify Elasticsearch has data: `curl http://localhost:9200/cdc-events/_search`
- Sometimes you need to wait a bit for data to show up

### Performance Issues
- This setup needs at least 6GB RAM to run smoothly
- If things are slow, try: `docker system prune -f`

## Useful Commands

```bash
# Check what's actually in Kafka
docker exec kafka /bin/kafka-console-consumer --bootstrap-server localhost:9092 --topic cdc-events --from-beginning

# See changefeed status
docker exec ticdc /cdc cli changefeed list --pd=http://pd0:2379

# Check Elasticsearch indices
curl "http://localhost:9200/_cat/indices?v"

# Consumer app metrics
curl "http://localhost:8080/metrics" | grep cdc
```

## TODO for Production
- [ ] Use proper secrets management instead of hardcoded passwords
- [ ] Add health checks to docker-compose
- [ ] Set up proper logging rotation
- [ ] Add backup strategy for data volumes
- [ ] Configure TLS for all services