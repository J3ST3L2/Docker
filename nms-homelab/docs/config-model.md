# NMS Configuration Model

The monitoring platform should be managed as desired state plus secret references.

## Sources Of Truth

- GitHub: Compose files, example configs, non-secret variables, templates, render scripts, and documentation.
- 1Password: database passwords, API tokens, Graylog secrets, Oxidized credentials, and SNMP communities.
- Docker hosts: runtime state only.

## Variable Files

```text
vars/nms.yml
vars/graylog.yml
vars/akvorado.yml
```

These files describe host paths, images, ports, render scripts, and 1Password references. They should not contain live secret values.

## Template Files

```text
stacks/nms-stack/.env.tpl
stacks/nms-stack/oxidized/config.tpl
stacks/graylog-stack/.env.tpl
stacks/akvorado/.env.tpl
stacks/akvorado/config/outlet.yaml.tpl
```

Templates use `op://` references that are resolved on the target host by `op inject`.

## Change Workflow

1. Edit non-secret desired state in GitHub.
2. Edit secret values in 1Password.
3. Run the matching `/secrets-test` Discord command.
4. Run the matching `/redeploy` Discord command.
5. Confirm Docker health and application behavior.
6. Commit and push sanitized repo changes.

## Rule

If a value is sensitive or would require rotation if exposed, it belongs in 1Password. If a value describes structure, ports, paths, images, or repeatable behavior, it belongs in GitHub.
