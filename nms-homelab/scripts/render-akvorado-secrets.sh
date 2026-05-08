#!/usr/bin/env sh
set -eu

TOKEN_FILE="${OP_TOKEN_FILE:-/etc/1password/akvorado-stack.token}"
STACK_DIR="${STACK_DIR:-/opt/docker/akvorado}"
OUT_FILE="${OUT_FILE:-/run/akvorado.env}"
OUTLET_TEMPLATE="${OUTLET_TEMPLATE:-$STACK_DIR/config/outlet.yaml.tpl}"
OUTLET_CONFIG_OUT="${OUTLET_CONFIG_OUT:-$STACK_DIR/config/outlet.yaml}"
export OP_SERVICE_ACCOUNT_TOKEN="$(cat "$TOKEN_FILE")"

op inject -f -i "$STACK_DIR/.env.tpl" -o "$OUT_FILE"
chmod 600 "$OUT_FILE"

if [ -f "$OUTLET_TEMPLATE" ]; then
  op inject -f \
    -i "$OUTLET_TEMPLATE" \
    -o "$OUTLET_CONFIG_OUT"
  chmod 644 "$OUTLET_CONFIG_OUT"
fi

echo "Rendered Akvorado secrets from 1Password"
