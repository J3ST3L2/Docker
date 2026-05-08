# Homelab Discord Redeploy Bot

This bot provides allowlisted Discord slash commands for testing 1Password secret rendering and redeploying fixed homelab stacks.

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

## Security Model

- Fixed scripts only.
- No arbitrary shell command execution.
- Commands are allowlisted by Discord user ID.
- Secrets are read from 1Password at runtime.
- Rendered env files are removed after use.
