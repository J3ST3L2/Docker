# Operations Log

## 2026-05-07 / 2026-05-08

### Oxidized

- Found Oxidized crash-looping on `cannot load hook 'http', not found`.
- Backed up the existing config on the server.
- Removed the unsupported Discord/HTTP hook block.
- Restarted Oxidized successfully.
- Confirmed Git-backed device configs were being written under Oxidized storage.

### LibreNMS

- Updated LibreNMS containers to current `librenms/librenms:latest`.
- Recreated the main LibreNMS and Dispatcher containers.
- Added Redis cache configuration with `CACHE_STORE=redis`.
- Confirmed Dispatcher heartbeat and workers were active.
- Created database backup before any schema-risk work:
  `/var/lib/mysql/backups/librenms-20260507-233252.sql.gz`
- Left the database schema table-case issue unresolved for a maintenance window.

### Graylog

- Disabled the duplicate embedded Graylog services inside the NMS stack using Compose profiles.
- Upgraded standalone Graylog incrementally through supported versions to 7.1.
- Upgraded MongoDB to 7.0 and set FCV to 7.0.
- Kept OpenSearch at 2.4.0.
- Confirmed Graylog status `ALIVE`, OpenSearch green, and Syslog UDP input running.
- Backup location:
  `/opt/graylog-stack/backups/20260507-235826`

### Akvorado

- Found old Akvorado config remnants but no active containers or Compose stack.
- Rebuilt a current Akvorado layout under `/opt/docker/akvorado`.
- Preserved existing GeoIP databases on the host.
- Started Akvorado 2.3.0 with Kafka, ClickHouse, Valkey, Traefik, inlet, outlet, console, and orchestrator.
- Confirmed services healthy and UI responding on `http://10.20.60.15:8081`.
- Confirmed listener ports for NetFlow/IPFIX/sFlow are open.
- Kafka topic `flows-v5` exists, but no offsets were present at the time of review, so device exporters still need verification.
