# Proxmox Health + Discord

Dockge-friendly controller for collecting health diagnostics from the Proxmox cluster and optionally sending the report to a Discord channel webhook.

## Hosts

The default Ansible inventory contains:

- pve
- pve2
- pve3
- pve4

SSH uses root with a dedicated Ed25519 key stored in `./ssh/`. Ansible has strict host-key checking enabled and will refuse unknown or changed host keys.

## Dockge deployment

Clone or update the Docker repository on the Dockge host so this directory exists under the Dockge stacks path, for example:

```bash
cd /opt/stacks
git clone https://github.com/J3ST3L2/Docker.git docker-repo
ln -s /opt/stacks/docker-repo/proxmox-health /opt/stacks/proxmox-health
```

If the repository is already cloned, just pull it and make sure `/opt/stacks/proxmox-health` points to this directory.

Create the runtime directories and environment file:

```bash
cd /opt/stacks/proxmox-health
mkdir -p ssh reports
chmod 700 ssh
cp .env.example .env
chmod 600 .env
```

Edit `.env` and set the Discord webhook URL for the automation channel:

```env
TZ=America/New_York
INCIDENT_NODE=pve2
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/REPLACE_ME
```

Do not commit `.env` or anything under `ssh/`.

In Dockge, scan the stacks folder, open `proxmox-health`, and choose Compose Up / Update.

## Establish SSH trust

Open a shell in the `proxmox-health` container and run:

```bash
/app/bootstrap_trust.sh
```

The script generates `/root/.ssh/id_ed25519` if needed and displays the public key plus SSH host-key fingerprints.

Before accepting those host keys as trusted, compare the displayed fingerprints with fingerprints obtained directly from each Proxmox node console:

```bash
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
ssh-keygen -lf /etc/ssh/ssh_host_ecdsa_key.pub
ssh-keygen -lf /etc/ssh/ssh_host_rsa_key.pub
```

Install the controller public key on each Proxmox host under root:

```bash
mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo 'PASTE_PUBLIC_KEY_HERE' >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

Then verify all nodes from inside the controller container:

```bash
ansible proxmox -m ping
```

All four nodes should return `SUCCESS` / `pong`.

## Run diagnostics

Run and keep the report locally only:

```bash
/app/proxmox_health.sh
```

Run and also send the resulting text report to Discord:

```bash
/app/run_and_notify.sh
```

Reports are stored under `./reports/` on the Dockge host.

## Incident node

`INCIDENT_NODE` controls which node gets the previous-boot deep inspection. It defaults to `pve2`.
