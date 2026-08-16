---
tags:
  - procedure
  - discord
  - automation
  - homelab
---
# Discord Bot Operations

Related: [[Discord Redeploy Bot]], [[Ansible Control Node]], [[1Password Secrets]]

## Check Service Status

On `10.20.60.19`:

```bash
sudo systemctl status --no-pager homelab-discord-bot
```

## View Logs

```bash
sudo journalctl -u homelab-discord-bot -n 120 --no-pager
```

Expected startup log includes the bot logging into Discord as `alerts-platform-bot`.

## Restart Bot

```bash
sudo systemctl restart homelab-discord-bot
sudo journalctl -u homelab-discord-bot -n 80 --no-pager
```

## Test Secret Rendering

Use Discord:

```text
/secrets-test target:arr
/secrets-test target:nms
/secrets-test target:graylog
/secrets-test target:akvorado
```

These tests should not restart containers.

## Redeploy A Stack

Use Discord:

```text
/redeploy target:arr
/redeploy target:nms
/redeploy target:graylog
/redeploy target:akvorado
```

Redeploy commands run fixed scripts only. They pull current values from 1Password, run Docker Compose, and remove temporary env files.

## If Slash Commands Do Not Appear

Confirm the bot is installed in the correct Discord server with both scopes:

```text
bot
applications.commands
```

The bot should sync guild-scoped commands using `DISCORD_GUILD_ID`. If duplicate `/sonarr` or `/radarr` entries appear, stale global application commands may still exist and should be cleared.

## Test Media Adds

Use the configured media channel:

```text
/sonarr query:severance
/radarr query:interstellar 2014
```

The bot should reply with one of:

```text
added and searched, but no download was grabbed yet
is in the download queue
was grabbed by search
```

If the request was grabbed in ARR but Discord did not say so, check the bot's ARR queue/history lookup and service logs.

## If Commands Fail

Check in this order:

- Bot service is running.
- `op read op://JesterTek/Discord Bot/DISCORD_BOT_TOKEN` works with the service account token.
- `/opt/homelab-discord-bot/known_hosts` has entries for `10.20.60.13` and `10.20.60.15`.
- `/home/tberno/.ssh/ansible_key` can SSH to the target host.
- Target render script works directly on the target host.
- Docker Compose stack is healthy after redeploy.
