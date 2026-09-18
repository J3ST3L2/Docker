#!/usr/bin/env bash
set -euo pipefail

STACK_DIR="${STACK_DIR:-/opt/docker-stacks/keep}"
ENV_FILE="${ENV_FILE:-$STACK_DIR/.env}"
DB_FILE="${DB_FILE:-$STACK_DIR/state/db.sqlite3}"
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

get_slack_provider_from_api() {
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

get_slack_row_from_db() {
  [[ -r "$DB_FILE" ]] || return 0
  python3 - "$DB_FILE" "$SLACK_PROVIDER_NAME" <<'PY'
import sqlite3
import sys

db, preferred_name = sys.argv[1], sys.argv[2]
try:
    conn = sqlite3.connect(db)
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        """
        SELECT id, name, type, configuration_key
        FROM provider
        WHERE lower(type) = 'slack'
        ORDER BY CASE WHEN lower(name) = lower(?) THEN 0 ELSE 1 END,
                 installation_time DESC
        """,
        (preferred_name,),
    ).fetchall()
except Exception:
    sys.exit(0)

if rows:
    row = rows[0]
    print(f"{row['id']}|{row['name']}|{row['configuration_key']}")
PY
}

prompt_slack_webhook() {
  if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
    read -r -s -p "Paste Slack Incoming Webhook URL: " SLACK_WEBHOOK_URL
    echo
  fi
  [[ -n "$SLACK_WEBHOOK_URL" ]] || die "Slack webhook URL cannot be empty"
}

repair_slack_provider() {
  local provider_id="$1"
  prompt_slack_webhook

  echo "==> Repairing existing Slack provider configuration"
  UPDATE_PAYLOAD="$(python3 - "$SLACK_WEBHOOK_URL" <<'PY'
import json
import sys
print(json.dumps({
    "webhook_url": sys.argv[1],
    "pulling_enabled": False
}))
PY
)"

  RESPONSE_FILE="$(mktemp)"
  CODE="$(curl -sS     -o "$RESPONSE_FILE"     -w '%{http_code}'     -X PUT "$API_URL/providers/$provider_id"     -H "Authorization: Bearer $TOKEN"     -H 'Content-Type: application/json'     -d "$UPDATE_PAYLOAD")"

  if [[ ! "$CODE" =~ ^2 ]]; then
    echo "Keep returned HTTP $CODE while repairing Slack:" >&2
    cat "$RESPONSE_FILE" >&2
    rm -f "$RESPONSE_FILE"
    die "Slack provider repair failed"
  fi
  rm -f "$RESPONSE_FILE"
}

if [[ -n "${SLACK_PROVIDER_NAME:-}" ]]; then
  echo "==> Using configured Slack provider name: $SLACK_PROVIDER_NAME"
  SLACK_PROVIDER="$SLACK_PROVIDER_NAME"
else
  echo "==> Discovering installed Slack provider"
  SLACK_PROVIDER="$(get_slack_provider_from_api || true)"
fi

if [[ -z "$SLACK_PROVIDER" ]]; then
  DB_ROW="$(get_slack_row_from_db || true)"

  if [[ -n "$DB_ROW" ]]; then
    IFS='|' read -r SLACK_PROVIDER_ID SLACK_PROVIDER SLACK_CONFIG_KEY <<< "$DB_ROW"
    echo "==> Found existing Slack DB row: $SLACK_PROVIDER"

    SECRET_FILE="$STACK_DIR/state/$SLACK_CONFIG_KEY"
    SECRET_OK="false"
    if [[ -r "$SECRET_FILE" ]]; then
      if python3 - "$SECRET_FILE" <<'PY' >/dev/null 2>&1
import json
import sys
data = json.load(open(sys.argv[1]))
url = (data.get("authentication") or {}).get("webhook_url")
if not url:
    raise SystemExit(1)
PY
      then
        SECRET_OK="true"
      fi
    fi

    if [[ "$SECRET_OK" != "true" ]]; then
      echo "==> Slack DB row exists but its saved config is missing/unreadable."
      repair_slack_provider "$SLACK_PROVIDER_ID"
    else
      echo "==> Existing Slack provider config is present."
    fi
  else
    echo "==> No Slack provider is installed in Keep."
    prompt_slack_webhook

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
    INSTALL_CODE="$(curl -sS       -o "$INSTALL_RESPONSE_FILE"       -w '%{http_code}'       -X POST "$API_URL/providers/install"       -H "Authorization: Bearer $TOKEN"       -H 'Content-Type: application/json'       -d "$INSTALL_PAYLOAD")"

    if [[ "$INSTALL_CODE" == "409" ]]; then
      rm -f "$INSTALL_RESPONSE_FILE"
      DB_ROW="$(get_slack_row_from_db || true)"
      [[ -n "$DB_ROW" ]] || die "Keep reports Slack already installed, but no local Slack provider row was found"
      IFS='|' read -r SLACK_PROVIDER_ID SLACK_PROVIDER SLACK_CONFIG_KEY <<< "$DB_ROW"
      echo "==> Reusing existing Slack provider: $SLACK_PROVIDER"
    elif [[ ! "$INSTALL_CODE" =~ ^2 ]]; then
      echo "Keep returned HTTP $INSTALL_CODE while installing Slack:" >&2
      cat "$INSTALL_RESPONSE_FILE" >&2
      rm -f "$INSTALL_RESPONSE_FILE"
      die "Slack provider installation failed"
    else
      SLACK_PROVIDER="$SLACK_PROVIDER_NAME"
      echo "==> Slack provider installed: $SLACK_PROVIDER"
      rm -f "$INSTALL_RESPONSE_FILE"
    fi
  fi
fi

[[ -n "$SLACK_PROVIDER" ]] || die "Unable to determine Slack provider name"
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

python3 - "$UPLOAD_RESPONSE_FILE" <<'PY'
import json
import sys
data = json.load(open(sys.argv[1]))
print("    status:", data.get("status", "unknown"))
print("    workflow_id:", data.get("workflow_id", "unknown"))
print("    revision:", data.get("revision", "unknown"))
PY
rm -f "$UPLOAD_RESPONSE_FILE"

echo "==> Verifying workflow"
VERIFY_FILE="$(mktemp)"
VERIFY_CODE="$(curl -sS   -o "$VERIFY_FILE"   -w '%{http_code}'   -H "Authorization: Bearer $TOKEN"   "$API_URL/workflows/$WORKFLOW_ID")"

if [[ ! "$VERIFY_CODE" =~ ^2 ]]; then
  echo "Keep returned HTTP $VERIFY_CODE while verifying workflow:" >&2
  cat "$VERIFY_FILE" >&2
  rm -f "$VERIFY_FILE"
  die "Workflow uploaded but verification failed"
fi

python3 - "$VERIFY_FILE" <<'PY'
import json
import sys
data = json.load(open(sys.argv[1]))
print("    name:", data.get("name"))
print("    disabled:", data.get("disabled"))
print("    revision:", data.get("revision"))
providers = data.get("providers") or []
if providers:
    print("    providers:", ", ".join(
        str((p.get("details") or {}).get("name") or p.get("name") or p.get("type") or "unknown")
        for p in providers
    ))
PY
rm -f "$VERIFY_FILE"

echo
echo "DONE: LibreNMS -> Keep -> Slack workflow is installed and enabled."
echo "Trigger another LibreNMS transport test and watch Slack."
