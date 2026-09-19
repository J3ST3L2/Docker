# UniFi Network - Docker 2

Containerized UniFi Network Application for the homelab.

## What this manages

This stack manages UniFi Network devices such as access points and switches.

It does **not** run UniFi Protect. Ubiquiti does not support self-hosting Protect, and the newer UniFi OS Server is not available as a standalone Docker/Podman container. Protect should remain on a supported UniFi console/NVR.

## Deployment target

- Host: Docker 2
- Host IP: `10.20.60.17`
- Stack path: `/opt/docker-stacks/unifi-network`
- Web UI: `https://10.20.60.17:8443`
- UniFi inform: `http://10.20.60.17:8081/inform`
- Database: MongoDB 8.0, reachable only on the private Compose network

## Non-default inform port

Alerta already uses TCP/8080 on Docker 2, so this deployment moves UniFi device communication to TCP/8081.

This is not implemented as a simple Docker `8081:8080` translation. UniFi must itself listen on and advertise the changed inform port. The `unifi-config-init` service maintains these values in `/config/data/system.properties` before the Network application starts:

```text
unifi.http.port=8081
system_ip=10.20.60.17
```

The application container therefore publishes `8081:8081`.

## Files

- `compose.yaml` - UniFi Network + MongoDB + configuration initializer
- `.env.example` - host settings and secret placeholders
- `init-mongo.sh` - first-run MongoDB user/database initialization
- `data/` - runtime state created locally and ignored by Git

## First deployment

Copy this stack to `/opt/docker-stacks/unifi-network`, then:

```bash
cd /opt/docker-stacks/unifi-network

cp .env.example .env

ROOT_PASS="$(openssl rand -hex 32)"
UNIFI_PASS="$(openssl rand -hex 32)"

sed -i "s|MONGO_ROOT_PASSWORD=CHANGE_ME_GENERATE_WITH_OPENSSL|MONGO_ROOT_PASSWORD=${ROOT_PASS}|" .env
sed -i "s|MONGO_PASS=CHANGE_ME_GENERATE_WITH_OPENSSL|MONGO_PASS=${UNIFI_PASS}|" .env

unset ROOT_PASS UNIFI_PASS

mkdir -p data/mongodb data/unifi

docker compose config
docker compose pull
docker compose up -d

docker compose ps
```

Then open:

```text
https://10.20.60.17:8443
```

A browser certificate warning is expected during the initial setup.

## Required network access

Allow UniFi devices to reach Docker 2 at `10.20.60.17` on:

| Port | Protocol | Purpose |
|---|---|---|
| 8081 | TCP | Device inform/adoption |
| 3478 | UDP | STUN |
| 10001 | UDP | Device discovery |
| 8443 | TCP | Admin UI |

MongoDB port 27017 is intentionally **not** published on the host.

## AP adoption across VLANs

Layer-2 discovery will not cross routed VLANs.

For an AP on another VLAN, SSH to the AP and set its controller:

```bash
set-inform http://10.20.60.17:8081/inform
```

After the AP appears in UniFi and you click Adopt, run the same `set-inform` command again if adoption does not finish immediately.

## Logs and status

```bash
cd /opt/docker-stacks/unifi-network

docker compose ps
docker compose logs --tail=100 unifi-db
docker compose logs --tail=100 unifi-network-application
```

## Updating

Update intentionally:

```bash
cd /opt/docker-stacks/unifi-network
docker compose pull
docker compose up -d
docker image prune
```

MongoDB is pinned to the 8.0 release family rather than `latest`.

## Backup

The important state is:

```text
data/unifi/
data/mongodb/
```

Also maintain a UniFi Network backup/export for migration and recovery.

## References

- Ubiquiti self-hosting: https://help.ui.com/hc/en-us/articles/34210126298775-Self-Hosting-UniFi
- Ubiquiti system.properties: https://help.ui.com/hc/en-us/articles/205202580-Explaining-the-UniFi-system-properties-File
- LinuxServer UniFi Network Application: https://docs.linuxserver.io/images/docker-unifi-network-application/
