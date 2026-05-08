#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ssh "${SSH_OPTS[@]}" tberno@10.20.60.13 '
  set -e
  cd /opt/docker-stacks/arr-stack
  sudo OUT_FILE=/tmp/arr-stack.env ./scripts/render-arr-env.sh >/dev/null
  sudo test -s /tmp/arr-stack.env
  sudo rm -f /tmp/arr-stack.env
  sudo OP_TOKEN_FILE=/etc/1password/arr-stack.token sh -c '"'"'
    export OP_SERVICE_ACCOUNT_TOKEN="$(cat "$OP_TOKEN_FILE")"
    op read "op://JesterTek/ARR Stack/SONARR_API_KEY" >/dev/null
    op read "op://JesterTek/ARR Stack/RADARR_API_KEY" >/dev/null
    op read "op://JesterTek/ARR Stack/PROWLARR_API_KEY" >/dev/null
    op read "op://JesterTek/ARR Stack/QBITTORRENT_WEBUI_PASSWORD_PBKDF2" >/dev/null
  '"'"'
  echo "ARR secret render OK"
'
