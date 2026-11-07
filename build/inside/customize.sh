#!/usr/bin/env bash
# Runs inside the build container (root, privileged, linux/arm64).
# Turns the stock Raspberry Pi OS Lite image into the pi6529 image:
#   1. copy and grow the base image, mount its two partitions;
#   2. in a chroot: install 6529's .deb and a few packages, apply the overlay;
#   3. make sure nothing device-specific is left in it (no keys, no machine id,
#      no SSH host keys, no validator data);
#   4. check it (build/check-image.sh), compress it, write the checksums.
set -euo pipefail

# shellcheck source=../config.env
source /src/build/config.env
VERSION="${PI6529_VERSION:?}"
IMAGE_NAME="${IMAGE_NAME:?}"
MODE="${BUILD_MODE:-build}"
WORK=/work
IMG="$WORK/$IMAGE_NAME.img"
OUT=/dist
BOOT="$WORK/boot"; ROOTFS="$WORK/root"
LOOP=""

log() { echo; echo "==> $*"; }
cleanup() {
    set +e
    for m in "$ROOTFS/boot/firmware" "$ROOTFS/dev/pts" "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/run" "$BOOT" "$ROOTFS"; do
        mountpoint -q "$m" 2>/dev/null && umount -l "$m"
    done
    [ -n "$LOOP" ] && losetup -d "$LOOP" 2>/dev/null
}
trap cleanup EXIT

log "tools"
apt-get -qq update >/dev/null
apt-get -qq install -y --no-install-recommends xz-utils util-linux mount fdisk parted e2fsprogs dosfstools ca-certificates curl rsync jq >/dev/null
mkdir -p "$WORK" "$BOOT" "$ROOTFS" "$OUT"

attach() {
    LOOP="$(losetup -fP --show "$IMG")"
    # Partition nodes can lag behind in a container; wait for them.
    for _ in $(seq 1 20); do [ -b "${LOOP}p2" ] && break; sleep 0.5; done
    [ -b "${LOOP}p2" ] || { partprobe "$LOOP" || true; sleep 1; }
    [ -b "${LOOP}p2" ] || { echo "no partition nodes for $LOOP" >&2; exit 1; }
}
mount_all() {
    mount "${LOOP}p2" "$ROOTFS"
    mount "${LOOP}p1" "$BOOT"
    mkdir -p "$ROOTFS/boot/firmware"
    mount --bind "$BOOT" "$ROOTFS/boot/firmware"
}

if [ "$MODE" = "check" ]; then
    log "check only"
    xz -dkc "$OUT/$IMAGE_NAME.img.xz" > "$IMG"
    attach; mount_all
    bash /src/build/check-image.sh "$ROOTFS" "$BOOT"
    exit 0
fi

log "1. the base image: decompress, check, grow by ${IMAGE_GROW_MB} MB"
xz -dkc "/cache/base/$BASE_NAME.img.xz" > "$IMG"
got="$(sha256sum "$IMG" | cut -d' ' -f1)"
[ "$got" = "$BASE_IMG_SHA256" ] || { echo "base image (decompressed) hash mismatch: $got" >&2; exit 1; }
truncate -s "+${IMAGE_GROW_MB}M" "$IMG"
parted -s "$IMG" resizepart 2 100%
attach
e2fsck -fy "${LOOP}p2" >/dev/null || true
resize2fs "${LOOP}p2" >/dev/null
mount_all
echo "root partition: $(df -h "$ROOTFS" | awk 'NR==2{print $2" total, "$4" free"}')"

log "2. chroot: install the validator and the image's packages"
cp /etc/resolv.conf "$ROOTFS/etc/resolv.conf.pi6529-build" && mv -f "$ROOTFS/etc/resolv.conf" "$ROOTFS/etc/resolv.conf.orig" 2>/dev/null || true
cp /etc/resolv.conf "$ROOTFS/etc/resolv.conf"
mount -t proc proc "$ROOTFS/proc"
mount -t sysfs sys "$ROOTFS/sys"
mount --bind /dev "$ROOTFS/dev"
mount --bind /dev/pts "$ROOTFS/dev/pts"
mount -t tmpfs tmpfs "$ROOTFS/run"
# No service may start inside the chroot.
printf '#!/bin/sh\nexit 101\n' > "$ROOTFS/usr/sbin/policy-rc.d"; chmod +x "$ROOTFS/usr/sbin/policy-rc.d"
cp "/cache/validator/$VALIDATOR_DEB_NAME" "$ROOTFS/tmp/validator.deb"
got="$(sha256sum "$ROOTFS/tmp/validator.deb" | cut -d' ' -f1)"
[ "$got" = "$VALIDATOR_DEB_SHA256" ] || { echo "validator .deb hash mismatch in the chroot copy" >&2; exit 1; }

