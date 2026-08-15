#!/usr/bin/env bash
set -euo pipefail

HOSTS=(pve pve2 pve3 pve4)
SSH_DIR=/root/.ssh
KNOWN_HOSTS="${SSH_DIR}/known_hosts"
KEY="${SSH_DIR}/id_ed25519"

mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"
touch "${KNOWN_HOSTS}"
chmod 600 "${KNOWN_HOSTS}"

if [[ ! -f "${KEY}" ]]; then
    echo "Generating dedicated Ansible SSH key at ${KEY}"
    ssh-keygen -t ed25519 -N '' -f "${KEY}" -C 'proxmox-health-ansible'
fi

echo
for host in "${HOSTS[@]}"; do
    echo "=== ${host} ==="
    echo "Fetching SSH host keys..."
    ssh-keyscan -H "${host}" 2>/dev/null >> "${KNOWN_HOSTS}.new"
done

sort -u "${KNOWN_HOSTS}" "${KNOWN_HOSTS}.new" > "${KNOWN_HOSTS}.merged"
mv "${KNOWN_HOSTS}.merged" "${KNOWN_HOSTS}"
rm -f "${KNOWN_HOSTS}.new"
chmod 600 "${KNOWN_HOSTS}"

echo
echo "Host keys captured. Verify fingerprints before trusting them permanently:"
for host in "${HOSTS[@]}"; do
    echo
    echo "--- ${host} ---"
    ssh-keyscan "${host}" 2>/dev/null | ssh-keygen -lf - || true
done

echo
echo "Public key to install on each Proxmox host:"
cat "${KEY}.pub"
echo
echo "After installing that public key in /root/.ssh/authorized_keys on every host, run:"
echo "  ansible proxmox -m ping"
