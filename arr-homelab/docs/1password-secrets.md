# ARR 1Password Secrets

## Model

1Password is the source of truth for real secrets. GitHub stores only templates with `op://` references.

Changing a secret in 1Password does not live-update a running container. Re-render the env file with `op inject`, then recreate the service that consumes the value.

## 1Password Item

Vault: `Homelab`

Item: `ARR Stack`

Fields:

- `PIA_USER`
- `PIA_PASS`

## Server Bootstrap Secret

The server still needs one bootstrap secret: a read-only 1Password service account token scoped to the `Homelab` vault.

Recommended storage:

```text
/etc/1password/arr-stack.token
```

Recommended permissions:

```bash
sudo mkdir -p /etc/1password
sudo chown root:root /etc/1password
sudo chmod 700 /etc/1password
sudo install -m 600 arr-stack.token /etc/1password/arr-stack.token
```

## Render And Deploy

```bash
cd /opt/docker-stacks/arr-stack
sudo /opt/docker-stacks/arr-stack/scripts/render-arr-env.sh
docker compose --env-file /run/arr-stack.env up -d
sudo rm -f /run/arr-stack.env
```

## Current Limitations

The PIA credentials are cleanly handled through Compose environment variables.

Sonarr, Radarr, and Prowlarr API keys live in their app config/databases. Keep a reference copy in 1Password, but changing the 1Password value alone will not rotate the app. Rotate those inside each app, then update 1Password.

qBittorrent WebUI password hash is stored in qBittorrent config. Keep the real password in 1Password, rotate it in qBittorrent, then update 1Password.