chroot "$ROOTFS" /usr/bin/env -i PATH=/usr/sbin:/usr/bin:/sbin:/bin HOME=/root LANG=C.UTF-8 DEBIAN_FRONTEND=noninteractive bash -eu <<'CHROOT'
apt-get -qq update
# jq: pi6529 update reads the release list. unattended-upgrades: security
# updates for Debian only (the validator is blacklisted; see /etc/apt/apt.conf.d).
apt-get -qq install -y --no-install-recommends jq unattended-upgrades
apt-get -qq install -y /tmp/validator.deb
rm -f /tmp/validator.deb
apt-get -qq clean
rm -rf /var/lib/apt/lists/*
/usr/bin/validator --version
CHROOT

log "3. the overlay, hostname, services, and a clean slate"
rsync -a --chown=root:root /src/image/rootfs/ "$ROOTFS/"
install -m 0644 /src/image/boot/pi6529.txt "$BOOT/pi6529.txt"
# SSH on: a Pi with no screen has no other door. The user and password come
# from Raspberry Pi Imager's settings (no default password exists).
touch "$BOOT/ssh"
echo "pi6529" > "$ROOTFS/etc/hostname"
sed -i 's/127\.0\.1\.1.*/127.0.1.1\tpi6529/' "$ROOTFS/etc/hosts"
grep -q '127.0.1.1' "$ROOTFS/etc/hosts" || echo -e "127.0.1.1\tpi6529" >> "$ROOTFS/etc/hosts"
# Enable units offline (symlinks only; nothing runs here).
chroot "$ROOTFS" systemctl enable pi6529-firstboot.service >/dev/null 2>&1
# The validator unit is enabled on the first boot, after init; not before.
chroot "$ROOTFS" systemctl disable 6529-validator.service >/dev/null 2>&1 || true
chroot "$ROOTFS" systemctl enable unattended-upgrades.service >/dev/null 2>&1 || true
mkdir -p "$ROOTFS/var/log/journal"   # persistent journal (see journald.conf.d)
# The release record the helper shows.
cat > "$ROOTFS/etc/pi6529/release" <<REL
PI6529_VERSION=$VERSION
PI6529_GIT=${PI6529_GIT:-}
PI6529_BUILT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
BASE_IMAGE=$BASE_NAME
VALIDATOR_VERSION=$VALIDATOR_VERSION
VALIDATOR_CHANNEL=$VALIDATOR_CHANNEL
VALIDATOR_COMMIT=$VALIDATOR_COMMIT
VALIDATOR_DEB_SHA256=$VALIDATOR_DEB_SHA256
UI_PORT=$UI_PORT
REL
chmod 0644 "$ROOTFS/etc/pi6529/release"
# Nothing device-specific may ship in a public image:
#  - the validator's data folder (the .deb's postinst ran `validator init` in
#    the chroot and wrote a password; the first boot makes this Pi's own);
#  - the machine id, SSH host keys (the stock image regenerates both at boot).
rm -rf "$ROOTFS/var/lib/6529-validator"/* "$ROOTFS/var/lib/6529-validator"/.[!.]* 2>/dev/null || true
rm -f "$ROOTFS/etc/ssh/ssh_host_"*
: > "$ROOTFS/etc/machine-id"
rm -f "$ROOTFS/var/lib/dbus/machine-id"
rm -f "$ROOTFS/usr/sbin/policy-rc.d"
rm -f "$ROOTFS/etc/resolv.conf"; mv -f "$ROOTFS/etc/resolv.conf.orig" "$ROOTFS/etc/resolv.conf" 2>/dev/null || true
rm -f "$ROOTFS/etc/resolv.conf.pi6529-build"
rm -rf "$ROOTFS/root/.bash_history" "$ROOTFS/tmp"/* "$ROOTFS/var/tmp"/*
rm -rf "$ROOTFS/var/log/journal"/* "$ROOTFS/var/log"/*.log "$ROOTFS/var/log/apt"/* 2>/dev/null || true

log "4. checks"
bash /src/build/check-image.sh "$ROOTFS" "$BOOT"

log "5. unmount, trim and compress"
umount "$ROOTFS/boot/firmware" "$ROOTFS/dev/pts" "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/run"
umount "$BOOT" "$ROOTFS"
fstrim -v "$ROOTFS" 2>/dev/null || true
e2fsck -fy "${LOOP}p2" >/dev/null || true
# Zero the free space so xz packs it to nothing.
mount "${LOOP}p2" "$ROOTFS"; (dd if=/dev/zero of="$ROOTFS/zero.fill" bs=1M status=none 2>/dev/null || true); rm -f "$ROOTFS/zero.fill"; sync; umount "$ROOTFS"
losetup -d "$LOOP"; LOOP=""
img_sha="$(sha256sum "$IMG" | cut -d' ' -f1)"; img_size="$(stat -c %s "$IMG")"
xz -T0 -6 -f "$IMG"
mv -f "$IMG.xz" "$OUT/$IMAGE_NAME.img.xz"
xz_sha="$(sha256sum "$OUT/$IMAGE_NAME.img.xz" | cut -d' ' -f1)"; xz_size="$(stat -c %s "$OUT/$IMAGE_NAME.img.xz")"
( cd "$OUT" && sha256sum "$IMAGE_NAME.img.xz" > "$IMAGE_NAME.img.xz.sha256" && cp "$IMAGE_NAME.img.xz.sha256" SHA256SUMS )
jq -n --arg v "$VERSION" --arg img_sha "$img_sha" --argjson img_size "$img_size" --arg xz_sha "$xz_sha" --argjson xz_size "$xz_size" \
      --arg built "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg validator "$VALIDATOR_VERSION" --arg base "$BASE_NAME" --arg git "${PI6529_GIT:-}" \
      '{version:$v, built:$built, validator:$validator, base_image:$base, git:$git, img_sha256:$img_sha, img_size:$img_size, xz_sha256:$xz_sha, xz_size:$xz_size}' \
      > "$OUT/$IMAGE_NAME.img.xz.json"
chown -R --reference=/dist "$OUT"/. 2>/dev/null || true
echo
echo "image:      $OUT/$IMAGE_NAME.img.xz ($xz_size bytes, sha256 $xz_sha)"
echo "uncompressed: $img_size bytes, sha256 $img_sha"
