#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ssh "${SSH_OPTS[@]}" tberno@10.20.60.13 '
  set -e
  cd /opt/docker-stacks/arr-stack
  sudo ./scripts/render-arr-env.sh >/dev/null
  sudo docker compose --env-file /run/arr-stack.env up -d
  sudo rm -f /run/arr-stack.env
  docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "^(NAMES|gluetun|qbittorrent|sonarr|radarr|prowlarr|flaresolverr)"
'
