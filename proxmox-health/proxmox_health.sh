#!/usr/bin/env bash
set -u

NODES=(pve pve2 pve3 pve4)
INCIDENT_NODE="${INCIDENT_NODE:-pve2}"
REPORT_DIR="/app/reports"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
REPORT="${REPORT_DIR}/proxmox_health_${TIMESTAMP}.txt"

mkdir -p "${REPORT_DIR}"

line() { printf '%*s\n' 78 '' | tr ' ' '-'; }
header() { echo; line; echo "$1"; line; }

run_remote() {
    local host="$1"
    shift
    ssh -o BatchMode=yes \
        -o ConnectTimeout=5 \
        -o ServerAliveInterval=5 \
        -o ServerAliveCountMax=1 \
        -o UserKnownHostsFile=/root/.ssh/known_hosts \
        -o StrictHostKeyChecking=yes \
        -i /root/.ssh/id_ed25519 \
        "root@${host}" "$*"
}

exec > >(tee "$REPORT") 2>&1

header "PROXMOX CLUSTER DIAGNOSTIC REPORT"
echo "Report time : $(date)"
echo "Incident    : ${INCIDENT_NODE}"
echo "Nodes       : ${NODES[*]}"

header "ANSIBLE CONNECTIVITY"
ansible proxmox -m ping || true

for NODE in "${NODES[@]}"; do
    header "NODE: ${NODE}"

    if ! run_remote "$NODE" "true" >/dev/null 2>&1; then
        echo "ERROR: Unable to communicate with ${NODE}"
        continue
    fi

    run_remote "$NODE" '
        echo "Hostname:"; hostname -f
        echo; echo "Current time:"; date
        echo; echo "Kernel:"; uname -a
        echo; echo "Uptime:"; uptime
        echo; echo "Boot time:"; who -b
        echo; echo "Recent reboot/shutdown history:"; last -x -F 2>/dev/null | head -30
        echo; echo "Failed systemd services:"; systemctl --failed --no-pager 2>/dev/null || true
        echo; echo "Memory:"; free -h
        echo; echo "Filesystem usage:"; df -hT -x tmpfs -x devtmpfs
        echo; echo "Inode usage:"; df -ih -x tmpfs -x devtmpfs
        echo; echo "Kernel warnings/errors:"; journalctl -k -b -p warning..alert --no-pager 2>/dev/null | tail -100
        echo; echo "Suspicious hardware/power events:";
        journalctl -b --no-pager 2>/dev/null |
          grep -Ei "oom|out of memory|killed process|thermal|temperature|overheat|watchdog|machine check|mce|hardware error|edac|pcie.*error|aer:|nvme.*error|ata.*error|i/o error|reset controller|power key|power failure|power loss|voltage|critical temperature|kernel panic|panic|segfault|hung task|soft lockup|hard lockup" |
          tail -150 || true
        echo; echo "Network link counters:"; ip -s link 2>/dev/null || true
        echo; echo "Block devices:"; lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL,SERIAL 2>/dev/null
    '
done

header "${INCIDENT_NODE}: PREVIOUS BOOT INVESTIGATION"
run_remote "$INCIDENT_NODE" 'journalctl --list-boots --no-pager' || true

echo; echo ">>> Previous boot warning through emergency messages"
run_remote "$INCIDENT_NODE" 'journalctl -b -1 -p warning..alert --no-pager 2>/dev/null | tail -250' || true

echo; echo ">>> Previous boot kernel warnings/errors"
run_remote "$INCIDENT_NODE" 'journalctl -k -b -1 -p warning..alert --no-pager 2>/dev/null | tail -250' || true

echo; echo ">>> Previous boot suspicious events"
run_remote "$INCIDENT_NODE" 'journalctl -b -1 --no-pager 2>/dev/null | grep -Ei "oom|out of memory|killed process|thermal|temperature|overheat|watchdog|machine check|mce|hardware error|edac|pcie.*error|aer:|nvme.*error|ata.*error|i/o error|reset|power key|power failure|power loss|voltage|critical temperature|kernel panic|panic|segfault|hung task|soft lockup|hard lockup|shutdown|reboot|systemd-shutdown|reached target.*shutdown|stopping|stopped target" | tail -300 || true' || true

echo; echo ">>> Final 150 messages from previous boot"
run_remote "$INCIDENT_NODE" 'journalctl -b -1 -e -n 150 --no-pager 2>/dev/null' || true

header "${INCIDENT_NODE}: CLEAN VS ABRUPT SHUTDOWN"
run_remote "$INCIDENT_NODE" '
    if journalctl -b -1 --no-pager 2>/dev/null | grep -Eqi "systemd-shutdown|powering off|reached target.*power-off"; then
        echo "Evidence of an orderly OS shutdown was found."
    else
        echo "No obvious orderly shutdown sequence was found."
        echo "Abrupt power loss, hardware reset, watchdog, kernel crash, PSU/power issue, or hard lockup is more suspicious."
    fi
' || true

header "REPORT COMPLETE"
echo "Saved to ${REPORT}"

printf '%s\n' "$REPORT" > /tmp/proxmox-health-last-report
