# PowerDNS Operations

## Start Stack

```bash
cd /opt/docker-stacks/powerdns-stack
sudo ./scripts/render-powerdns-env.sh
sudo docker compose --env-file /run/powerdns-stack.env up -d
sudo rm -f /run/powerdns-stack.env
```

## Check Containers

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E 'pdns|poweradmin'
docker logs --tail 100 pdns-auth
docker logs --tail 100 pdns-recursor
docker logs --tail 100 poweradmin
```

## Check Authoritative Zone Replication

```bash
dig @127.0.0.1 -p 5300 tape.local SOA
dig @127.0.0.1 -p 5300 jestertek.cc SOA
```

PowerDNS 5 may report a `pdnsutil zone check tape.local` warning for AD-owned
delegation records such as `_msdcs.tape.local`. Treat actual `dig` answers as
the first operational check for transferred AD zones.

Do not use `pdnsutil zone check` as the container healthcheck when the SQL
backend password is injected at runtime. Use the control socket instead:

```bash
docker exec pdns-auth pdns_control list >/dev/null
```

## Check Client Resolver Behavior

```bash
dig @127.0.0.1 tape.local SOA
dig @127.0.0.1 jestertek.cc SOA
dig @127.0.0.1 cloudflare.com A
```

## Refresh Zone Transfers

```bash
docker exec pdns-auth pdns_control retrieve tape.local
```

`jestertek.cc` is a native SQL-backed zone on the PowerDNS node, so it is not
refreshed from AD.

If `tape.local` was previously refused by AD, restarting `pdns-auth` also
forces a fresh transfer attempt:

```bash
docker restart pdns-auth
```

If a failed lookup was cached during a transfer problem:

```bash
docker exec pdns-recursor rec_control wipe-cache tape.local
docker exec pdns-recursor rec_control wipe-cache dc1.tape.local
```

## Poweradmin

Poweradmin is available on:

```text
http://10.20.60.11:9191
```

Use it for internal `jestertek.cc` records. Leave `tape.local` changes in AD
DNS unless there is a deliberate AD DNS migration later.

The initial admin account is created from the stack environment file:

```bash
sudo grep '^POWERADMIN_ADMIN_USER=' /opt/docker-stacks/powerdns-stack.env
```

## Add Reverse Zones

If AD DNS has reverse lookup zones, add them to:

```text
auth/bind/named.conf
recursor/recursor.d/recursor.conf
```

Example:

```text
zone "60.20.10.in-addr.arpa" {
  type secondary;
  primaries { 10.20.60.10; 10.20.60.14; };
  file "60.20.10.in-addr.arpa.zone";
};
```

Then add the recursor forward:

```text
forward-zones+=60.20.10.in-addr.arpa=127.0.0.1:5300
```

Restart the stack after editing.
