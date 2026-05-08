# ARR Stack Review Notes

## Host

- Host: `10.20.60.13`
- Hostname: `ddocker`
- User: `tberno`
- Active stack: `/opt/docker-stacks/arr-stack`

## Container State

At review time, these containers were running:

- `gluetun`: healthy
- `qbittorrent`: running behind Gluetun
- `sonarr`: running behind Gluetun
- `radarr`: running behind Gluetun
- `prowlarr`: running behind Gluetun
- `flaresolverr`: running behind Gluetun
- `plex`: separate stack/container, not included in this ARR backup pass

## Network Design

Gluetun is the root network service. qBittorrent, Sonarr, Radarr, Prowlarr, and FlareSolverr use `network_mode: "service:gluetun"`. This is the right pattern for forcing application egress through the VPN container. App ports are published on Gluetun.

## Preserved In Git

- `docker-compose.yml`
- `.env.example`
- qBittorrent lightweight config examples
- Sonarr/Radarr/Prowlarr redacted `config.xml` examples
- Documentation and ignore rules

## Excluded From Git

- PIA credentials
- Arr API keys
- qBittorrent WebUI password hash
- SQLite databases
- Logs
- PID files
- App backup folders
- Download/media paths
- Prowlarr definition cache

## Follow-Ups

- Rotate the PIA password because it was visible during review.
- Rotate Sonarr, Radarr, and Prowlarr API keys if this repo will be shared or made public.
- Rotate qBittorrent WebUI password if it was reused elsewhere.
- Decide whether the ARR backup should live in the same `J3ST3L2/Docker` repo under `arr-homelab/`.
- Consider pinning image versions instead of using `latest` once the stack is stable.
