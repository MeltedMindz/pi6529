# Releasing a pi6529 image

1. **Pin.** If 6529 has a newer validator, `build/bump-validator.sh`, read the
   notes, commit `build/config.env`. If the base OS moved, update the
   `BASE_*` lines by hand from Raspberry Pi Imager's OS list
   (`https://downloads.raspberrypi.com/os_list_imagingutility_v4.json`).
2. **Version.** Bump `VERSION` (semver; the image's own number) and add a
   section to `CHANGELOG.md` naming the validator release inside.
3. **Build and check locally.** `make image && make check`. Flash it to a
   card and boot a real Pi: first login shows the welcome, `pi6529 link`
   prints a link, the page loads, `pi6529 update --check` talks to 6529.
4. **Imager entry.** `make imager-entry` rewrites `imager/os_list.json` with
   the new hashes and sizes. Commit.
5. **Tag and push.** `git tag v<version> && git push --tags`. The workflow
   builds on GitHub's ARM64 runner, creates the Release, attaches the image,
   `.sha256`, `SHA256SUMS` and `.json`, and records build provenance.
6. **Compare.** The hash in the Release must equal the one from your local
   build's `.json` if nothing else changed; if it doesn't, the difference is
   the mirrors' package versions (see BUILDING.md, Reproducibility). Note it
   in the Release.
7. **Mark it pre-release** while the validator is on the `test` channel.

## Deadlines that matter

The validator's release list carries `min_supported` and `deadline`. A
pi6529 image pinned to a release below `min_supported` after the deadline
installs a validator that can't sign until updated. Rebuild before that, and
say so in the Release notes.
