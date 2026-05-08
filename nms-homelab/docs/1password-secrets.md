# NMS 1Password Secrets

## Model

1Password is the source of truth for real secrets. GitHub stores only templates with `op://` references.

Changing a secret in 1Password does not live-update a running container. Re-render the relevant env/config file with `op inject`, then recreate the affected service.

## Vault

Vault: `Homelab`

Use read-only service account tokens scoped to this vault. Store the token root-only on each Docker host under `/etc/1password/`.

## Items And Fields

### NMS Stack

- `MYSQL_ROOT_PASSWORD`
- `MYSQL_PASSWORD`

### Graylog Stack

- `GRAYLOG_PASSWORD_SECRET`
- `GRAYLOG_ROOT_PASSWORD_SHA2`

### Oxidized

- `OXIDIZED_USERNAME`
- `OXIDIZED_PASSWORD`
- `LIBRENMS_API_TOKEN`

### Akvorado Stack

- `AKVORADO_SNMP_COMMUNITY`

## Render Commands

LibreNMS and Oxidized:

```bash
sudo /opt/docker-stacks/nms-stack/scripts/render-nms-secrets.sh
cd /opt/docker-stacks/nms-stack
docker compose --env-file /run/nms-stack.env up -d
sudo rm -f /run/nms-stack.env
```

Graylog:

```bash
sudo /opt/graylog-stack/scripts/render-graylog-secrets.sh
cd /opt/graylog-stack
docker compose --env-file /run/graylog-stack.env up -d
sudo rm -f /run/graylog-stack.env
```

Akvorado:

```bash
sudo /opt/docker/akvorado/scripts/render-akvorado-secrets.sh
cd /opt/docker/akvorado
docker compose --env-file /run/akvorado.env up -d
sudo rm -f /run/akvorado.env
```

## Bootstrap Token Permissions

```bash
sudo mkdir -p /etc/1password
sudo chown root:root /etc/1password
sudo chmod 700 /etc/1password
sudo chmod 600 /etc/1password/*.token
```

## Limitations

Database passwords, Graylog secrets, Oxidized credentials, and SNMP community values need service restarts after re-rendering.

If a secret is stored inside an application database rather than an env/config file, rotate it inside the application first, then update the reference copy in 1Password.
