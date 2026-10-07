# Sandbox module (optional)

An opt-in container layer for running an AI coding assistant with limited
blast radius. It complements the governance rules and hooks: those try to
prevent bad actions, the sandbox limits the damage when one gets through.

**Status: scaffold.** `devcontainer.json` works today (tested with Claude
Code in VS Code). `Dockerfile` and `init-firewall.sh` are empty placeholders.

| File | Purpose | State |
|---|---|---|
| `devcontainer.json` | Base image, Node + Claude Code features, per-project config volume, non-root user | Working |
| `Dockerfile` | Custom image if a project needs tooling beyond the base image | Empty, reserved |
| `init-firewall.sh` | Default-deny outbound firewall driven by `allowed-domains.txt` | Empty, reserved |
| `allowed-domains.txt` | Editable outbound allowlist | Stub |

## Design intent
- Non-root user; no host home directory or credential mounts.
- Assistant config and login live in a named volume, not on the host.
- Optional egress firewall: default deny, domain allowlist, fail closed,
  no blanket outbound SSH. Needs `NET_ADMIN` and `NET_RAW` in `runArgs`
  when enabled.
- Written from scratch. Anthropic's reference container is proprietary
  ("All rights reserved"), so none of its files are copied here. See
  https://code.claude.com/docs/en/devcontainer for their reference.

## Usage (manual, until the installer supports it)
Copy `devcontainer.json` to `<project>/.devcontainer/devcontainer.json`, then
run **Dev Containers: Reopen in Container** in VS Code. See
`docs/SANDBOX_THREAT_MODEL.md` in the project repository (it is not shipped
inside the plugin) for what this does and does not protect.
