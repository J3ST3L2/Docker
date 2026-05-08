#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ssh "${SSH_OPTS[@]}" tberno@10.20.60.15 '
  set -e
  cd /opt/docker-stacks/nms-stack
  sudo ./scripts/render-nms-secrets.sh >/dev/null
  sudo docker compose --env-file /run/nms-stack.env up -d
  sudo rm -f /run/nms-stack.env
  docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "^(NAMES|librenms|oxidized)"
'
