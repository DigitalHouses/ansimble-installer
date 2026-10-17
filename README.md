# DigitalHouses · Ansimble Runner Installer

**Public network entrypoint only.** The installer provisions a local Ansimble-2 runner with Semaphore as its only Web UI. The actual installer, Ansible roles, site inventories, and Fleet Vault are kept in the **private** `DigitalHouses/ansimble-2.0` repository.

## One command · clean PVE

Use a **trusted root terminal on Proxmox VE**, after initial PVE LAN configuration. For the Home pilot (`site=home`), this command uses an immutable public Git commit:

```bash
bash -c 'set -Eeuo pipefail; src=$(curl -fsSL --retry 2 https://raw.githubusercontent.com/DigitalHouses/ansimble-installer/6e18dde6f0be21935cac0fab6e395b68bfb153b6/install.sh); test -n "$src"; bash -c "$src" -- home'
```

### Resume an existing empty CT1231 after interrupted commissioning

**Only when the initial installer already created CT1231 and stopped before installing Ansible/Semaphore**, add the explicit recovery flag to the same pinned network command:

```bash
bash -c 'set -Eeuo pipefail; src=$(curl -fsSL --retry 2 https://raw.githubusercontent.com/DigitalHouses/ansimble-installer/6e18dde6f0be21935cac0fab6e395b68bfb153b6/install.sh); test -n "$src"; bash -c "$src" -- home --resume'
```

The private installer performs immutable Git authorization, Fleet Vault verification, fresh read-only CT identity/state checks, and a strictly scoped correction of Debian `/etc` permissions (0700 to 0755 only). It fails closed for a VM, an unexpected CT hostname/IP/resources, mounts, a non-running CT, or any partially installed Semaphore runtime. It requires explicit `RESUME CT1231` confirmation before any guest changes. **It never destroys or recreates an existing CT.** If blocked, inspect the actual guest state; do not force or bypass the gate.

### Resume after Ansible is installed but Semaphore has not started

For a **verified CT1231 with the correct Ansible 2.21.4 venv but no Semaphore installation**, for example after an unsupported locale stopped `ansible-playbook --version`, use the distinct explicit recovery stage:

```bash
bash -c 'set -Eeuo pipefail; src=$(curl -fsSL --retry 2 https://raw.githubusercontent.com/DigitalHouses/ansimble-installer/6e18dde6f0be21935cac0fab6e395b68bfb153b6/install.sh); test -n "$src"; bash -c "$src" -- home --resume-ansible'
```

The operator must confirm `RESUME ANSIBLE CT1231`. This mode requires a running CT matching the exact expected hostname, network, storage, resources, owner and access checks. It verifies the existing venv version and dependencies under `C.UTF-8`, rejects Semaphore binaries, database, config, service and incomplete release files, skips reinstalling the Ansible venv, and continues with Semaphore installation and local API seeding. It **never recreates or destroys** the CT.

### Complete an already running Semaphore installation

When the initial admin exists and the HTTPS service is working but the GitHub deploy key/project/templates have not yet been seeded, use a distinct, pinned recovery mode:

```bash
bash -c 'set -Eeuo pipefail; src=$(curl -fsSL --retry 2 https://raw.githubusercontent.com/DigitalHouses/ansimble-installer/6e18dde6f0be21935cac0fab6e395b68bfb153b6/install.sh); test -n "$src"; bash -c "$src" -- home --resume-semaphore'
```

Requires `COMPLETE SEMAPHORE CT1231` confirmation. The private installer checks exact CT identity/resources, pinned Semaphore 2.19.16, TLS health, root-only initial admin credentials, and absence of previous deploy-key artifacts. It tests admin login with the Semaphore API before registering a new read-only GitHub deploy key and seeding the site project. **It does not reinstall Ansible or Semaphore, migrate/delete SQLite, change the admin password, or restart the service.** If the check fails, stop and investigate rather than rerunning a previous stage.

The command preserves terminal input for the owner's hidden Fleet Vault password and explicit CT confirmation. It downloads the installer over HTTPS directly from GitHub, **without** manual ZIP, file transfer, or an existing GitHub CLI installation on PVE. Do not pipe the script into `bash` because later interactive prompts require terminal input. Always pin the public commit; do not execute mutable `main` as root.

## Expected flow

1. `install.sh` checks root/PVE identity and obtains a SHA256-pinned official GitHub CLI in disposable, root-only storage.
2. The owner opens [GitHub device sign-in](https://github.com/login/device) on their **own device**, approves access and completes 2FA there. The engineer must not ask for their GitHub password or OTP.
3. The script downloads the private installer from a **fixed private Git commit**, verifies its independently pinned Git blob and hands off the existing authorized GitHub session.
4. The private installer checks PVE, LAN, reserved CTID 1231/IP `.231`, Git revision and the operator-held Fleet Vault master password before performing any PVE guest changes.
5. Following explicit `CREATE CT1231` approval, it creates a fresh Debian 13 LXC runner, installs Ansible Core and Semaphore, and prepares initial read-only tasks. No separate DigitalHouses Web UI.

The initial Semaphore URL follows the runner's verified site inventory IP at TCP/3000 over HTTPS.

## Release status

**First E2E pilot, not yet accepted on a real PVE.** Public loader CI tests PVE safety gates and shell syntax; private repository CI additionally tests a live Semaphore 2.19 API server. The full unattended fresh-CT installation, private Git checkout and first human login must still pass Home E2E. On error, **do not rerun blindly**: inspect the actual CT and GitHub deploy keys.

The public loader pins:
- Private installer commit: `8ce6bb97b37414300c16871786768cf1532f823d` (tested source).
- Private installer blob: `723c5293ed87bb2720d465f376a2ad72b87b37a7`.
- Official GitHub CLI: 2.102.0 with independently pinned SHA-256.

This repository does not contain the private installer; it performs GitHub authorization and **verified transfer** only. Changes to deployment logic happen in the private repository and require a new, reviewed pinned public release.

## Security and trust

No credentials, API tokens, PVE private keys, inventories, customer-specific network information, Cloudflare tunnel configurations or Fleet Vault material may be committed here.

The initial GitHub login and Fleet Vault password must be entered **by the owner using a trusted terminal/device**. An engineer with ongoing root access to PVE can inspect runtime secrets; GitHub 2FA alone does not protect against an untrusted PVE root operator.

Public source: [DigitalHouses/ansimble-installer](https://github.com/DigitalHouses/ansimble-installer). Private source of truth: `DigitalHouses/ansimble-2.0`.
