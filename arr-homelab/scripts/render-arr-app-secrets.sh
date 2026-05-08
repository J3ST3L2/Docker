#!/usr/bin/env sh
set -eu

STACK_DIR="${STACK_DIR:-/opt/docker-stacks/arr-stack}"
TOKEN_FILE="${OP_TOKEN_FILE:-/etc/1password/arr-stack.token}"

export OP_SERVICE_ACCOUNT_TOKEN="$(cat "$TOKEN_FILE")"

SONARR_API_KEY="$(op read 'op://JesterTek/ARR Stack/SONARR_API_KEY')"
RADARR_API_KEY="$(op read 'op://JesterTek/ARR Stack/RADARR_API_KEY')"
PROWLARR_API_KEY="$(op read 'op://JesterTek/ARR Stack/PROWLARR_API_KEY')"
QBITTORRENT_WEBUI_PASSWORD_PBKDF2="$(op read 'op://JesterTek/ARR Stack/QBITTORRENT_WEBUI_PASSWORD_PBKDF2')"

export SONARR_API_KEY RADARR_API_KEY PROWLARR_API_KEY QBITTORRENT_WEBUI_PASSWORD_PBKDF2

python3 - <<'PY'
import os
import re
import xml.etree.ElementTree as ET
from pathlib import Path

stack_dir = Path(os.environ.get("STACK_DIR", "/opt/docker-stacks/arr-stack"))
config_dir = stack_dir / "config"

def update_xml(path: Path, updates: dict[str, str]) -> None:
    tree = ET.parse(path)
    root = tree.getroot()
    for tag, value in updates.items():
        element = root.find(tag)
        if element is None:
            element = ET.SubElement(root, tag)
        element.text = value
    tree.write(path, encoding="utf-8", xml_declaration=True)

def update_qbit(path: Path, password_hash: str) -> None:
    if not path.exists():
        return
    text = path.read_text()
    replacement = f"WebUI\\\\Password_PBKDF2={password_hash}"
    if re.search(r"^WebUI\\Password_PBKDF2=.*$", text, flags=re.MULTILINE):
        text = re.sub(r"^WebUI\\Password_PBKDF2=.*$", replacement, text, flags=re.MULTILINE)
    else:
        text = text.rstrip() + "\n" + replacement + "\n"
    path.write_text(text)

update_xml(config_dir / "sonarr/config.xml", {"ApiKey": os.environ["SONARR_API_KEY"]})
update_xml(config_dir / "radarr/config.xml", {"ApiKey": os.environ["RADARR_API_KEY"]})
update_xml(config_dir / "prowlarr/config.xml", {"ApiKey": os.environ["PROWLARR_API_KEY"]})

for qbit_path in [
    config_dir / "qbittorrent/qBittorrent/qBittorrent.conf",
    config_dir / "qbittorrent/qBittorrent.conf",
]:
    update_qbit(qbit_path, os.environ["QBITTORRENT_WEBUI_PASSWORD_PBKDF2"])
PY

echo "Rendered ARR app secret fields from 1Password"
