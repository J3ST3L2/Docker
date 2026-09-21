# Middlebury Mist -> Vector -> Keep

This stack replaces the homegrown Mist polling/normalization path with a vendor-aligned push model:

```text
Juniper Mist organization-level Alerts webhook
        |
        v
keep.middlebury.edu/mist-webhook
        |
        v
Nginx
        |
        v
Vector on 127.0.0.1:8686
        |
        v
Keep API on 127.0.0.1:8088/alerts/event
```

## Design goals

- No Mist API polling loop.
- No Raccoon alert broker dependency.
- No custom Python service.
- One organization-level Mist Alerts webhook.
- Vector only performs transport, batch splitting, field normalization, lifecycle mapping, buffering, and retry.
- Keep owns alert state, deduplication, incidents, workflows, and downstream notifications.

## Prerequisites

The current Keep deployment on Gravitron must already have:

- Keep frontend reachable through Nginx.
- Keep backend healthy on `127.0.0.1:8088`.
- Nginx serving `keep.middlebury.edu`.
- Docker Compose available.

This stack deliberately uses Linux host networking so Vector can reach the localhost-only Keep backend without reopening port 8088.

## Install

On Gravitron:

```bash
cd /opt/stacks
git clone https://github.com/J3ST3L2/Docker.git keep-mist-repo
cd keep-mist-repo/middlebury/keep-mist-vector

cp .env.example .env
openssl rand -hex 32
```

Put the generated value into:

```text
MIST_WEBHOOK_PASSWORD=<generated value>
```

Then:

```bash
chmod 600 .env
sudo ./scripts/install.sh
```

If the repository is already cloned elsewhere, copy or rsync this directory into `/opt/stacks/keep-mist-vector` instead of cloning a second copy.

## Nginx

Add the contents of:

```text
nginx/keep-mist-location.conf
```

inside the existing `server_name keep.middlebury.edu;` server block.

Then:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

The public endpoint will be:

```text
http://keep.middlebury.edu/mist-webhook
```

When TLS is enabled later, the same path becomes:

```text
https://keep.middlebury.edu/mist-webhook
```

No Vector change is required for that transition.

## Local pipeline test

Before touching Mist:

```bash
cd /opt/stacks/keep-mist-vector
./scripts/test-local.sh
```

A successful request should result in a Keep alert for:

```text
TEST-AP-01
```

Inspect Vector:

```bash
docker compose logs -f vector
```

Inspect Keep:

```bash
cd /opt/stacks/keep
sudo docker compose logs --tail=100 keep-backend
```

## Mist organization-level webhook

In the Mist organization settings, create one webhook for the **Alerts** topic.

Use the Keep endpoint:

```text
https://keep.middlebury.edu/mist-webhook
```

For the current HTTP-only testing phase use the HTTP URL temporarily. Do not send reusable Basic credentials over an untrusted network without TLS.

Vector uses HTTP Basic Authentication for the receiver. Configure Mist to send an `Authorization` header containing:

```text
Basic base64(MIST_WEBHOOK_USERNAME:MIST_WEBHOOK_PASSWORD)
```

The default username is `mist`. The password belongs only in `.env` on Gravitron and the Mist webhook configuration. Never commit it.

### Initial topic selection

Start with **Alerts only**.

Do not enable both `device-events` and `device-updowns` during the initial rollout because they overlap and can create duplicate event streams.

## Normalization

Mist webhook envelopes may contain an `events[]` array. Vector unnests that array so each Mist event becomes one Keep event.

The transform produces Keep fields including `name`, `status`, `severity`, `lastReceived`, `service`, `source`, `message`, `description`, `fingerprint`, and `labels`.

Keep receives each normalized alert at:

```text
POST http://127.0.0.1:8088/alerts/event
```

### Lifecycle mapping

The initial mapping is intentionally conservative:

- Mist `details.state=validated` -> Keep `resolved`.
- Mist resolved/cleared/reconnected/up-style event types -> Keep `resolved`.
- Everything else -> Keep `firing`.

The fingerprint canonicalizes recovery words back to the corresponding active event family so a recovery can update the same logical Keep alert.

Real Middlebury Mist payloads should be captured during rollout and the mapping refined from actual data rather than growing a pile of guessed vendor fields.

## Reliability

Vector is configured with end-to-end acknowledgements, a 256 MiB disk buffer, one event per Keep HTTP request, and retry handling for temporary Keep failures.

The point is to make Vector boring infrastructure plumbing, not another alert application.

## Security

Current phase:

- Vector listens only on `127.0.0.1:8686`.
- Docker uses host networking only so Vector can reach Keep on localhost.
- Nginx is the only network-facing receiver.
- Credentials live in `.env`, not Git.

Production target:

- HTTPS on `keep.middlebury.edu`.
- Mist certificate verification enabled.
- Mist webhook signing with the current `X-Mist-Signature-v2` mechanism can be added after the first real payload is captured and verified end-to-end.
- Keep authentication should be enabled before the service is broadly reachable.

## Rollout sequence

1. Start Vector locally.
2. Run `scripts/test-local.sh`.
3. Confirm the synthetic alert reaches Keep.
4. Add the Nginx location.
5. Test through Nginx.
6. Configure the org-level Mist Alerts webhook.
7. Capture real Mist payloads.
8. Tune lifecycle/fingerprint mapping from those payloads.
9. Observe alongside the legacy path temporarily.
10. Retire the Raccoon Mist poller/broker path after confidence is established.
