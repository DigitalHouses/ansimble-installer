#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."

bash -n install.sh
echo "BASH_SYNTAX=PASS"

# These checks must return BLOCKED before any download/login/write.
for args in "" "wrong/site" "a b" "home --unknown" "home --resume --apply"; do
  if bash install.sh $args >/tmp/dh-installer-negative.log 2>&1; then
    echo "FAIL: unexpected success with malformed site: $args" >&2
    exit 1
  fi
done
echo "INVALID_ARGUMENT_GATE=PASS"

# Generic CI is not a Proxmox host; do not attempt OAuth or guest creation.
if [[ ! -f /etc/pve/user.cfg ]]; then
  if bash install.sh home >/tmp/dh-installer-negative.log 2>&1; then
    echo "FAIL: non-PVE machine was allowed to proceed" >&2
    exit 1
  fi
  grep -q "root terminal on Proxmox VE required" /tmp/dh-installer-negative.log
fi
echo "PVE_HOST_GATE=PASS"

python3 - <<'PY'
from pathlib import Path
s=Path("install.sh").read_text()
assert "DUMMY" not in s
assert 'sha256sum -c -' in s
assert 'gh auth login --web' in s
assert '--use-github-session --apply' in s
assert 'PRIVATE_INSTALLER_BLOB=' in s
assert 'GH_CONFIG_DIR="$WORK/gh-config"' in s
assert 'secrets/fleet.vault.yml' not in s
assert 'pct destroy' not in s
assert 'pct create' not in s
assert 'readarray -t NETWORK' in s
assert 'RESUME_ARGS=(--resume)' in s
assert 'RESUME_ARGS=(--resume-ansible)' in s
assert '--apply "${RESUME_ARGS[@]}"' in s
assert 'expected_sha' in s
assert 'record.get("sha") != expected_sha' in s
files = list(Path().rglob("*"))
assert not any(p.name.endswith((".p12", ".pem", ".key", ".vault.yml")) for p in files if p.is_file())
print("MINIMAL_PUBLIC_LOADER_POLICY=PASS")
PY
echo "DONE"
