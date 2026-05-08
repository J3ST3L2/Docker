# ARR Homelab Stack

Docker Compose backup for the ARR/qBittorrent/Gluetun stack on `10.20.60.13`.

This repository folder stores sanitized stack configuration and lightweight app examples. Runtime databases, logs, downloads, app backup folders, API keys, WebUI password hashes, and VPN credentials are intentionally excluded.

## Services

- Gluetun with Private Internet Access over OpenVPN.
- qBittorrent behind Gluetun network namespace.
- Sonarr behind Gluetun.
- Radarr behind Gluetun.
- Prowlarr behind Gluetun.
- FlareSolverr behind Gluetun.

## Current Layout

```text
/opt/docker-stacks/arr-stack
```

The active Compose file publishes application ports from the Gluetun container because the other services use `network_mode: "service:gluetun"`.

## Published Ports

- `8080/tcp`: qBittorrent WebUI
- `8989/tcp`: Sonarr
- `7878/tcp`: Radarr
- `9696/tcp`: Prowlarr
- `8191/tcp`: FlareSolverr

## Before Deploying

Create a local `.env` file next to `docker-compose.yml`:

```env
PIA_USER=your-username
PIA_PASS=your-password
```

Do not commit real VPN credentials or app API keys.
