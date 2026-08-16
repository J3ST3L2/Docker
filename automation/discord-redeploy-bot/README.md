# Homelab Discord Redeploy Bot

This bot provides allowlisted Discord slash commands for testing 1Password secret rendering, redeploying fixed homelab stacks, and adding media to Sonarr/Radarr from one approved channel.

## Runtime Host

```text
10.20.60.19:/opt/homelab-discord-bot
```

## Service

```text
homelab-discord-bot.service
```

## Secrets

The bot token is stored in 1Password:

```text
op://JesterTek/Discord Bot/DISCORD_BOT_TOKEN
```

The runtime host reads it through:

```text
/etc/1password/jestertek-readonly.token
```

## Commands

```text
/secrets-test target:arr
/secrets-test target:nms
/secrets-test target:graylog
/secrets-test target:akvorado
```

```text
/redeploy target:arr
/redeploy target:nms
/redeploy target:graylog
/redeploy target:akvorado
```

```text
/sonarr query:severance
/radarr query:interstellar 2014
```

The media commands are available to anyone in `MEDIA_CHANNEL_ID`.

After adding a Sonarr/Radarr item, the bot triggers search and checks queue/history. The Discord reply should report whether the item was queued, grabbed, or added without a matching release.

## Security Model

- Fixed scripts only.
- No arbitrary shell command execution.
- Admin commands are allowlisted by Discord user ID.
- Media add commands are open to anyone in the configured Discord channel ID.
- Secrets are read from 1Password at runtime.
- Rendered env files are removed after use.
