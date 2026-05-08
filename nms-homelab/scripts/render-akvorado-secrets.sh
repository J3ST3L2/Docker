#!/usr/bin/env sh
set -eu

TOKEN_FILE="${OP_TOKEN_FILE:-/etc/1password/akvorado-stack.token}"
export OP_SERVICE_ACCOUNT_TOKEN="$(cat "$TOKEN_FILE")"

op inject -i /opt/docker/akvorado/.env.tpl -o /run/akvorado.env
chmod 600 /run/akvorado.env

if [ -f /opt/docker/akvorado/config/outlet.yaml.tpl ]; then
  op inject \
    -i /opt/docker/akvorado/config/outlet.yaml.tpl \
    -o /opt/docker/akvorado/config/outlet.yaml
  chmod 644 /opt/docker/akvorado/config/outlet.yaml
fi

echo "Rendered Akvorado secrets from 1Password"
