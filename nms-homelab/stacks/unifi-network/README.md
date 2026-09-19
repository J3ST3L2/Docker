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

## Files

- `compose.yaml` - UniFi Network + MongoDB
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
| 8081 | TCP | Device inform/adoption (published to container port 8080) |
| 3478 | UDP | STUN |
| 10001 | UDP | Device discovery |
| 8443 | TCP | Admin UI |

MongoDB port 27017 is intentionally **not** published on the host.

## AP adoption across VLANs

Layer-2 discovery will not magically leap across routed VLANs because Ethernet remains stubbornly committed to physics.

For an AP on another VLAN, SSH to the AP and set its controller:

```bash
set-inform http://10.20.60.17:8081/inform
```

After the AP appears in UniFi and you click Adopt, run the same `set-inform` command again if adoption does not finish immediately.

Once the controller is running, set the UniFi **Inform Host Override** to:

```text
10.20.60.17
```

so adopted devices keep using the reachable host address instead of a Docker bridge address.

## Logs and status

```bash
cd /opt/docker-stacks/unifi-network

docker compose ps
docker compose logs --tail=100 unifi-db
docker compose logs --tail=100 unifi-network-application
```

Follow the UniFi log:

```bash
docker compose logs -f unifi-network-application
```

## Updating

Do not use an unattended auto-updater for this stack.

Update intentionally:

```bash
cd /opt/docker-stacks/unifi-network
docker compose pull
docker compose up -d
docker image prune
```

MongoDB is pinned to the 8.0 release family rather than `latest` to prevent an accidental major-version database upgrade.

## Backup

The important state is:

```text
data/unifi/
data/mongodb/
```

UniFi's own Network backup/export should also be enabled after initial setup. A UniFi application backup is the preferred migration/recovery artifact rather than treating a live MongoDB directory copy as a database backup.

## References

- Ubiquiti self-hosting: https://help.ui.com/hc/en-us/articles/34210126298775-Self-Hosting-UniFi
- LinuxServer UniFi Network Application image: https://docs.linuxserver.io/images/docker-unifi-network-application/
