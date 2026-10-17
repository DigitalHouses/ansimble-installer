#!/usr/bin/env bash
# Public DigitalHouses bootstrap. Private deployment code is not mirrored here.
set -Eeuo pipefail
umask 077

SITE="${1:-}"
RELEASE="d6021a5c34a2f470b2dab4f3d4292f2e84412734"
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
  "repos/DigitalHouses/ansimble-2.0/contents/bootstrap/semaphore-launch.sh?ref=$RELEASE" \
  > "$WORK/release.json"

python3 - "$WORK/release.json" "$WORK/private-launch.sh" "$RELEASE" <<'PY'
import base64, hashlib, json, os, pathlib, sys
source, target, revision = map(pathlib.Path, sys.argv[1:3]) if False else (pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3])
record = json.loads(source.read_text())
if record.get("type") != "file" or record.get("encoding") != "base64":
    raise SystemExit("BLOCKED: private bootstrap file missing")
blob = base64.b64decode(record["content"])
identity = hashlib.sha1(b"blob " + str(len(blob)).encode() + b"\0" + blob).hexdigest()
if identity != record.get("sha"):
    raise SystemExit("BLOCKED: private bootstrap Git blob mismatch")
marker = b"__RELEASE_COMMIT__"
if blob.count(marker) != 1:
    raise SystemExit("BLOCKED: private bootstrap release marker mismatch")
content = blob.replace(marker, revision.encode("ascii"))
fd = os.open(target, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o700)
with os.fdopen(fd, "wb") as output:
    output.write(content)
print("PRIVATE_LAUNCHER_SOURCE=VERIFIED")
PY

echo "=== HANDOFF TO PINNED PRIVATE INSTALLER ==="
echo "NOTE: the private pilot launcher currently requires another GitHub device confirmation."
bash "$WORK/private-launch.sh" "$SITE"
echo "=== DONE ==="
