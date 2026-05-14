# Akvorado Notes

## Access

- Console: `http://10.20.60.15:8081`
- Private Traefik endpoint: `127.0.0.1:8080`
- NetFlow v5/v9: `2055/udp`
- IPFIX: `4739/udp`
- sFlow: `6343/udp`
- BMP: `10179/tcp`

## Current Lab Config

- Akvorado image: `quay.io/akvorado/akvorado:2.3.0`
- Kafka image: `apache/kafka:4.2.0`
- ClickHouse image: `clickhouse/clickhouse-server:26.3`
- Valkey image: `valkey/valkey:9.0`
- Traefik image: `traefik:v3.6`

## Verification Commands

```bash
cd /opt/docker/akvorado
docker compose ps
curl -fsSI http://127.0.0.1:8081/
docker exec akvorado-kafka-1 /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic flows-v5
docker exec akvorado-kafka-1 /opt/kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell --bootstrap-server localhost:9092 --topic flows-v5
```

If Kafka offsets stay empty, Akvorado is ready but no exporters are sending usable flow records.
