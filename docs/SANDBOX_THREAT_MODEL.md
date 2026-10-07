# Sandbox threat model

**Status: stub.** To be written before the sandbox module is announced as
a security feature. Outline:

## What the sandbox protects against
- Commands the assistant runs affecting the host outside the project folder
- Host credentials and config being readable or modifiable from the session

## What it does NOT protect against
- Changes to the project folder itself (it is bind-mounted read-write; use git)
- Exfiltration of anything reachable inside the container, including the
  assistant's own credentials, unless the egress firewall is enabled and tight
- Anything granted by loosened config: host mounts, the Docker socket,
  open network, running as root

## Assumptions and requirements
- Docker running; non-root container user
- Trusted repositories only when running without permission prompts

## Open questions
- Default network policy: firewall on or off?
- Which domains belong in the baseline allowlist?
