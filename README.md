# DigitalHouses · Ansimble Runner Installer

**Public distribution only.** This repository contains the initial PVE launcher. The actual infrastructure code, Ansible roles, inventories, and encrypted Fleet Vault remain in the private repository `DigitalHouses/ansimble-2.0`.

## Installation contract

On a **trusted clean Proxmox VE host** the engineer executes one network command. The installer:

1. Verifies the pinned official GitHub CLI download before running it.
2. Requests the DigitalHouses owner's GitHub **device authorization with 2FA** in a trusted browser; never asks for GitHub password or OTP in the PVE terminal.
3. Fetches the private Ansimble-2 installer **from a fixed Git commit**, validates the Git blob, and asks the owner to enter their Fleet Vault master password in a trusted root terminal.
4. After independent checks and explicit `CREATE CT1231 ...` confirmation, creates a fresh runner and installs Ansible + Semaphore.
5. Configures Semaphore as the **only Web UI**, initially with read-only smoke/audit tasks.

**This is a first-pilot release, not yet production-accepted on a real PVE.** Do not run on a production host without the owner's explicit E2E acceptance. No background services or databases are installed by this *distribution repository* itself.

## Source and releases

- `install.sh` is a **generated immutable build output** of the private repository's canonical `bootstrap/semaphore-launch.sh`. Do not maintain a separate implementation here.
- Trusted source release commit: `d6021a5c34a2f470b2dab4f3d4292f2e84412734`.
- The initial publication must be verified with `bash -n`, a pinned SHA-256 of the release script, and read-only CI before allowing real PVE writes.
- Bootstrap requires PVE root, an available standard Debian 13 template, a free reserved CTID 1231 and IPv4 `.231` on `vmbr0`, and safe fleet credentials.
- Owner's root terminal must be trusted: an engineer with PVE root can inspect runtime secrets. GitHub 2FA alone cannot prevent that.

## Security

**Never add to this repository:** site inventories, credentials, tokens, SSH private keys, decrypted or encrypted Fleet Vault, customer-specific network configuration, Cloudflare tunnel details, or copies of private repository history.

The contents are public and must remain free of secrets. Use immutable release revisions when fetching code over HTTPS; **do not run an unverified mutable `main` script as root**.

Source of truth: `DigitalHouses/ansimble-2.0`. The two repositories have separate responsibilities: public distribution, private orchestration.
