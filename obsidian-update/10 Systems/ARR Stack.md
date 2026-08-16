---
tags:
  - system
  - arr
  - docker
  - homelab
---
# ARR Stack

Related: [[1Password Secrets]], [[Discord Redeploy Bot]], [[Homelab GitHub Repos]], [[Homelab Secret Rotation And Redeploy]]

## Role

The ARR stack runs media automation and torrent traffic through Gluetun. Configuration has been sanitized and backed up to GitHub, while runtime secrets are pulled from 1Password.

## Host

- Address: `10.20.60.13`
- User: `tberno`
- Stack path: `/opt/docker-stacks/arr-stack`
- Compose style: Docker Compose

## Main Containers

- `gluetun`
- `qbittorrent`
- `sonarr`
- `radarr`
- `prowlarr`
- `flaresolverr`
- Plex is separate from the ARR Compose stack.

## Discord-Controlled Adds

The existing [[Discord Redeploy Bot]] can expose media commands:

```text
/sonarr query:show name
/radarr query:movie name and year
```

The bot restricts these commands to the configured media channel ID. Anyone in that Discord channel can use the media add commands; admin redeploy commands remain limited to the allowlisted Discord user.

The bot calls the internal Sonarr/Radarr APIs through the ARR host published ports. After adding an item, it starts a search and checks ARR queue/history so Discord can report whether the request was queued, grabbed, or added without a matching release.

## Secret Source

1Password item:

```text
op://JesterTek/ARR Stack
```

Runtime token:

```text
/etc/1password/arr-stack.token
```

Render script:

```text
/opt/docker-stacks/arr-stack/scripts/render-arr-env.sh
/opt/docker-stacks/arr-stack/scripts/render-arr-app-secrets.sh
```

Runtime env file:

```text
/run/arr-stack.env
```

## GitHub Backup

Sanitized backup lives under the `arr-homelab` folder in the GitHub Docker repo. It includes Compose files, examples, redacted configs, render scripts, and notes. It should not include live `.env` files or real credentials.

## Redeploy Flow

1. Discord command runs on [[Ansible Control Node]].
2. Bot SSHes to `10.20.60.13`.
3. ARR render script pulls secrets from 1Password.
4. ARR app-secret render script updates only secret-bearing app config fields.
5. Docker Compose runs with `/run/arr-stack.env`.
6. Temporary env file is removed.

## 1Password Managed Fields

The `ARR Stack` item currently owns:

- `PIA_USER`
- `PIA_PASS`
- `SONARR_API_KEY`
- `RADARR_API_KEY`
- `PROWLARR_API_KEY`
- `QBITTORRENT_WEBUI_PASSWORD_PBKDF2`

The app-secret render script updates:

- Sonarr `config.xml` `ApiKey`
- Radarr `config.xml` `ApiKey`
- Prowlarr `config.xml` `ApiKey`
- qBittorrent `WebUI\Password_PBKDF2`

## Open Follow-Ups

- [[Rotate ARR Stack Credentials]]
- Confirm Gluetun provider settings after rotation.
- Confirm qBittorrent is still bound behind Gluetun after redeploy.

## Cutover

See [[ARR 1Password Cutover]] for the completed cutover status.
