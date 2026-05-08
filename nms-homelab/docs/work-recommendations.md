# Work Recommendations

These are the items worth carrying into the work environment after proving them in the lab.

## Monitoring Platform

- Use LibreNMS Dispatcher with Redis cache as the baseline scheduler model.
- Add RRDCached before enabling distributed pollers or scaling polling volume.
- Enable distributed pollers only when there is a real latency, geography, or scale need.
- Keep Docker stack definitions, example env files, and operating notes in Git.

## Config Backup

- Keep Oxidized integrated with LibreNMS.
- Use groups for device families, sites, or credential domains.
- Keep Oxidized output in Git, but treat the config repo separately from stack config if it will contain device configs.
- Rotate the Oxidized service password and LibreNMS API token after initial testing.

## Logs And Flow

- Keep Graylog as the central syslog/search layer.
- Use Akvorado for flow visibility once exporters are confirmed.
- Standardize exporter templates by platform, especially Aruba CX and edge/core routers.

## Alerts And Addons

- Configure alert transports for Teams, Slack, email, or webhook rather than relying only on the UI.
- Review SNMP trap handling; current LibreNMS behavior observed unhandled trap logging.
- Add service checks for high-value endpoints.
- Enable SSL certificate discovery/checking where useful.
- Consider SSO/MFA for the LibreNMS and Graylog admin surfaces.
