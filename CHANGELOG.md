# Changelog

All notable changes to the pi6529 image. The image has its own version; each
entry names the 6529 validator release inside it.

## 0.1.0 — 2026-11-07

First image.

- Base: Raspberry Pi OS Lite (64-bit) Trixie, 2026-10-06.
- Validator: 6529 validator 0.1.0-rc.10 (commit f0a3440, TDH v1.4), test
  channel, from 6529's ARM64 `.deb`. Stops signing on 2026-12-01; new
  installs must start before about 2026-11-23 03:30 UTC.
- First-boot setup makes the validator's config and keystore password on the
  Pi (`pi6529-firstboot.service`), reading `pi6529.txt` from the boot
  partition; the page is fixed at 127.0.0.1:7529.
- `pi6529` helper: welcome, link, status, logs, update (verified through the
  validator's own key), pause/resume, restart, tor-report, version, settings,
  repair.
- Clock wait before the validator starts; Wi-Fi power saving off; persistent
  capped journal; unattended Debian security updates with the validator
  blacklisted; SSH on, no default user.
- Build: pinned inputs, 29 image checks, Raspberry Pi Imager entry generator,
  pin-bump script, GitHub Actions workflow.
- Known limits: not yet booted on real hardware by the author; image not
  byte-for-byte reproducible (apt packages from mirrors).
