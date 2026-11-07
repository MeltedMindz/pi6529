# Building the image yourself

You don't have to: every release on GitHub carries the image, its SHA-256 and
the build's provenance. But the whole point of a pinned build is that anyone
can make the same file. Here is how.

## What you need

- Docker. On a Mac: Docker Desktop, [Colima](https://github.com/abiosoft/colima)
  or OrbStack. On Linux: Docker Engine or Podman with the `docker` alias.
- About 8 GB of free disk and a few minutes. The build runs a privileged
  `linux/arm64` container (loop devices and `chroot` need root in it).
  - Apple silicon Mac, or an ARM64 Linux host: runs natively.
  - x86-64 Linux: install `qemu-user-static` and `binfmt-support` so the
    container's ARM64 programs run; the build is then slower.
- `git`, `make`, `curl`, `python3` on the host.

## Build

```bash
git clone https://github.com/MeltedMindz/pi6529
cd pi6529
make image
```

It downloads the base Raspberry Pi OS image and 6529's `.deb` into `.cache/`,
checks each against the hash in `build/config.env`, and writes:

```
dist/pi6529-<version>.img.xz          the image
dist/pi6529-<version>.img.xz.sha256   its SHA-256
dist/SHA256SUMS                       the same, for sha256sum --check
dist/pi6529-<version>.img.xz.json     sizes and hashes (for the Imager entry)
```

`make check` re-runs the 26 assertions in `build/check-image.sh` against the
image in `dist/`. `make lint` syntax-checks every script.

## The pins

`build/config.env` holds every input's URL and SHA-256. The build refuses an
input whose hash differs. To move to a newer validator release:

```bash
build/bump-validator.sh      # rewrites the VALIDATOR_* pins from 6529's signed feed
git diff build/config.env    # read what changed, and the release notes it points to
make image
```

`bump-validator.sh` verifies the feed's signature with a validator binary when
it finds one (the installed `validator`, or the terminal archive unpacked in
`.cache/validator/`). Without one it stops; `--unverified` overrides that and
trusts TLS to 6529.io alone.

6529 serves only the newest release for download. If the pinned one is no
longer the newest, `fetch.sh` gets a 404 and says to bump.

## What the build does, step by step

`build/inside/customize.sh`, in the container:

1. Decompress the base image, verify the decompressed hash, grow it by
   `IMAGE_GROW_MB` (parted + resize2fs), loop-mount both partitions.
2. In a chroot (with `policy-rc.d` so no service starts): `apt-get install`
   `jq`, `unattended-upgrades` and the validator `.deb`. The `.deb`'s postinst
   creates the `validator6529` account and runs `validator init` (we wipe
   that result afterwards; see 4).
3. Copy the overlay `image/rootfs/` over the root, `image/boot/pi6529.txt` to
   the boot partition, touch `boot/ssh`, set the hostname, enable
   `pi6529-firstboot.service`, make sure `6529-validator.service` is
   disabled, write `/etc/pi6529/release`.
4. Wipe anything device-specific: the validator's data folder, machine-id,
   SSH host keys, shell history, logs, apt lists.
5. Run `build/check-image.sh`.
6. Unmount, `e2fsck`, zero the free space, `xz -6`, write the checksums and
   the `.json`.

## Reproducibility

The inputs are pinned, the steps are deterministic, but the output is not yet
byte-for-byte reproducible: `apt-get install` in step 2 fetches the current
`jq` and `unattended-upgrades` from the Raspberry Pi mirrors, and timestamps
land in a few files. Pinning those two packages and normalising mtimes is a
roadmap item. What *is* reproducible today: the validator binary (6529's
builds are reproducible; `release.json` records the toolchain) and the
checks that prove nothing device-specific shipped.

## Releasing

See [RELEASING.md](RELEASING.md).
