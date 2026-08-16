# PowerDNS HA Design

## Goal

Run resilient DNS resolvers across Docker VMs in two groups:

- Lab DNS cluster: `10.20.99.39`, `10.20.99.40`
- Home-prod DNS cluster: `10.20.99.33` through `10.20.99.36`

AD DNS remains authoritative for Active Directory DNS. PowerDNS is the
writable local source for the internal split view of public app names.

## DNS Authority Model

| Zone | Public/Internal | Primary | PowerDNS role |
|---|---|---|---|
| `tape.local` | Internal only | AD DNS | Secondary |
| `jestertek.cc` | Split zone | Cloudflare/public DNS externally, PowerDNS internally | Native primary for internal app records |

## Runtime Model

Each node runs:

```text
client -> pdns-recursor:53 -> pdns-auth:5300 -> local authoritative data
```

For non-internal names:

```text
client -> pdns-recursor:53 -> normal internet recursion
```

## HA Model

The first version uses multiple independent DNS nodes rather than a shared database or VIP.

Clients should receive at least two DNS server IPs:

- one from the local/preferred cluster
- one fallback from the other cluster if desired

This is simple and failure-tolerant for resolvers. The first node uses a local
MariaDB backend so Poweradmin can write internal `jestertek.cc` app records.

## GUI Model

Poweradmin runs beside PowerDNS and manages records through the PowerDNS API.

- Poweradmin: `http://<dns-node>:9191`
- PowerDNS API/webserver: local node port `8081`
- PowerDNS authoritative listener: port `5300`
- PowerDNS recursor listener for clients: port `53`

Only `jestertek.cc` should normally be edited in the GUI. Keep `tape.local`
owned by AD DNS so domain controller registrations and AD service records stay
boring and reliable.

## Future Options

- Add `dnsdist` in front of the recursors if a DNS VIP is desired.
- Add keepalived VRRP VIPs per cluster if the network design supports it.
- Add reverse-zone replication after confirming AD reverse zone names.
- Add LibreNMS service checks for TCP/UDP 53 and PowerDNS webserver ports.
