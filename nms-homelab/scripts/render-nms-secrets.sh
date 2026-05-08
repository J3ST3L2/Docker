#!/usr/bin/env sh
set -eu

TOKEN_FILE="${OP_TOKEN_FILE:-/etc/1password/nms-stack.token}"
export OP_SERVICE_ACCOUNT_TOKEN="$(cat "$TOKEN_FILE")"

op inject -i /opt/docker-stacks/nms-stack/.env.tpl -o /run/nms-stack.env
chmod 600 /run/nms-stack.env

if [ -f /opt/docker-stacks/nms-stack/oxidized/config.tpl ]; then
  op inject \
    -i /opt/docker-stacks/nms-stack/oxidized/config.tpl \
    -o /opt/docker-stacks/nms-stack/oxidized/config
  chmod 600 /opt/docker-stacks/nms-stack/oxidized/config
fi

echo "Rendered NMS secrets from 1Password"
