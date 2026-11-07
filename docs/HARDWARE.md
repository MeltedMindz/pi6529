# Hardware

6529's own hardware page is the source: https://6529.io/validator/hardware.
This page only translates it to a Raspberry Pi shopping list.

## What works

| | |
| --- | --- |
| Board | Raspberry Pi 5 (best) or Raspberry Pi 4. Both need the 64-bit OS, which this image is. A Pi 3 is not supported by this image. |
| Memory | 8 GB is best. 4 GB works with little to spare (the validator peaks under 2 GB once a day). 2 GB is too small. |
| Storage | Any: SD card, USB SSD, or an NVMe SSD on a Pi 5 HAT. The validator needs about 140 MB and adds about 25 MB a month. SD cards wear out; 6529 says start from an SSD if you can. A 16 GB card is plenty. |
| Power | The official power supply for your model. Under-powered Pis reboot at random, and a reboot at 00:15 UTC is a missed day. |
| Network | Ethernet or Wi-Fi. About 50 GB a month. No port to open on your router. |
| Cooling | A Pi 5 wants the active cooler or a case with a fan. The validator's daily calculation is a few seconds; the rest of the day it idles. |
| Clock | A Pi has no battery clock. It sets the time from the internet at boot; the image waits up to 90 seconds for that before starting the validator. A Pi 5 can take a small RTC battery; nice, not needed. |

## 6529's "Acceptable" tier, as a Pi

From 6529's page (prices read 31 October 2026, PiShop.us):

- Raspberry Pi 5, 8 GB: about $175 for the board
- about $300 with a power supply, a 256 GB SSD, a cooler and a case
- about 3 W; about $5 of power a year

## Booting from an SSD

Flash the same image to the SSD with Raspberry Pi Imager (pick the SSD as the
storage). A Pi 5 boots from NVMe or USB out of the box on current firmware; a
Pi 4 boots from USB once its bootloader is current (Imager has a "Bootloader"
entry under "Misc utility images" that updates it). Nothing in pi6529 cares
which drive it is on.

## What to avoid

- Running two Pis from one card image. See SECURITY.md: one key, one Pi.
- Cheap power supplies and long thin USB cables.
- Turning it off at night before it has signed (about 00:30 UTC). It signs
  when it next starts, until 19:00 UTC, but a Pi that is on all day is simpler.
