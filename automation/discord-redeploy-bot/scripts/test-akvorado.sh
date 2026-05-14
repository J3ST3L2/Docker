#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ssh "${SSH_OPTS[@]}" tberno@10.20.60.15 '
  set -e
  cd /opt/docker/akvorado
  sudo OUT_FILE=/tmp/akvorado.env OUTLET_CONFIG_OUT=/tmp/akvorado-outlet.yaml ./scripts/render-akvorado-secrets.sh >/dev/null
  sudo test -s /tmp/akvorado.env
  sudo test -s /tmp/akvorado-outlet.yaml
  sudo rm -f /tmp/akvorado.env /tmp/akvorado-outlet.yaml
  echo "Akvorado secret render OK"
'
