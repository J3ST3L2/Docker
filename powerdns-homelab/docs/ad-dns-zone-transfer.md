# AD DNS Zone Transfer Setup

PowerDNS should be read-only secondaries for AD-owned zones.

## Zones

- `tape.local`
- internal split-zone `jestertek.cc`

## Secondary Servers

```powershell
$PowerDnsSecondaries = @(
  '10.20.99.39',
  '10.20.99.40',
  '10.20.99.33',
  '10.20.99.34',
  '10.20.99.35',
  '10.20.99.36'
)
```

## Configure Zone Transfers

Run on a domain controller with the DNS Server PowerShell module:

```powershell
$PowerDnsSecondaries = @(
  '10.20.99.39',
  '10.20.99.40',
  '10.20.99.33',
  '10.20.99.34',
  '10.20.99.35',
  '10.20.99.36'
)

foreach ($Zone in @('tape.local', 'jestertek.cc')) {
  Set-DnsServerPrimaryZone `
    -Name $Zone `
    -SecureSecondaries TransferToSecureServers `
    -SecondaryServers $PowerDnsSecondaries `
    -Notify NotifyServers `
    -NotifyServers $PowerDnsSecondaries
}
```

## Firewall Requirements

AD DNS primaries to PowerDNS secondaries:

- UDP/53 for notify and queries.
- TCP/53 for AXFR zone transfers.

PowerDNS nodes to AD DNS primaries:

- UDP/53 for SOA checks.
- TCP/53 for AXFR zone transfers.

Clients to PowerDNS recursors:

- UDP/53
- TCP/53

## Split-Zone Reminder

If `jestertek.cc` is configured as an internal AD DNS zone, internal clients will use that zone instead of public DNS for `jestertek.cc`.

Make sure the internal zone contains records for services internal clients need, such as:

```text
plex.jestertek.cc
git.jestertek.cc
vpn.jestertek.cc
```

or whatever names should resolve internally.
