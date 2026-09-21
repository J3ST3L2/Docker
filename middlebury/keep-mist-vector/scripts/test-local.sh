#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "Missing .env. Copy .env.example to .env and set MIST_WEBHOOK_PASSWORD." >&2
  exit 1
fi

set -a
source ./.env
set +a

AUTH="$(printf '%s:%s' "$MIST_WEBHOOK_USERNAME" "$MIST_WEBHOOK_PASSWORD" | base64 -w0)"

curl -fsS -i \
  -X POST \
  http://127.0.0.1:8686/ \
  -H "Authorization: Basic $AUTH" \
  -H 'Content-Type: application/json' \
  --data '{
    "topic": "alarms",
    "org_id": "test-org",
    "site_id": "test-site",
    "site_name": "Vector Test",
    "events": [
      {
        "type": "ap_down",
        "severity": "critical",
        "device_name": "TEST-AP-01",
        "mac": "001122334455",
        "text": "Synthetic Mist alarm from test-local.sh",
        "timestamp": "2026-09-21T15:00:00Z"
      }
    ]
  }'

echo
echo "Submitted synthetic Mist alarm. Check Keep Alerts for TEST-AP-01."
