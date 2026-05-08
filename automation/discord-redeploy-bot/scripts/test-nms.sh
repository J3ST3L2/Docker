#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ssh "${SSH_OPTS[@]}" tberno@10.20.60.15 '
  set -e
  cd /opt/docker-stacks/nms-stack
  sudo OUT_FILE=/tmp/nms-stack.env OXIDIZED_CONFIG_OUT=/tmp/oxidized-config ./scripts/render-nms-secrets.sh >/dev/null
  sudo test -s /tmp/nms-stack.env
  sudo test -s /tmp/oxidized-config
  sudo rm -f /tmp/nms-stack.env /tmp/oxidized-config
  echo "NMS secret render OK"
'
