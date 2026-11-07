#!/usr/bin/env bash
# Print a Raspberry Pi Imager OS-list (os_list.json) entry for the image in
# $DIST, pointing at the GitHub release of this version. Run after a build;
# the Makefile's `imager-entry` target writes it to imager/os_list.json.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# shellcheck source=config.env
source "$HERE/config.env"
VERSION="$(cat "$ROOT/VERSION")"
DIST="${DIST:-$ROOT/dist}"
REPO="${REPO:-MeltedMindz/pi6529}"
META="$DIST/pi6529-$VERSION.img.xz.json"
[ -f "$META" ] || { echo "imager-entry: $META not found; build first." >&2; exit 1; }
python3 - "$META" "$VERSION" "$REPO" "$VALIDATOR_VERSION" <<'PY'
import json, sys, datetime
meta = json.load(open(sys.argv[1]))
version, repo, validator = sys.argv[2], sys.argv[3], sys.argv[4]
entry = {
  "name": f"pi6529 {version} (6529 Validator {validator})",
  "description": "Raspberry Pi OS Lite (64-bit) with the 6529 validator installed and set to start on first boot. Makes its key on your Pi; you authorize it with your wallet.",
  "icon": f"https://raw.githubusercontent.com/{repo}/main/imager/icon.png",
  "url": f"https://github.com/{repo}/releases/download/v{version}/pi6529-{version}.img.xz",
  "release_date": meta["built"][:10],
  "extract_size": meta["img_size"],
  "extract_sha256": meta["img_sha256"],
  "image_download_size": meta["xz_size"],
  "image_download_sha256": meta["xz_sha256"],
  "devices": ["pi5-64bit", "pi4-64bit"],
  "init_format": "cloudinit-rpi",
  "website": f"https://github.com/{repo}"
}
print(json.dumps({"os_list": [entry]}, indent=2))
PY
