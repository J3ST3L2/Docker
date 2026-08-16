#!/usr/bin/env sh
set -eu

TOKEN_FILE="${OP_TOKEN_FILE:-/etc/1password/powerdns-stack.token}"
STACK_DIR="${STACK_DIR:-/opt/docker-stacks/powerdns-stack}"
OUT_FILE="${OUT_FILE:-/run/powerdns-stack.env}"

export OP_SERVICE_ACCOUNT_TOKEN="$(cat "$TOKEN_FILE")"

op inject -f -i "$STACK_DIR/.env.tpl" -o "$OUT_FILE"
chmod 600 "$OUT_FILE"

echo "Rendered PowerDNS secrets from 1Password"
