# pi6529: a Raspberry Pi that runs the 6529 validator

**Flash a card. Plug the Pi in. Sign once with your wallet. It signs every day for you.**

pi6529 is a ready-made SD-card image for a Raspberry Pi 4 or 5. It is Raspberry Pi OS with the official [6529 validator](https://6529.io/validator) already installed and set to start by itself. The validator reads Ethereum once a day, works out everyone's TDH, and signs the result with a key that lives only on your Pi. Your wallet signs one message, once, to say that key speaks for your account. That's the whole job.

> **Status: early test build.** 6529's validator is itself a test release (0.1.0-rc.10). This image has been built and checked by machine (29 checks), and its file system has been booted under systemd on an ARM64 host, where the validator connected to Tor and to other validators and its page came up. It has **not yet been booted on a real Pi by the author**, so the kernel, Wi-Fi and Imager steps are untested. The validator in it stops signing on 1 December 2026, and 6529 asks that new installs start before about 23 November 2026; a newer image will follow 6529's next release. Try it, tell us what happened, don't bet the farm on it yet.
>
> pi6529 is an independent community project. It is **not made by, affiliated with or endorsed by 6529**. 6529 never starts a DM with you or asks for a seed phrase. Neither do we.

---

## The whole thing in four steps

| | Step | How long |
|---|---|---|
| 1 | Flash the image to a card with Raspberry Pi Imager and type in your Wi-Fi and a password. | 5 minutes |
| 2 | Put the card in the Pi and plug it in. It sets itself up and downloads the network's history. | 20 to 30 minutes, hands off |
| 3 | From your computer, open the Pi's page with one command, make the key, and sign on your phone. | 5 minutes |
| 4 | Leave it on. | forever |

Nothing in these steps needs a screen or keyboard on the Pi.

---

## What you need

- **A Raspberry Pi 5 or Raspberry Pi 4.** 8 GB of memory is best; 4 GB works. (A Pi 3 or a 2 GB Pi won't do.) The official power supply for it.
- **A microSD card, 16 GB or bigger.** Or a USB or NVMe SSD, which lasts longer. [More on hardware.](docs/HARDWARE.md)
- **Home internet**, by Ethernet cable or Wi-Fi. About 50 GB a month. You open nothing on your router.
- **A computer** (Mac, Windows or Linux) with [Raspberry Pi Imager](https://www.raspberrypi.com/software/) to write the card, and a browser.
- **Your wallet**, the one that holds your TDH: on your phone (easiest), or in your computer's browser (MetaMask, Rabby, a Ledger through them, and the like).

---

## Step 1: Flash the card

1. Download the image from the [latest release](https://github.com/MeltedMindz/pi6529/releases/latest): the file called `pi6529-<version>.img.xz`. (Optional but good: check its SHA-256 against the `.sha256` file next to it.)
2. Open **Raspberry Pi Imager**.
   - **Device:** your Pi model.
   - **Operating System:** scroll to the bottom, **Use custom**, pick the file you downloaded.
   - **Storage:** your card.
3. Press **Next**. Imager asks **"Would you like to apply OS customisation settings?"** Press **Edit settings**. This is the important bit:
   - **Set hostname:** `pi6529` (leave it so; the commands below use this name).
   - **Set username and password:** pick a username (for example `pi`) and a password you'll remember. **Write them down.** This is how you'll log in.
   - **Configure wireless LAN:** your Wi-Fi name and password, and your country. Skip this if you'll use an Ethernet cable.
   - **Set locale settings:** your time zone (the validator works in UTC whatever you choose; this is just for you).
   - **Services tab: Enable SSH** with **Use password authentication**. (If you know what SSH keys are, paste your public key instead.)
   - **Save**, then **Yes** to apply, then **Yes** to write.
4. Wait for "Write successful", then take the card out.

> If you'd rather not download by hand, Imager can list pi6529 directly: see [Raspberry Pi Imager entry](#raspberry-pi-imager-entry) below.

## Step 2: Plug it in and wait

Put the card in the Pi, connect the Ethernet cable if you're using one, and plug in the power. Then leave it alone.

What happens by itself, in order:

1. The Pi grows its file system, makes its own identity, and joins your network (about 1 minute).
2. The validator is set up with a password and settings that exist only on this Pi, and started (a few seconds).
3. The validator waits for the clock to set itself from the internet (up to 90 seconds), connects to Tor (1 to 2 minutes), finds other validators, and downloads and checks the network's history (**about 20 minutes** on 6529's measurements; a little longer each day the release ages).

You can do step 3 while it's still downloading; the page will show its progress.

## Step 3: Open the page, make the key, sign

The validator's page runs on the Pi and is reachable only from the Pi itself. You open a short tunnel to it from your computer. Two commands, both copy-paste.

**On your computer**, open a terminal:
- Mac: **Terminal** (in Applications › Utilities).
- Windows 10 or 11: **PowerShell** (search for it in the Start menu).
- Linux: any terminal.

Type this, replacing `pi` with the username you chose in Imager:

```
ssh -L 7529:127.0.0.1:7529 pi@pi6529.local
```

The first time it asks "Are you sure you want to continue connecting?": type `yes`. Then it asks for the password you chose. (It shows nothing while you type; that's normal.)

You are now logged in to the Pi, and it greets you with the validator's status and **a link that starts with `http://127.0.0.1:7529/login?token=`**. Copy that whole link and open it in the browser on your computer. (If the link isn't there yet, the validator is still starting: wait a minute and type `pi6529 link`.)

The page walks you through the rest:

1. **Make this Pi's key.** One click. The page shows the key's short code, eight characters like `9f3a2c71`. The key is made on the Pi and never leaves it.
2. **Authorize it with your wallet.** Choose **Your phone**, paste your wallet's address, and scan the QR code with your phone. Your phone opens a page on 6529.io that shows *exactly* what you're signing: the name "6529 Validator", the sentence "These keys may sign daily TDH roots for this account and nothing else. They cannot move NFTs or funds.", your account, and the key's code. **Check the code matches the one on the Pi's page.** Sign. It is a message, not a transaction: it costs nothing and moves nothing. Copy the signature your phone shows and paste it into the box on the Pi's page.
   - Wallet in your computer's browser instead? Choose that option and the page talks to it directly.
3. The page tells you from which day the key counts (usually tomorrow).

Keep the terminal window open while you use the page; closing it closes the tunnel. You can close it afterwards.

## Step 4: Leave it on

Every day at about 00:15 UTC the validator computes the day's TDH, signs it, and sends its vote. The Pi needs to be on and online then (signing stays open until 19:00 UTC, so an outage of a few hours is fine; a missed day costs only that day). Your account keeps counting as long as the Pi signs at least once every seven days.

To look in on it, log in the same way (the same `ssh` command) and read the greeting, or type `pi6529`.

---

## Everyday commands

Log in with the `ssh` command from step 3, then:

| Type | To |
|---|---|
| `pi6529` | see what the validator is doing today and what, if anything, needs you |
| `pi6529 link` | get a fresh link to the page (and the tunnel command, in case you forgot it) |
| `pi6529 status -v` | everything the validator knows, in plain words |
| `pi6529 update` | check 6529's signed list of releases and, if there's a newer one, read its notes and install it |
| `pi6529 logs` | the validator's log (`pi6529 logs -f` follows it live; Ctrl-C stops) |
| `pi6529 pause` / `pi6529 resume` | stop signing for a while without stopping the validator |
| `pi6529 restart` | restart the validator service |
| `pi6529 tor-report` | a report on Tor, with no addresses in it, to paste when you ask for help |
| `pi6529 version` | which image, validator and system this is |
| `pi6529 help` | this list |

## Updating

6529 publishes new validator releases often during the test phase, and they tell you a deadline when one matters. Nothing updates by itself: 6529's rule is that you read the notes and decide. The validator checks 6529's signed list once an hour and says so on its page and in `pi6529`. Then:

```
pi6529 update
```

It shows the notes, asks, downloads the Raspberry Pi package, checks its SHA-256 against the list 6529 signed, and installs it. Your key, your authorization and your records stay. `pi6529 update --check` only looks.

The Pi's operating system installs Debian security updates by itself at night. The validator is excluded from that.

---

## Things that matter

**One key, one Pi. Never clone this card.** The validator's key lives in `/var/lib/6529-validator` on the Pi. If two machines ever sign with the same key, that's a double vote: your account stops counting for 30 days or more, and that authorization's keys never count again. So:

- Don't copy the SD card, image it, or restore it onto another Pi.
- Don't back up that folder, and never put an old copy back.
- To move to a new Pi: flash a fresh card, let the new Pi make its *own* key, add that key on the page under **Keys** (its code is shown on the new Pi's page), stop the old key there, and then wipe the old card.

**Stop for good.** Before you throw the Pi in a drawer, open the page, **Keys**, **Stop**, and sign. Otherwise the network keeps expecting that key.

**It opens no ports.** At home the validator connects out only, through Tor, and your address stays yours. You don't need to touch your router. Don't forward port 22 to the Pi either.

**Several Pis, one account.** An account can authorize up to 16 keys, each with a share. Fine for later; one Pi is plenty to start.

More in [docs/SECURITY.md](docs/SECURITY.md).

---

## If something's wrong

**`ssh: Could not resolve hostname pi6529.local`.** The Pi hasn't joined your network yet (wait two minutes), the Wi-Fi details were wrong (re-flash), or your network blocks `.local` names. Find the Pi's IP address in your router's device list and use it instead: `ssh -L 7529:127.0.0.1:7529 pi@192.168.1.23`.

**The greeting says the first-boot setup hasn't finished.** Give it a minute and log in again. If it still says so: `sudo journalctl -u pi6529-firstboot` shows why, and `sudo pi6529 repair` runs it again.

**The link opens a page that can't sign.** You pasted the address without the `?token=...` part. Copy the whole line. `pi6529 link` makes a new one.

**`WAITING_HISTORY` or a progress bar for a long time.** Normal on the first start: about 20 minutes, sometimes 30. Leave it.

**`TOR_BLOCKED`.** Your network blocks Tor. The validator tries bridges by itself and keeps trying every five minutes. If it never gets through, the page offers to add a bridge of your own or to connect without Tor on this network (then other validators and Ethereum servers see your IP address). `pi6529 tor-report` gives you something safe to paste when you ask for help.

**`WAITING_SOURCE`.** No Ethereum server is answering through Tor right now. The validator moves between servers on its own. If it lasts hours, see the known issues below.

**`CLOCK`.** The Pi's clock is off. It sets itself from the internet; check that the Pi is online. `timedatectl` on the Pi should say "System clock synchronized: yes".

**The service isn't running.** `sudo pi6529 start`, then `pi6529 logs`.

**Anything else:** 6529's [known issues](https://6529.io/validator/known-issues) and [tester guide](https://6529.io/validator/guide) cover the validator itself. For the image, open an issue here. Never post raw logs or files from `/var/lib/6529-validator`: they show your keys and your account. `pi6529 tor-report` and the page's **Report a problem** are made to be safe to share.

---

## Settings

Before the first boot, you can open the small `bootfs` partition of the card on any computer and edit `pi6529.txt`:

```
name=         # a label for this Pi, shown only on its page (default: hostname)
mode=home     # home (Tor on, connects out only) or datacenter (Tor off, public address)
tor=on        # on or off
ui_port=7529  # the page's port on the Pi; the ssh command above uses it
country=      # two letters, optional
```

After the first boot, change settings on the page (**Settings**), or in `/var/lib/6529-validator/config.toml` followed by `sudo pi6529 restart`. `pi6529 settings` shows what the Pi was set up with.

## Raspberry Pi Imager entry

Raspberry Pi Imager can show pi6529 in its OS list so you skip the download. Start Imager with a custom list:

```
rpi-imager --repo https://raw.githubusercontent.com/MeltedMindz/pi6529/main/imager/os_list.json
```

(On a Mac: `open -a "Raspberry Pi Imager" --args --repo <that URL>`.) Then pick **pi6529** under Operating System. The entry is in [`imager/os_list.json`](imager/os_list.json) and carries the image's hashes, which Imager checks as it writes.

## What's on the image

- Raspberry Pi OS Lite (64-bit), Debian 13 "Trixie", 2026-10-06 release, unchanged except for the files below.
- The 6529 validator, from 6529's own `.deb` for ARM64, installed unmodified and checked against the SHA-256 6529 lists.
- `pi6529-firstboot.service`: sets the validator up on the first boot, on your Pi, so no password, key or config ever ships in the image.
- A wait of up to 90 seconds for the clock before the validator starts (a Pi has no battery clock).
- The `pi6529` helper and the login greeting.
- `jq` and `unattended-upgrades` (Debian security updates only; the validator is excluded).
- Wi-Fi power saving off; the log kept across reboots, capped at 200 MB.
- SSH enabled. No default user or password: you set them in Imager.

Every build is pinned in [`build/config.env`](build/config.env) and checked by [`build/check-image.sh`](build/check-image.sh). To build it yourself: [docs/BUILDING.md](docs/BUILDING.md).

## The project

- [Design](docs/superpowers/specs/2026-11-07-pi6529-design.md): why each choice was made.
- [Roadmap](docs/ROADMAP.md): what comes next, including pre-flashed cards and kits once 6529's validator has a public release.
- [Security](docs/SECURITY.md), [Hardware](docs/HARDWARE.md), [Building](docs/BUILDING.md), [Releasing](docs/RELEASING.md).
- [Talking to 6529](docs/6529-outreach.md): before anything is sold.
- [Changelog](CHANGELOG.md).

License: MIT for pi6529's own files. The 6529 validator is 6529 Collection LLC's, under the Apache License 2.0; its notices are kept on the image. Raspberry Pi OS is Raspberry Pi Ltd's and Debian's.
