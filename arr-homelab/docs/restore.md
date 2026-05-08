# ARR Stack Restore

## Restore Shape

1. Create the host directory:

```bash
sudo mkdir -p /opt/docker-stacks/arr-stack
```

2. Copy `docker-compose.yml` and create a real `.env` from `.env.example`.

3. Recreate the config directories:

```bash
mkdir -p config/gluetun config/qbittorrent config/sonarr config/radarr config/prowlarr
```

4. Restore application databases from private backups if available. The GitHub copy only stores redacted examples, not live databases.

5. Start the stack:

```bash
docker compose up -d
```

6. Verify Gluetun is healthy:

```bash
docker logs --tail 80 gluetun
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

## Important

Because qBittorrent, Sonarr, Radarr, Prowlarr, and FlareSolverr share Gluetun networking, application ports must be published on the Gluetun service, not on the individual app services.
