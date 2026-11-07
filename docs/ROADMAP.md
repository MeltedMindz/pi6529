# Roadmap

Where pi6529 goes after 0.1.0, in the order that seems right today. Each
item is small enough to be one pull request. Nothing here is promised.

## 0.1.x: while the validator is a test release

- **Track 6529's releases.** Bump the pin (`build/bump-validator.sh`), rebuild,
  tag. 0.1.0 stops signing on 1 December 2026, so a rebuild on the first
  0.1.x release is required, not optional.
- **Boot test on real hardware** (Pi 4 4 GB, Pi 5 8 GB, SD and USB SSD) and
  write down the timings in the README.
- **`pi6529 doctor`**: one command that checks the clock, the network, Tor,
  peers, disk, and the validator's alerts, and prints what to do.
- **A `pi6529 setup` interactive step** for people who skipped the Imager
  settings: set a user, Wi-Fi and the hostname from the console.
- **Sigstore verification** of `SHA256SUMS` in `fetch.sh` and `pi6529 update`,
  the day 6529 publishes `SHA256SUMS.sigstore.json` (first public release).

## 0.2: the public release of the validator

- **Re-base on the validator's first stable release.** Switch the pin to the
  `stable` channel and stop offering `test` builds by default.
- **Imager entry in a public list.** Ask Raspberry Pi to list pi6529 under
  "Other specific-purpose OS", as other projects are, once 6529 has seen it.
- **Opt-in LAN page** (`[ui] lan = true`, which the validator already has as a
  setting) for people who can't do SSH tunnels, behind a clear warning and
  only if 6529 is comfortable with it. Until then, the tunnel.
- **mDNS name on the page.** `http://pi6529.local:7529` would need the LAN
  option above.
- **Hardware watchdog** (`RuntimeWatchdogSec` on the Pi's BCM watchdog) so a
  hung Pi reboots itself before 00:15 UTC.
- **Use your own Ethereum node from the Pi.** `validator init` takes
  `--own-execution` and `--own-beacon` (for example a Geth + Lighthouse pair
  on another machine on the LAN); a `pi6529.txt` key pair for them, so a Pi
  can report `OWN_NODE` without touching `config.toml` by hand.
- **Read-only root / overlayfs option** for SD-card longevity, with the
  validator's data folder on a writable partition.

## Hardware

- **Pre-flashed cards and SSDs.** The same image; a label with the version
  and the validator release; a one-page printed guide that is the README's
  first screen.
- **A kit**: Pi 5 8 GB, official power supply, case with a fan, NVMe HAT and
  256 GB SSD (6529's "Acceptable" tier, about $300 at October 2026 prices).
  Only after the first public release and only with 6529's blessing.
- **A tiny status display** (e-ink or OLED HAT): green "signed", grey
  "waiting", rose "needs you", like the Mac app's menu-bar logo.

## Not planned

- Running an Ethereum node on the Pi.
- Any form of key backup, export or transfer. 6529's rule is one key, one
  machine, and a lost machine is replaced by a new key.
- Automatic validator updates.
