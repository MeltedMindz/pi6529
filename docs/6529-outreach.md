# Talking to 6529 before anything is sold

The pasted brief said it well: 6529 encourage more validators in more homes,
and warn repeatedly about keys, grants and double votes. A design that
generates keys on-device, drafts grants on-device and only signs on the
owner's phone stays within their rules. Getting that blessed, and maybe a
link from their hardware page, is worth more than any marketing.

## Where

- The **Ministry of Validation** wave on 6529.io, where testers post results.
  6529's tester guide gives a template; use it, and post a real result from a
  real Pi first. Then the project.
- The `6529-Collections/6529seize-frontend` repo, where the validator pages
  live, once there is something concrete to link.

## What to say (draft, to adapt)

> I built a flashable Raspberry Pi image for the validator: Raspberry Pi OS
> Lite 64-bit with your `.deb` installed unmodified, set to start on the first
> boot. The image holds no key, no password and no config: the first boot
> runs `validator init` on the Pi, and the key is made on your page as usual.
> The page stays on 127.0.0.1; the README gives the SSH tunnel, and a small
> helper (`pi6529`) prints the one-time link and wraps `validator status`,
> `update check` and `diagnose tor`. Updates are never automatic: the helper
> shows the notes, verifies the feed through the validator's own key, checks
> the SHA-256 and asks before installing.
>
> It's an independent project, says so everywhere, and is private until your
> first public release. Two questions: is there anything in this design you'd
> want different before holders use it, and would you be open to linking it
> from the hardware page once it's public?

## What to have ready

- A boot on a real Pi 4 and Pi 5 with timings.
- The repo's SECURITY.md and the build's check list (nothing device-specific
  in the image).
- A clear "not affiliated" line, and no 6529 logos or names in the product's
  own branding beyond naming the validator it runs.

## What not to do

- Don't sell hardware or pre-flashed cards before the first public release:
  0.1.0 stops signing on 1 December 2026 and the first thing a customer would
  do is a mandatory update.
- Don't ship anything that touches the key: no backup, no export, no
  "transfer to a new Pi".
