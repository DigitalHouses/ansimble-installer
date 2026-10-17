# DigitalHouses · Ansimble Runner Installer

**Public network entrypoint only.** The installer provisions a local Ansimble-2 runner with Semaphore as its only Web UI. The actual installer, Ansible roles, site inventories, and Fleet Vault are kept in the **private** `DigitalHouses/ansimble-2.0` repository.

## One command · clean PVE

Use a **trusted root terminal on Proxmox VE**, after initial PVE LAN configuration. For the Home pilot (`site=home`), this command uses an immutable public Git commit:

```bash
bash -c 'set -Eeuo pipefail; src=$(curl -fsSL --retry 2 https://raw.githubusercontent.com/DigitalHouses/ansimble-installer/a592795bf0dfec9f9e188a132c4f607c7aec17d5/install.sh); test -n "$src"; bash -c "$src" -- home'
```

The command preserves terminal input for the owner's hidden Fleet Vault password and explicit CT confirmation. It downloads the installer over HTTPS directly from GitHub, **without** manual ZIP, file transfer, or an existing GitHub CLI installation on PVE. Do not pipe the script into `bash` because later interactive prompts require terminal input. Always pin the public commit; do not execute mutable `main` as root.

## Expected flow

1. `install.sh` checks root/PVE identity and obtains a SHA256-pinned official GitHub CLI in disposable, root-only storage.
2. The owner opens [GitHub device sign-in](https://github.com/login/device) on their **own device**, approves access and completes 2FA there. The engineer must not ask for their GitHub password or OTP.
3. The script downloads the private installer from a **fixed private Git commit**, verifies its independently pinned Git blob and hands off the existing authorized GitHub session.
4. The private installer checks PVE, LAN, reserved CTID 1231/IP `.231`, Git revision and the operator-held Fleet Vault master password before performing any PVE guest changes.
5. Following explicit `CREATE CT1231` approval, it creates a fresh Debian 13 LXC runner, installs Ansible Core and Semaphore, and prepares initial read-only tasks. No separate DigitalHouses Web UI.

The initial Semaphore URL for the Home pilot is `https://192.168.11.231:3000/`.

## Release status

**First E2E pilot, not yet accepted on a real PVE.** Public loader CI tests PVE safety gates and shell syntax; private repository CI additionally tests a live Semaphore 2.19 API server. The full unattended fresh-CT installation, private Git checkout and first human login must still pass Home E2E. On error, **do not rerun blindly**: inspect the actual CT and GitHub deploy keys.

The public loader pins:
- Private installer commit: `75b37e1639d1d3553eaccc0eef478269f73298ae` (tested source).
- Private installer blob: `48827e2ba835c9d21c16d64e360d2b53970027e1`.
- Official GitHub CLI: 2.102.0 with independently pinned SHA-256.

This repository does not contain the private installer; it performs GitHub authorization and **verified transfer** only. Changes to deployment logic happen in the private repository and require a new, reviewed pinned public release.

## Security and trust

No credentials, API tokens, PVE private keys, inventories, customer-specific network information, Cloudflare tunnel configurations or Fleet Vault material may be committed here.

The initial GitHub login and Fleet Vault password must be entered **by the owner using a trusted terminal/device**. An engineer with ongoing root access to PVE can inspect runtime secrets; GitHub 2FA alone does not protect against an untrusted PVE root operator.

Public source: [DigitalHouses/ansimble-installer](https://github.com/DigitalHouses/ansimble-installer). Private source of truth: `DigitalHouses/ansimble-2.0`.
