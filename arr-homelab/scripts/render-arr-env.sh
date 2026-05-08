#!/usr/bin/env sh
set -eu

STACK_DIR="${STACK_DIR:-/opt/docker-stacks/arr-stack}"
TOKEN_FILE="${OP_TOKEN_FILE:-/etc/1password/arr-stack.token}"
OUT_FILE="${OUT_FILE:-/run/arr-stack.env}"

export OP_SERVICE_ACCOUNT_TOKEN="$(cat "$TOKEN_FILE")"
op inject -i "$STACK_DIR/.env.tpl" -o "$OUT_FILE"
chmod 600 "$OUT_FILE"

echo "Rendered $OUT_FILE from 1Password"
