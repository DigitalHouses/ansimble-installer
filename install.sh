#!/usr/bin/env bash
# Public DigitalHouses bootstrap. Private deployment code is not mirrored here.
set -Eeuo pipefail
umask 077

SITE="${1:-}"
RELEASE="8e1d36ae9ed30d6b2249981a2378b27c99f3c791"
PRIVATE_INSTALLER_BLOB="6149088623debbf4ab8744631921ea164579a174"
GH_VERSION="2.102.0"
GH_SHA256="bb766f710eef8ede859c18578c72c327597cd4c8a85b06001b1f3843c6019386"

if (( $# != 1 )) || [[ ! "$SITE" =~ ^[a-z][a-z0-9_-]{0,30}$ ]]; then
  echo "BLOCKED: usage: install.sh <site-id>" >&2
  exit 2
fi
if (( EUID != 0 )) || [[ ! -f /etc/pve/user.cfg ]]; then
  echo "BLOCKED: root terminal on Proxmox VE required" >&2
  exit 2
fi

WORK=$(mktemp -d /root/ansimble-network.XXXXXX)
trap 'rc=$?; rm -rf "$WORK"; echo "RESULT_RC=$rc"; echo "TERMINAL STAYS OPEN"' EXIT
mkdir -m 700 "$WORK/gh-config"

echo "=== DIGITALHOUSES · PUBLIC NETWORK BOOTSTRAP ==="
echo "PRIVATE_RELEASE=$RELEASE"
curl -fsSL --max-time 120 \
  "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" \
  -o "$WORK/gh.tgz"
printf '%s  %s\n' "$GH_SHA256" "$WORK/gh.tgz" | sha256sum -c -
tar -xzf "$WORK/gh.tgz" -C "$WORK" "gh_${GH_VERSION}_linux_amd64/bin/gh"
export PATH="$WORK/gh_${GH_VERSION}_linux_amd64/bin:$PATH"
export GH_CONFIG_DIR="$WORK/gh-config"
export BROWSER=false
unset GH_TOKEN GITHUB_TOKEN || true

echo "=== OWNER · AUTHORIZE IN YOUR OWN BROWSER ==="
echo "https://github.com/login/device"
gh auth login --web --git-protocol https
gh auth status >/dev/null

echo "=== FETCH IMMUTABLE PRIVATE BOOTSTRAP ==="
gh api \
  "repos/DigitalHouses/ansimble-2.0/contents/bootstrap/semaphore-host-install.py?ref=$RELEASE" \
  > "$WORK/release.json"

python3 - "$WORK/release.json" "$WORK/private-install.py" "$PRIVATE_INSTALLER_BLOB" <<'PY'
import base64, hashlib, json, os, pathlib, sys
source, target, expected_sha = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
record = json.loads(source.read_text())
if record.get("type") != "file" or record.get("encoding") != "base64":
    raise SystemExit("BLOCKED: private installer source missing")
blob = base64.b64decode(record["content"])
identity = hashlib.sha1(b"blob " + str(len(blob)).encode() + b"\0" + blob).hexdigest()
if identity != expected_sha or record.get("sha") != expected_sha:
    raise SystemExit("BLOCKED: private installer immutable Git identity mismatch")
fd = os.open(target, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o700)
with os.fdopen(fd, "wb") as output:
    output.write(blob)
print("PRIVATE_INSTALLER_SOURCE=VERIFIED")
PY

echo "=== READ NETWORK CONFIGURATION ==="
BRIDGE_IP=$(ip -4 -o addr show dev vmbr0 | awk '$3=="inet" {print $4}')
DEFAULT_GW=$(ip -4 route show default | awk '$1=="default" && $2=="via" {print $3}')
readarray -t NETWORK < <(python3 - "$BRIDGE_IP" "$DEFAULT_GW" <<'PY'
import ipaddress,sys
try:
    interface = ipaddress.IPv4Interface(sys.argv[1])
    gateway = ipaddress.IPv4Address(sys.argv[2])
    assert interface.network.prefixlen == 24
    assert gateway in interface.network
    address = ipaddress.IPv4Address(int(interface.network.network_address) + 231)
    assert address != interface.ip and address != gateway
except (IndexError, ValueError, AssertionError):
    raise SystemExit("BLOCKED: unsupported or ambiguous PVE LAN")
print(interface.ip)
print(str(address) + "/24")
print(gateway)
PY
)
if (( ${#NETWORK[@]} != 3 )); then
  echo "BLOCKED: PVE network resolution failed" >&2; exit 2
fi
echo "PVE=${NETWORK[0]} RUNNER=${NETWORK[1]}"
echo "=== RUN PINNED PRIVATE INSTALLER ==="
python3 "$WORK/private-install.py" \
  --site "$SITE" \
  --pve-ip "${NETWORK[0]}" \
  --runner-cidr "${NETWORK[1]}" \
  --gateway "${NETWORK[2]}" \
  --expected-commit "$RELEASE" \
  --use-github-session --apply

echo "=== DONE ==="
