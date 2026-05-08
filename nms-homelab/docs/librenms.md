# LibreNMS Notes

## Current State

- LibreNMS container updated to `librenms/librenms:latest`.
- Redis cache configured with `CACHE_STORE=redis`.
- Dispatcher sidecar active with `DISPATCHER_NODE_ID=dispatcher1`.
- Oxidized integration enabled with `ENABLE_OXIDIZED=1` and `OXIDIZED_URL=http://127.0.0.1:8888`.

## Known Issue

LibreNMS validation still reports a database schema issue caused by lower-case table names where LibreNMS expects camelCase names. A database backup exists on the server:

```text
/var/lib/mysql/backups/librenms-20260507-233252.sql.gz
```

Do not run destructive schema cleanup during normal operations. Handle this in a maintenance window after a fresh backup and a tested restore path.
