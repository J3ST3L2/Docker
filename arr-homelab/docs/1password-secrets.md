# ARR 1Password Secrets

## Model

1Password is the source of truth for real secrets. GitHub stores only templates with `op://` references.

Changing a secret in 1Password does not live-update a running container. Re-render the env file with `op inject`, then recreate the service that consumes the value.

## 1Password Item

Vault: `JesterTek`

Item: `ARR Stack`

Fields:

- `PIA_USER`
- `PIA_PASS`
- `SONARR_API_KEY`
- `RADARR_API_KEY`
- `PROWLARR_API_KEY`
- `QBITTORRENT_WEBUI_PASSWORD_PBKDF2`

## Server Bootstrap Secret

The server still needs one bootstrap secret: a read-only 1Password service account token scoped to the `JesterTek` vault.

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

## App-Internal Secret Rendering

The PIA credentials are handled through Compose environment variables.

Sonarr, Radarr, and Prowlarr API keys live in `config.xml`. The script below updates only the `ApiKey` element from 1Password:

```bash
sudo /opt/docker-stacks/arr-stack/scripts/render-arr-app-secrets.sh
```

qBittorrent stores the WebUI password as a PBKDF2 hash. The render script updates the `WebUI\Password_PBKDF2` field from 1Password.

Changing these values in 1Password does not live-update running services. Use `/redeploy target:arr` after changes.
