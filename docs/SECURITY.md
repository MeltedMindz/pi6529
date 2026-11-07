# Security notes

## What is and isn't in the image

A pi6529 image is public and the same for everyone. It must therefore hold
nothing that belongs to one Pi. The build checks (`build/check-image.sh`) that:

- the validator's data folder is empty: no `config.toml`, no
  `secrets/password`, no `keys/`, no `signer/`;
- no keystore file exists anywhere on the image;
- `/etc/machine-id` is empty and there are no SSH host keys;
- the validator service is not enabled until the first boot has set it up.

All of these are made on the Pi on its first boot.

## The key

- The validator key is a BLS12-381 key in an encrypted keystore in
  `/var/lib/6529-validator/keys/`, readable only by the `validator6529`
  account. Its password is in `secrets/password` beside it, so the service
  starts by itself. 6529's validator never prints or logs either.
- It signs only validator messages. It cannot move NFTs or funds. The
  authorization your wallet signs says so, word for word.
- **One key, one Pi.** Cloning the SD card, imaging it, or restoring a backup
  of the data folder onto a second machine makes two validators that can sign
  the same day twice. That excludes your account for 30 days or more and the
  keys of that authorization never count again. The folder carries a
  `CACHEDIR.TAG` so borg, restic and `tar --exclude-caches` skip it, but a
  raw disk image ignores that: never make one.
- To move to another Pi: flash a new card, let it make its own key, add that
  key in the page's Keys, and stop the old key there. Then wipe the old card.

## The page

- 6529's validator serves its page on `127.0.0.1` only, on port 7529 in this
  image. Nothing on your network can reach it. You reach it through an SSH
  tunnel, which is encrypted and authenticated by your Pi's user and
  password (or key).
- `pi6529 link` asks the validator for a one-time sign-in link. The link works
  once and for 24 hours. The address without the token opens a page that
  cannot sign.
- Signing on your phone opens `6529.io/validator/authorize#...`: the draft is
  in the URL fragment, which browsers never send to any server. Check that the
  key code the phone shows matches the one on your Pi's page before you sign.

## SSH

- SSH is enabled so a Pi with no screen can be reached. There is no default
  user and no default password: Raspberry Pi Imager creates the user you
  choose. Choose a real password, or better, put your SSH public key in the
  Imager's settings and turn password login off.
- Don't forward port 22 from your router. The validator opens no port and
  needs none.

## Updates

- Debian security updates install themselves at night. The validator is
  blacklisted from that: 6529's rule is that you install each release
  yourself after reading its notes.
- `pi6529 update` verifies the release list with the key built into the
  validator you already run, checks the file's SHA-256 against that list, and
  only then installs. A mismatch installs nothing.
- From 6529's first public release, their `SHA256SUMS` carries a Sigstore
  signature. Verifying it is on the roadmap for both the build and the
  updater.

## Reporting

Something wrong with the image or the helper: open an issue on the repo, or
write to the maintainer privately for anything that could affect other
people's keys. Something wrong with the validator itself: 6529's known-issues
page and the Ministry of Validation wave. `pi6529 tor-report` makes a report
with no addresses in it that is safe to paste.

6529 never starts a DM with you or asks for a seed phrase. Neither does this
project.
