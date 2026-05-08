#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-/home/tberno/.ssh/ansible_key}"
KNOWN_HOSTS="${KNOWN_HOSTS:-/opt/homelab-discord-bot/known_hosts}"
SSH_OPTS=(-i "$SSH_KEY" -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$KNOWN_HOSTS")
