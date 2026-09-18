# Keep Home Alerting

Home deployment of [Keep](https://github.com/keephq/keep) as the alert workflow and notification layer for the homelab.

## Target architecture

```text
LibreNMS ---------+
                  |
Zabbix (later) ---+--> Keep --> Slack
                  |       +--> Discord / ntfy / on-call later
Watchtower -------+
```

The existing direct LibreNMS -> Slack webhook stays enabled during rollout. Keep is added in parallel until firing, recovery, deduplication, and formatting are proven.

## Deployment target

- Docker/Dockge host: `10.20.60.15`
- Keep UI: `http://10.20.60.15:3100`
- Keep API: `http://10.20.60.15:8180`
- Keep websocket: `10.20.60.15:6101`
- Authentication: local DB auth
- Pilot database: SQLite persisted in `./state`

This stack is intentionally close to Keep's upstream authenticated Docker Compose design, flattened into one Dockge-friendly compose file.

## Deploy with Dockge

1. Create a new Dockge stack named `keep`.
2. Use the contents of `compose.yaml`.
3. Add the variables from `.env.example` to Dockge's environment editor.
4. Replace both `CHANGE_ME` values before deploying.
5. Deploy the stack.
6. Open `http://10.20.60.15:3100`.
7. Sign in using `KEEP_DEFAULT_USERNAME` and `KEEP_DEFAULT_PASSWORD`.

Generate a strong auth secret on any Linux host:

```bash
openssl rand -hex 32
```

Generate a strong initial password:

```bash
openssl rand -base64 24
```

## First integration: LibreNMS -> Keep

Keep has a native LibreNMS provider and supports receiving LibreNMS alerts by webhook.

See [docs/librenms.md](docs/librenms.md).

For rollout, keep the existing direct Slack transport enabled and add Keep as a second transport on a single test rule first.

## Slack

Connect a Slack provider in Keep using the existing incoming webhook or OAuth. Name the provider `home-slack` if you want to import the included example workflow without editing it.

The example workflow is:

`workflows/librenms-slack.yaml`

It is committed disabled on purpose. Import it, verify the provider name and alert fields, then enable it from the Keep UI.

## Persistence

Keep state is stored under:

```text
./state/
```

That directory is ignored by Git.

For the home rollout SQLite keeps the deployment simple. Before copying this design to the college production environment, re-evaluate the database and HA requirements rather than blindly promoting the homelab stack. Civilization has suffered enough from "it worked in my basement."

## Rollout order

1. Deploy Keep.
2. Connect the Keep LibreNMS provider.
3. Create a Keep webhook API key with the webhook role.
4. Add a second LibreNMS API transport pointed at Keep.
5. Send a LibreNMS test alert.
6. Confirm the normalized alert in Keep.
7. Connect the Slack provider.
8. Import/build the LibreNMS -> Slack workflow.
9. Test firing and recovery.
10. Compare Keep's Slack output with the existing direct webhook.
11. Only disable the direct webhook after the new path is proven.
