# Dockge Homelab

Git-backed desired state and runbook for Dockge on the homelab Docker hosts.

Dockge is used as a lightweight GUI for Docker Compose stacks. Git remains the
source of truth; Dockge is the operational UI for inspecting, starting,
stopping, updating, and reading logs from compose stacks.

## Hosts

| Host | Role | URL |
|---|---|---|
| `docker2` / `10.20.60.17` | Main Dockge UI | `http://10.20.60.17:5001` |
| `nms` / `10.20.60.15` | Dockge agent | `http://10.20.60.15:5001` |
| `ddocker` / `10.20.60.13` | Dockge agent | `http://10.20.60.13:5001` |
| `ddi` / `10.20.60.11` | Dockge agent | `http://10.20.60.11:5001` |

## Stack Directory

All hosts use:

```text
/opt/docker-stacks
```

Dockge data is stored in:

```text
/opt/dockge/data
```

## First Login

Open:

```text
http://10.20.60.17:5001
```

Create the initial admin account.

Then add agents in Dockge:

```text
docker2  http://10.20.60.17:5001
nms      http://10.20.60.15:5001
ddocker  http://10.20.60.13:5001
ddi      http://10.20.60.11:5001
```

## GitOps Rule

Use GitHub as source of truth:

```text
GitHub repo -> compose files/env templates -> deploy to /opt/docker-stacks
```

Use Dockge for:

- viewing stack state
- logs
- one-off restarts
- image updates after reviewing desired state
- quick edits that should be copied back into Git

Do not let Dockge become the only place a compose change exists.
