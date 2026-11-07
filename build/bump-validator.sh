#!/usr/bin/env bash
# Move the validator pin in build/config.env to the newest release in 6529's
# signed release feed. It downloads releases.json and releases.json.sig and,
# when a validator binary is available (the installed one, or the one in a
# previous build's cache), verifies the feed's signature with it before
# trusting anything in it. Without one it stops, unless --unverified is given.
#
#   build/bump-validator.sh [--unverified] [--version 0.1.0-rc.11]
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
CACHE="${CACHE:-$ROOT/.cache}"
FEED_URL="https://6529.io/validator/releases.json"
unverified=no; want=""
while [ $# -gt 0 ]; do
    case "$1" in
        --unverified) unverified=yes ;;
        --version) want="$2"; shift ;;
        *) echo "unknown flag $1" >&2; exit 2 ;;
    esac; shift
done
mkdir -p "$CACHE/feed"
curl -fsSL -o "$CACHE/feed/releases.json" "$FEED_URL"
curl -fsSL -o "$CACHE/feed/releases.json.sig" "$FEED_URL.sig"

validator_bin=""
for c in "$(command -v validator || true)" "$CACHE"/validator/validator-*-aarch64-unknown-linux-gnu/validator; do
    [ -n "$c" ] && [ -x "$c" ] && { validator_bin="$c"; break; }
done
if [ -n "$validator_bin" ] && "$validator_bin" update check --feed "$CACHE/feed/releases.json" >/dev/null 2>&1; then
    echo "bump: the feed's signature verified with $validator_bin"
elif [ "$unverified" = "yes" ]; then
    echo "bump: WARNING: the feed's signature was NOT verified (no validator binary here). Trusting TLS to 6529.io only." >&2
else
    echo "bump: no validator binary to verify the feed's signature. Install one, or pass --unverified." >&2
    exit 1
fi

python3 - "$CACHE/feed/releases.json" "$HERE/config.env" "$want" <<'PY'
import json, re, sys
feed = json.load(open(sys.argv[1])); env_path = sys.argv[2]; want = sys.argv[3]
unsafe = {u["version"] for u in feed.get("unsafe_versions", [])}
rels = [r for r in feed["releases"] if r["version"] not in unsafe]
rel = next((r for r in rels if r["version"] == want), None) if want else rels[0]
if rel is None: sys.exit(f"bump: release {want!r} is not in the feed")
deb = next(f for f in rel["files"] if f["name"].endswith("_arm64.deb"))
page = feed.get("download_page", "https://6529.io/validator")
pins = {
  "VALIDATOR_VERSION": rel["version"], "VALIDATOR_CHANNEL": rel.get("channel", ""),
  "VALIDATOR_COMMIT": rel.get("commit", ""), "VALIDATOR_DEB_NAME": deb["name"],
  "VALIDATOR_DEB_URL": f"{page}/download/{rel['version']}/{deb['name']}",
  "VALIDATOR_DEB_SHA256": deb["sha256"], "VALIDATOR_SOFTWARE_ID": rel.get("software_id", ""),
}
text = open(env_path).read()
for k, v in pins.items():
    text, n = re.subn(rf'^{k}=".*"$', f'{k}="{v}"', text, flags=re.M)
    if n != 1: sys.exit(f"bump: {k} not found in config.env")
open(env_path, "w").write(text)
print(f"bump: pinned validator {rel['version']} ({rel.get('channel')}, {rel.get('date')}), {deb['name']} {deb['sha256']}")
print("bump: read the release notes before you build:", rel.get("notes_url", page))
PY
