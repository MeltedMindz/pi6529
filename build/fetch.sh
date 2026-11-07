#!/usr/bin/env bash
# Download the build's inputs into $CACHE and check each against the hash
# pinned in build/config.env. Nothing unchecked is ever used by the build.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.env
source "$HERE/config.env"
CACHE="${CACHE:-$HERE/../.cache}"
mkdir -p "$CACHE/base" "$CACHE/validator"

sha256() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
    else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

fetch() { # fetch URL DEST SHA256 WHAT
    local url="$1" dest="$2" want="$3" what="$4"
    if [ -f "$dest" ] && [ "$(sha256 "$dest")" = "$want" ]; then
        echo "fetch: $what: already in the cache and its hash matches."
        return 0
    fi
    echo "fetch: $what"
    echo "       $url"
    local code
    code=$(curl -fL --retry 3 --progress-bar -o "$dest.part" -w '%{http_code}' "$url" || true)
    if [ ! -s "$dest.part" ] || [ "$code" != "200" ]; then
        rm -f "$dest.part"
        echo "fetch: $what: download failed (HTTP $code)." >&2
        if [ "$what" = "validator .deb" ]; then
            echo "       6529 serves only the newest release. If a newer one is out," >&2
            echo "       run build/bump-validator.sh to move the pin, then build again." >&2
        fi
        exit 1
    fi
    local got
    got=$(sha256 "$dest.part")
    if [ "$got" != "$want" ]; then
        rm -f "$dest.part"
        echo "fetch: $what: SHA-256 MISMATCH. Refusing to use it." >&2
        echo "       wanted $want" >&2
        echo "       got    $got" >&2
        exit 1
    fi
    mv "$dest.part" "$dest"
    echo "fetch: $what: OK ($want)"
}

fetch "$BASE_URL" "$CACHE/base/$BASE_NAME.img.xz" "$BASE_XZ_SHA256" "base image (Raspberry Pi OS Lite 64-bit)"
fetch "$VALIDATOR_DEB_URL" "$CACHE/validator/$VALIDATOR_DEB_NAME" "$VALIDATOR_DEB_SHA256" "validator .deb"
echo "fetch: done. Inputs are in $CACHE"
