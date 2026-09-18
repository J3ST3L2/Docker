#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="${STACK_DIR:-/opt/docker-stacks/keep}"
ENV_FILE="${ENV_FILE:-$STACK_DIR/.env}"
API_URL="${API_URL:-http://10.20.60.15:8180}"
WORKFLOW_ID="${WORKFLOW_ID:-home-librenms-slack}"
SLACK_PROVIDER_NAME="${SLACK_PROVIDER_NAME:-home-slack}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

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

get_slack_provider() {
  curl -fsS     -H "Authorization: Bearer $TOKEN"     "$API_URL/providers" |
  python3 -c '
import json, sys
data = json.load(sys.stdin)
providers = [
    p for p in data.get("installed_providers", [])
    if str(p.get("type", "")).lower() == "slack"
]
if not providers:
    sys.exit(0)

def provider_name(p):
    details = p.get("details") or {}
    return str(details.get("name") or p.get("name") or "")

preferred = {"home-slack": 0, "slack": 1}
providers.sort(key=lambda p: preferred.get(provider_name(p).lower(), 99))
print(provider_name(providers[0]))
'
}

echo "==> Discovering installed Slack provider"
SLACK_PROVIDER="$(get_slack_provider || true)"

if [[ -z "$SLACK_PROVIDER" ]]; then
  echo "==> No Slack provider is installed in Keep."

  if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
    read -r -s -p "Paste Slack Incoming Webhook URL: " SLACK_WEBHOOK_URL
    echo
  fi

  [[ -n "$SLACK_WEBHOOK_URL" ]] || die "Slack webhook URL cannot be empty"

  case "$SLACK_WEBHOOK_URL" in
    https://hooks.slack.com/*)
      ;;
    *)
      echo "WARNING: This does not look like a standard Slack Incoming Webhook URL."
      read -r -p "Continue anyway? [y/N]: " answer
      [[ "${answer:-}" =~ ^[Yy]$ ]] || die "Cancelled"
      ;;
  esac

  echo "==> Installing Slack provider as $SLACK_PROVIDER_NAME"
  INSTALL_PAYLOAD="$(python3 - "$SLACK_PROVIDER_NAME" "$SLACK_WEBHOOK_URL" <<'PY'
import json
import sys
name = sys.argv[1]
webhook = sys.argv[2]
print(json.dumps({
    "provider_id": name,
    "provider_name": name,
    "provider_type": "slack",
    "pulling_enabled": False,
    "webhook_url": webhook
}))
PY
)"

  INSTALL_RESPONSE_FILE="$(mktemp)"
  INSTALL_CODE="$(curl -sS     -o "$INSTALL_RESPONSE_FILE"     -w '%{http_code}'     -X POST "$API_URL/providers/install"     -H "Authorization: Bearer $TOKEN"     -H 'Content-Type: application/json'     -d "$INSTALL_PAYLOAD")"

  if [[ ! "$INSTALL_CODE" =~ ^2 ]]; then
    echo "Keep returned HTTP $INSTALL_CODE while installing Slack:" >&2
    cat "$INSTALL_RESPONSE_FILE" >&2
    rm -f "$INSTALL_RESPONSE_FILE"
    die "Slack provider installation failed"
  fi
  rm -f "$INSTALL_RESPONSE_FILE"

  SLACK_PROVIDER="$(get_slack_provider || true)"
  [[ -n "$SLACK_PROVIDER" ]] || die "Slack installation returned success but provider was not found afterward"
fi

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
UPLOAD_RESPONSE_FILE="$(mktemp)"
UPLOAD_CODE="$(curl -sS   -o "$UPLOAD_RESPONSE_FILE"   -w '%{http_code}'   -X POST "$API_URL/workflows"   -H "Authorization: Bearer $TOKEN"   -F "file=@$TMP_YAML;type=application/x-yaml")"

if [[ ! "$UPLOAD_CODE" =~ ^2 ]]; then
  echo "Keep returned HTTP $UPLOAD_CODE while uploading workflow:" >&2
  cat "$UPLOAD_RESPONSE_FILE" >&2
  rm -f "$UPLOAD_RESPONSE_FILE"
  die "Workflow upload failed"
fi

cat "$UPLOAD_RESPONSE_FILE" | python3 -c '
import json, sys
data = json.load(sys.stdin)
print(f"    status: {data.get('status', 'unknown')}")
print(f"    workflow_id: {data.get('workflow_id', 'unknown')}")
print(f"    revision: {data.get('revision', 'unknown')}")
'
rm -f "$UPLOAD_RESPONSE_FILE"

echo "==> Verifying workflow"
VERIFY_JSON="$(curl -fsS   -H "Authorization: Bearer $TOKEN"   "$API_URL/workflows/$WORKFLOW_ID")" || die "Workflow uploaded but verification failed"

printf '%s\n' "$VERIFY_JSON" | python3 -c '
import json, sys
data = json.load(sys.stdin)
print(f"    name: {data.get('name')}")
print(f"    disabled: {data.get('disabled')}")
print(f"    revision: {data.get('revision')}")
providers = data.get("providers") or []
if providers:
    print("    providers: " + ", ".join(str(p.get("name", p.get("type", "unknown"))) for p in providers))
'

echo
echo "DONE: LibreNMS -> Keep -> Slack workflow is installed and enabled."
echo "Trigger another LibreNMS transport test and watch Slack."
