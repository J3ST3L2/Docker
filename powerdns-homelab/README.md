# PowerDNS Homelab HA

Git-backed desired state for internal PowerDNS resolvers, authoritative DNS,
and the Poweradmin DNS management GUI.

## Purpose

Provide highly available DNS resolvers in the home lab while keeping Active
Directory DNS authoritative for AD records and giving us a simple GUI for local
app DNS.

- `tape.local` is AD-owned internal DNS.
- `jestertek.cc` is public externally, but has an internal split-zone view in PowerDNS.
- PowerDNS authoritative containers replicate `tape.local` from AD DNS via AXFR.
- PowerDNS authoritative containers host `jestertek.cc` as a native SQL-backed zone.
- PowerDNS recursor containers listen on port 53 for clients and forward internal zones to the local authoritative container.
- Poweradmin provides the web GUI for creating internal `jestertek.cc` records.

## Target Nodes

Lab DNS cluster:

- `10.20.99.39`
- `10.20.99.40`

Home-prod DNS cluster:

- `10.20.99.33`
- `10.20.99.34`
- `10.20.99.35`
- `10.20.99.36`

## Stack Layout

```text
/opt/docker-stacks/powerdns-stack
```

Each DNS node runs the same stack:

- `pdns-db`: MariaDB backend for native zones and Poweradmin.
- `pdns-auth`: authoritative DNS, listens on `5300/tcp` and `5300/udp`.
- `pdns-recursor`: recursive resolver for clients, listens on `53/tcp` and `53/udp`.
- `poweradmin`: DNS management GUI, listens on `9191/tcp`.

## Why This Shape

The first version keeps each DNS node independent. Clients get HA by receiving
multiple DNS server IPs from DHCP or static DNS settings. `tape.local` remains
boring AD DNS. Internal `jestertek.cc` records are managed in Poweradmin and
served locally so app traffic stays on-net instead of hairpinning out through
public DNS and ZT relay paths.

## Deploying

1. Copy `stacks/powerdns-stack` to `/opt/docker-stacks/powerdns-stack` on each target DNS VM.
2. Render `/run/powerdns-stack.env` from 1Password or create it from `.env.example`.
3. Start the stack:

```bash
cd /opt/docker-stacks/powerdns-stack
sudo docker compose --env-file /run/powerdns-stack.env up -d
```

## AD DNS Requirements

On the AD DNS primary zone, allow zone transfers and notify the PowerDNS node IPs.

Zones:

- `tape.local`

PowerDNS secondary IPs:

```text
10.20.99.39
10.20.99.40
10.20.99.33
10.20.99.34
10.20.99.35
10.20.99.36
```

## Verification

From a DNS node:

```bash
dig @127.0.0.1 -p 5300 tape.local SOA
dig @127.0.0.1 tape.local SOA
dig @127.0.0.1 dc1.tape.local A
dig @127.0.0.1 jestertek.cc SOA
dig @127.0.0.1 ns1.jestertek.cc A
dig @127.0.0.1 dns.jestertek.cc A
dig @127.0.0.1 cloudflare.com A
```

From any lab client:

```bash
dig @10.20.99.39 tape.local SOA
dig @10.20.99.40 tape.local SOA
dig @10.20.99.33 jestertek.cc SOA
dig @10.20.99.36 cloudflare.com A
```

## Notes

Because `jestertek.cc` is split, the internal PowerDNS zone must contain any
public records that internal clients still need. If the internal `jestertek.cc`
zone does not include a record, internal clients will get the internal zone's
answer, not the public internet answer.
