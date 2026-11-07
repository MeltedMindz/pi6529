#!/usr/bin/env bash
# Assertions on the built image's root and boot file systems. Runs inside the
# build container after customization (and with `make check`). Every line is a
# promise the README makes.
set -euo pipefail
ROOTFS="${1:?rootfs mount}"; BOOT="${2:?boot mount}"
# shellcheck source=config.env
source /src/build/config.env
fail=0
ok()   { echo "  ok   $*"; }
bad()  { echo "  FAIL $*"; fail=1; }
check(){ if eval "$1"; then ok "$2"; else bad "$2"; fi; }

echo "check-image:"
check '[ -x "$ROOTFS/usr/bin/validator" ]' "validator program installed"
v="$(chroot "$ROOTFS" /usr/bin/validator --version 2>/dev/null || true)"
check '[[ "$v" == *"$VALIDATOR_VERSION"* ]]' "validator reports $VALIDATOR_VERSION (got: $v)"
check '[[ "$v" == *"${VALIDATOR_COMMIT:0:7}"* ]]' "validator built from commit ${VALIDATOR_COMMIT:0:7}"
check 'chroot "$ROOTFS" /usr/bin/validator version --json | grep -q "\"build\": \"release\""' "validator is a release build (release.json present)"
check 'chroot "$ROOTFS" /usr/bin/validator version --json | grep -q "$VALIDATOR_SOFTWARE_ID"' "software_id matches the pin"
check '[ -f "$ROOTFS/lib/systemd/system/6529-validator.service" ]' "6529's systemd unit present"
check '[ -f "$ROOTFS/etc/systemd/system/6529-validator.service.d/pi6529.conf" ]' "pi6529 drop-in present"
check '[ -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/pi6529-firstboot.service" ]' "first-boot service enabled"
check '[ ! -L "$ROOTFS/etc/systemd/system/multi-user.target.wants/6529-validator.service" ]' "validator service NOT enabled before the first boot"
check 'getent passwd validator6529 >/dev/null || grep -q "^validator6529:" "$ROOTFS/etc/passwd"' "service account validator6529 exists"
check '[ -d "$ROOTFS/var/lib/6529-validator" ] && [ -z "$(ls -A "$ROOTFS/var/lib/6529-validator")" ]' "validator data folder is EMPTY (no password, no key, no config)"
check '! find "$ROOTFS" -path "$ROOTFS/proc" -prune -o -name "*.keystore.json" -print | grep -q .' "no keystore anywhere on the image"
check '[ ! -s "$ROOTFS/etc/machine-id" ]' "machine-id is empty (made at first boot)"
check '! ls "$ROOTFS/etc/ssh/ssh_host_"* >/dev/null 2>&1' "no SSH host keys (made at first boot)"
check '[ "$(cat "$ROOTFS/etc/hostname")" = "pi6529" ]' "hostname is pi6529"
check '[ -f "$BOOT/pi6529.txt" ]' "pi6529.txt on the boot partition"
check '[ -f "$BOOT/ssh" ]' "ssh enabled on first boot"
check '[ -x "$ROOTFS/usr/local/sbin/pi6529" ]' "pi6529 helper installed"
check 'bash -n "$ROOTFS/usr/local/sbin/pi6529" && bash -n "$ROOTFS/usr/local/lib/pi6529/firstboot.sh"' "helper scripts parse"
check '[ -x "$ROOTFS/usr/local/lib/pi6529/wait-for-time" ]' "wait-for-time present"
check '[ -f "$ROOTFS/etc/pi6529/release" ] && grep -q "PI6529_VERSION=" "$ROOTFS/etc/pi6529/release"' "release record written"
check 'chroot "$ROOTFS" dpkg -s jq >/dev/null 2>&1' "jq installed (pi6529 update needs it)"
check 'chroot "$ROOTFS" dpkg -s unattended-upgrades >/dev/null 2>&1' "unattended-upgrades installed"
check 'grep -q 6529-validator "$ROOTFS/etc/apt/apt.conf.d/52pi6529-unattended"' "validator blacklisted from automatic upgrades"
check '[ -f "$ROOTFS/etc/NetworkManager/conf.d/pi6529-wifi-powersave.conf" ]' "Wi-Fi power saving off"
check '[ -f "$ROOTFS/usr/share/doc/6529-validator/NOTICE" ]' "6529's NOTICE kept"
check '[ ! -f "$ROOTFS/usr/sbin/policy-rc.d" ]' "policy-rc.d removed"
check '[ ! -f "$ROOTFS/root/.bash_history" ]' "no root shell history"
check 'grep -q "glibc 2.41\|2\.41" <(chroot "$ROOTFS" ldd --version | head -1)' "glibc 2.41 (validator needs 2.35+)"
if [ "$fail" != 0 ]; then echo "check-image: FAILED"; exit 1; fi
echo "check-image: all checks passed"
