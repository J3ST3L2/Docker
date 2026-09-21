#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="${STACK_DIR:-/opt/stacks/keep-mist-vector}"

sudo mkdir -p "$STACK_DIR"
sudo chown "$USER":"$USER" "$STACK_DIR"

cp -a . "$STACK_DIR/"
cd "$STACK_DIR"

if [[ ! -f .env ]]; then
  cp .env.example .env
  chmod 600 .env
  echo
  echo "Created $STACK_DIR/.env"
  echo "Set MIST_WEBHOOK_PASSWORD before starting the stack."
  exit 2
fi

docker compose config >/dev/null
docker compose pull
docker compose up -d

echo
docker compose ps
echo
echo "Vector is listening on 127.0.0.1:8686."
echo "Next: add nginx/keep-mist-location.conf to the keep.middlebury.edu server block."
