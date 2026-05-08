#!/usr/bin/env sh
set -eu

TOKEN_FILE="${OP_TOKEN_FILE:-/etc/1password/nms-stack.token}"
STACK_DIR="${STACK_DIR:-/opt/docker-stacks/nms-stack}"
OUT_FILE="${OUT_FILE:-/run/nms-stack.env}"
OXIDIZED_TEMPLATE="${OXIDIZED_TEMPLATE:-$STACK_DIR/oxidized/config.tpl}"
OXIDIZED_CONFIG_OUT="${OXIDIZED_CONFIG_OUT:-$STACK_DIR/oxidized/config}"
export OP_SERVICE_ACCOUNT_TOKEN="$(cat "$TOKEN_FILE")"

op inject -f -i "$STACK_DIR/.env.tpl" -o "$OUT_FILE"
chmod 600 "$OUT_FILE"

if [ -f "$OXIDIZED_TEMPLATE" ]; then
  op inject -f \
    -i "$OXIDIZED_TEMPLATE" \
    -o "$OXIDIZED_CONFIG_OUT"
  chmod 644 "$OXIDIZED_CONFIG_OUT"
fi

echo "Rendered NMS secrets from 1Password"
