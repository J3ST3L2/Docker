# ARR Configuration Model

The ARR stack should be managed as desired state plus secret references.

## Sources Of Truth

- GitHub: Compose files, config examples, non-secret variables, render scripts, and documentation.
- 1Password: VPN credentials, application passwords, API keys, and tokens.
- Docker host: runtime state only.

## Change Workflow

1. Edit non-secret desired state in `vars/arr.yml` or the stack files.
2. Edit secret values in the `ARR Stack` item in 1Password.
3. Run `/secrets-test target:arr` from Discord.
4. Run `/redeploy target:arr` from Discord.
5. Commit and push the sanitized repo changes.

## Variable File

`vars/arr.yml` documents the target host, stack path, render script, published ports, mount paths, and 1Password references.

The file intentionally stores only secret references such as:

```text
op://JesterTek/ARR Stack/PIA_USER
op://JesterTek/ARR Stack/PIA_PASS
```

## Runtime Render

The render script reads:

```text
/etc/1password/arr-stack.token
```

It renders:

```text
/run/arr-stack.env
```

The env file is used by Docker Compose and deleted after Discord-triggered redeploys.

## Rule

If a value is sensitive or would require rotation if exposed, it belongs in 1Password. If a value describes structure, ports, paths, images, or repeatable behavior, it belongs in GitHub.
