#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ssh "${SSH_OPTS[@]}" tberno@10.20.60.15 '
  set -e
  cd /opt/docker/akvorado
  sudo ./scripts/render-akvorado-secrets.sh >/dev/null
  sudo docker compose --env-file /run/akvorado.env up -d
  sudo rm -f /run/akvorado.env
  sudo docker compose ps
'
