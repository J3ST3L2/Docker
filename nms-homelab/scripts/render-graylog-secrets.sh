#!/usr/bin/env sh
set -eu

TOKEN_FILE="${OP_TOKEN_FILE:-/etc/1password/graylog-stack.token}"
export OP_SERVICE_ACCOUNT_TOKEN="$(cat "$TOKEN_FILE")"

op inject -i /opt/graylog-stack/.env.tpl -o /run/graylog-stack.env
chmod 600 /run/graylog-stack.env

echo "Rendered Graylog secrets from 1Password"
