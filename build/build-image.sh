#!/usr/bin/env bash
# Build the pi6529 image. This runs on the host: it fetches the inputs, then
# runs build/inside/customize.sh in a privileged Docker container (loop
# devices and chroot need root), and leaves the result in $DIST.
#
#   build/build-image.sh               build
#   build/build-image.sh --check-only  only run build/check-image.sh on dist/
#
# The container is linux/arm64: native on Apple silicon and ARM64 Linux, and
# through qemu-user-static on x86-64 Linux.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# shellcheck source=config.env
source "$HERE/config.env"
VERSION="$(cat "$ROOT/VERSION")"
CACHE="${CACHE:-$ROOT/.cache}"
DIST="${DIST:-$ROOT/dist}"
IMAGE_NAME="pi6529-$VERSION"
CONTAINER_IMAGE="${CONTAINER_IMAGE:-debian:trixie-slim}"

mode="build"
[ "${1:-}" = "--check-only" ] && mode="check"

command -v docker >/dev/null 2>&1 || { echo "build: docker is needed (Docker Desktop, Colima, or a Linux host)." >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "build: the docker daemon is not running." >&2; exit 1; }

if [ "$mode" = "build" ]; then
    CACHE="$CACHE" "$HERE/fetch.sh"
fi
mkdir -p "$DIST"

# A git description for the record written to /etc/pi6529/release.
GIT_DESC="$(git -C "$ROOT" describe --tags --always --dirty 2>/dev/null || echo "untracked")"

echo "build: running the $mode step in a $CONTAINER_IMAGE container (linux/arm64)"
docker run --rm --privileged --platform linux/arm64 \
    -v /dev:/dev \
    -v "$ROOT:/src:ro" \
    -v "$CACHE:/cache:ro" \
    -v "$DIST:/dist" \
    -e DEBIAN_FRONTEND=noninteractive \
    -e PI6529_VERSION="$VERSION" \
    -e PI6529_GIT="$GIT_DESC" \
    -e IMAGE_NAME="$IMAGE_NAME" \
    -e BUILD_MODE="$mode" \
    -e SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-$(git -C "$ROOT" log -1 --format=%ct 2>/dev/null || date +%s)}" \
    "$CONTAINER_IMAGE" bash /src/build/inside/customize.sh

if [ "$mode" = "build" ]; then
    echo
    echo "build: done."
    ls -la "$DIST"
    echo
    echo "Flash $DIST/$IMAGE_NAME.img.xz with Raspberry Pi Imager (Use custom)."
fi
