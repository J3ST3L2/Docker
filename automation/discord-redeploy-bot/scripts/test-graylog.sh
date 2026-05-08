#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ssh "${SSH_OPTS[@]}" tberno@10.20.60.15 '
  set -e
  cd /opt/graylog-stack
  sudo OUT_FILE=/tmp/graylog-stack.env ./scripts/render-graylog-secrets.sh >/dev/null
  sudo test -s /tmp/graylog-stack.env
  sudo rm -f /tmp/graylog-stack.env
  echo "Graylog secret render OK"
'
