# Graylog Notes

## Current State

- Graylog upgraded to 7.1.
- MongoDB upgraded to 7.0 with FCV 7.0.
- OpenSearch remains on 2.4.0 and was green after upgrade.
- Syslog UDP input was running after upgrade.

## Backup

Upgrade backup on the server:

```text
/opt/graylog-stack/backups/20260507-235826
```

## Follow-Up

Graylog logs still warn about the legacy config path under `/usr/share/graylog/data/config/graylog.conf`. Move config to the current `/usr/share/graylog/config/graylog.conf` mount style in a future cleanup.
