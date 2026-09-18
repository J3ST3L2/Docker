#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="${STACK_DIR:-/opt/docker-stacks/keep}"
ENV_FILE="${ENV_FILE:-$STACK_DIR/.env}"
API_URL="${API_URL:-http://10.20.60.15:8180}"
WORKFLOW_ID="${WORKFLOW_ID:-home-librenms-slack}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v python3 >/dev/null 2>&1 || die "python3 is required"
[[ -r "$ENV_FILE" ]] || die "Cannot read $ENV_FILE"

get_env() {
  local key="$1"
  grep -m1 "^${key}=" "$ENV_FILE" | cut -d= -f2- || true
}

KEEP_USER="$(get_env KEEP_DEFAULT_USERNAME)"
KEEP_PASS="$(get_env KEEP_DEFAULT_PASSWORD)"

[[ -n "$KEEP_USER" ]] || KEEP_USER="tberno"
[[ -n "$KEEP_PASS" ]] || die "KEEP_DEFAULT_PASSWORD is missing from $ENV_FILE"

echo "==> Checking Keep API"
curl -fsS "$API_URL/healthcheck" >/dev/null || die "Keep API is not healthy at $API_URL"

echo "==> Logging into Keep as $KEEP_USER"
LOGIN_PAYLOAD="$(python3 - "$KEEP_USER" "$KEEP_PASS" <<'PY'
import json
import sys
print(json.dumps({"username": sys.argv[1], "password": sys.argv[2]}))
PY
)"

LOGIN_RESPONSE="$(curl -fsS   -X POST "$API_URL/signin"   -H 'Content-Type: application/json'   -d "$LOGIN_PAYLOAD")" || die "Keep login failed"

TOKEN="$(printf '%s' "$LOGIN_RESPONSE" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("accessToken", ""))
except Exception:
    print("")
')"

[[ -n "$TOKEN" ]] || die "Keep login succeeded but no access token was returned"

echo "==> Discovering installed Slack provider"
PROVIDERS_JSON="$(curl -fsS   -H "Authorization: Bearer $TOKEN"   "$API_URL/providers")" || die "Unable to query Keep providers"

SLACK_PROVIDER="$(printf '%s' "$PROVIDERS_JSON" | python3 -c '
import json, sys
data = json.load(sys.stdin)
providers = [
    p for p in data.get("installed_providers", [])
    if str(p.get("type", "")).lower() == "slack"
]
if not providers:
    sys.exit(0)

preferred = {"home-slack": 0, "slack": 1}
providers.sort(key=lambda p: preferred.get(str(p.get("name", "")).lower(), 99))
print(providers[0].get("name", ""))
')"

[[ -n "$SLACK_PROVIDER" ]] || die "No installed Slack provider found in Keep. Connect Slack first."

echo "==> Using Slack provider: $SLACK_PROVIDER"

TMP_YAML="$(mktemp)"
trap 'rm -f "$TMP_YAML"' EXIT

cat > "$TMP_YAML" <<YAML
workflow:
  id: $WORKFLOW_ID
  name: Home LibreNMS to Slack
  description: Forward normalized LibreNMS alerts to Slack through Keep.
  disabled: false

  triggers:
    - type: alert
      cel: source.contains("libre_nms")

  actions:
    - name: send-librenms-alert-to-slack
      provider:
        type: slack
        config: "{{ providers.$SLACK_PROVIDER }}"
        with:
          message: |
            *{{ alert.severity | upper }}* - *{{ alert.name }}*

            *Status:* {{ alert.status }}
            *Device:* {{ alert.hostname | default('unknown') }}
            *IP:* {{ alert.ip | default('unknown') }}
            *Location:* {{ alert.location | default('unknown') }}
            *Description:* {{ alert.description | default('No description') }}
YAML

echo "==> Uploading workflow: $WORKFLOW_ID"
UPLOAD_RESPONSE="$(curl -fsS   -X POST "$API_URL/workflows"   -H "Authorization: Bearer $TOKEN"   -F "file=@$TMP_YAML;type=application/x-yaml")" || die "Workflow upload failed"

printf '%s\n' "$UPLOAD_RESPONSE" | python3 -c '
import json, sys
data = json.load(sys.stdin)
print(f"    status: {data.get("status", "unknown")}")
print(f"    workflow_id: {data.get("workflow_id", "unknown")}")
print(f"    revision: {data.get("revision", "unknown")}")
'

echo "==> Verifying workflow"
VERIFY_JSON="$(curl -fsS   -H "Authorization: Bearer $TOKEN"   "$API_URL/workflows/$WORKFLOW_ID")" || die "Workflow uploaded but verification failed"

printf '%s\n' "$VERIFY_JSON" | python3 -c '
import json, sys
data = json.load(sys.stdin)
print(f"    name: {data.get("name")}")
print(f"    disabled: {data.get("disabled")}")
print(f"    revision: {data.get("revision")}")
providers = data.get("providers") or []
if providers:
    print("    providers: " + ", ".join(str(p.get("name", p.get("type", "unknown"))) for p in providers))
'

echo
echo "DONE: LibreNMS -> Keep -> Slack workflow is installed and enabled."
echo "Trigger another LibreNMS transport test and watch Slack."
