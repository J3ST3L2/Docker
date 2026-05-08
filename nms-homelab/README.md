# NMS Homelab

Docker-based monitoring stack for the home lab:

- LibreNMS with MariaDB, Redis, Dispatcher, and Oxidized integration.
- Oxidized network config backup with Git storage.
- Graylog standalone stack upgraded to 7.1.
- Akvorado 2.3 flow collector/search stack with Kafka, ClickHouse, Valkey, and Traefik.

This repo stores sanitized configuration and operating notes only. Runtime data, backups, database dumps, GeoIP databases, and secrets are intentionally excluded.

## Current Status

- LibreNMS: updated to `librenms/librenms:latest`, currently 26.4.1 during the review.
- LibreNMS Dispatcher: running with Redis cache.
- Oxidized: running after removing an unsupported HTTP hook.
- Graylog: upgraded from 5.x to 7.1; MongoDB is 7.0 with FCV 7.0.
- Akvorado: rebuilt and running on `http://10.20.60.15:8081`; listener ports are `2055/udp`, `4739/udp`, and `6343/udp`.

## Before Deploying

Create stack-local `.env` files with real secrets. Do not commit them.

Required values include:

- `MYSQL_ROOT_PASSWORD`
- `MYSQL_PASSWORD`
- `GRAYLOG_PASSWORD_SECRET`
- `GRAYLOG_ROOT_PASSWORD_SHA2`
- `OXIDIZED_USERNAME`
- `OXIDIZED_PASSWORD`
- `LIBRENMS_API_TOKEN`
- `AKVORADO_SNMP_COMMUNITY`

## Repo Layout

- `stacks/nms-stack/`: LibreNMS, Redis, MariaDB, Oxidized, and disabled legacy embedded Graylog services.
- `stacks/nms-stack/oxidized/config.example`: redacted Oxidized config.
- `stacks/graylog-stack/`: standalone Graylog stack.
- `stacks/akvorado/`: Akvorado stack and config.
- `docs/`: review notes, upgrade notes, and work recommendations.
