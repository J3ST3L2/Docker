#!/usr/bin/env bash
set -euo pipefail

/app/proxmox_health.sh
REPORT="$(cat /tmp/proxmox-health-last-report)"

if [[ -z "${DISCORD_WEBHOOK_URL:-}" ]]; then
    echo "DISCORD_WEBHOOK_URL is not set; report saved locally only."
    exit 0
fi

if [[ ! -f "$REPORT" ]]; then
    echo "Expected report file was not created: $REPORT" >&2
    exit 1
fi

SUMMARY="Proxmox health report completed on $(date '+%Y-%m-%d %H:%M:%S %Z'). Incident node: ${INCIDENT_NODE:-pve2}."

curl --fail-with-body --silent --show-error \
    -F "payload_json={\"content\":\"${SUMMARY}\"}" \
    -F "files[0]=@${REPORT}" \
    "${DISCORD_WEBHOOK_URL}"

echo "Report sent to Discord."
