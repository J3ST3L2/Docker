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
  echo "ARR secret render OK"
'
