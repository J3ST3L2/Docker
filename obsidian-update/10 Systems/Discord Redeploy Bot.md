---
tags:
  - system
  - discord
  - automation
  - secrets
  - homelab
---
# Discord Redeploy Bot

Related: [[Ansible Control Node]], [[1Password Secrets]], [[Homelab Secret Rotation And Redeploy]], [[Discord Bot Operations]]

## Role

The Discord redeploy bot gives a controlled way to test secret rendering and redeploy homelab stacks from Discord. It runs only fixed scripts and only accepts commands from the allowlisted Discord user.

## Location

- Host: [[Ansible Control Node]]
- Address: `10.20.60.19`
- Service: `homelab-discord-bot.service`
- Install path: `/opt/homelab-discord-bot`

## Discord App

- App name: `alerts-platform-bot`
- Logged-in bot at setup time: `alerts-platform-bot#4163`
- Bot application ID at setup time: `1500973421331353660`
- Allowlisted Discord user ID: `1399736899551101056`

## Token Source

The bot token is stored in 1Password:

```text
op://JesterTek/Discord Bot/DISCORD_BOT_TOKEN
```

The service reads the token at startup using:

```text
/etc/1password/jestertek-readonly.token
```

## Commands

Safe test commands:

```text
/secrets-test target:arr
/secrets-test target:nms
/secrets-test target:graylog
/secrets-test target:akvorado
```

Redeploy commands:

```text
/redeploy target:arr
/redeploy target:nms
/redeploy target:graylog
/redeploy target:akvorado
```

Media add commands:

```text
/sonarr query:severance
/radarr query:interstellar 2014
```

These are restricted to:

- The configured media download channel ID.

Anyone in the configured media download channel can use the media add commands. Admin commands remain restricted to the allowlisted Discord user ID.

Required environment:

```text
MEDIA_CHANNEL_ID=1499582440971436082
DISCORD_GUILD_ID=1440378706257383428
SONARR_URL=http://10.20.60.13:8989
RADARR_URL=http://10.20.60.13:7878
SONARR_ROOT_FOLDER=/tv
RADARR_ROOT_FOLDER=/movies
SONARR_QUALITY_PROFILE_ID=1
RADARR_QUALITY_PROFILE_ID=1
```

Secrets are read from 1Password:

```text
op://JesterTek/ARR Stack/SONARR_API_KEY
op://JesterTek/ARR Stack/RADARR_API_KEY
```

## Script Paths

```text
/opt/homelab-discord-bot/scripts/test-arr.sh
/opt/homelab-discord-bot/scripts/test-nms.sh
/opt/homelab-discord-bot/scripts/test-graylog.sh
/opt/homelab-discord-bot/scripts/test-akvorado.sh
/opt/homelab-discord-bot/scripts/redeploy-arr.sh
/opt/homelab-discord-bot/scripts/redeploy-nms.sh
/opt/homelab-discord-bot/scripts/redeploy-graylog.sh
/opt/homelab-discord-bot/scripts/redeploy-akvorado.sh
```

## Verified State

The service was enabled and running after setup. Secret render tests passed for all four targets:

```text
ARR secret render OK
NMS secret render OK
Graylog secret render OK
Akvorado secret render OK
```

The user also confirmed the Discord test appeared to work.

## Operational Notes

The bot uses guild-scoped command sync with `DISCORD_GUILD_ID` so command changes appear quickly in the configured Discord server. Stale global commands were cleared after media commands were added, because duplicate global and guild commands showed two `/sonarr` entries in the command picker.

Media commands add the item, trigger ARR search, then poll ARR queue/history briefly. Expected replies include:

```text
`Title` is in the download queue: downloading, WEBDL-1080p.
`Title` was grabbed by search: WEBDL-1080p.
`Title` was added and searched, but no download was grabbed yet.
```

The bot should stay limited to fixed scripts. Avoid adding arbitrary shell execution through Discord.
