# hy310-deshittify

Notes and scripts for taking back control of the **MAGCUBIC HY310** projector and its
rebadges (Allwinner H713, Android 11): getting rid of the malware and adware it ships
with, rooting it, fixing features the vendor left broken, and backing it up safely
before touching anything.

Everything here was worked out on real hardware. Where something is a hypothesis rather
than a confirmed result, it says so.

## Why

The stock firmware is not just bloated. It ships with packages that phone home, inject
ads, upload telemetry, install apps silently, and come with their own unverified app
store and an OTA updater that can re-infect the device. Several of them hold
permissions such as camera, microphone, input injection and reboot. This repository
documents what they are, how to switch them off, and how to do it without bricking the
projector.

## Two firmware versions

There are at least two versions of this projector in circulation that look identical
from the outside. The easiest way to tell them apart is the boot logo:

| | Yellow MAGCUBIC logo at boot | Black and white MAGCUBIC logo at boot |
|---|---|---|
| Firmware build | `Projector.20250724.102119` (July 2025) | `Projector.20250214.153635` (February 2025) |
| Build fingerprint | `Allwinner/h713_tuna_p3/h713-tuna_p3:11/RP1A.201005.006/Projector07241019:user/release-keys` | `Allwinner/h713_tuna_p3/h713-tuna_p3:11/RP1A.201005.006/projector02141535:user/release-keys` |
| eMMC size (512-byte sectors) | 15,269,888 (about 7.28 GiB) | 15,335,424 (about 7.31 GiB, 32 MiB larger) |
| GPT layout | 26 partitions | Same 26 partitions, same offsets; only `UDISK` (`/data`) is larger |
| Vendor properties | not recorded yet | `persist.sys.Model=aodin`, `persist.sys.Channel=HY260Pro_SpectraOS_cyh` |

Do not assume an image, a dump or a partition offset from one version fits the other.
The partition table looks the same, but the dynamic partitions inside `super` sit at
different offsets on each unit, the eMMC sizes differ, and the firmware is five months
apart.

## What works so far

- **Full eMMC backup over USB (FEL)**, read-only, verified by taking it twice and
  comparing byte for byte. This comes first, before anything else.
- **Disabling the malware and bloat packages** on a running device. Tested on the black
  and white version; the change survives reboots.
- **Removing the malware and bloat for real** on a rooted device, with a Magisk module that
  hides the app directories and leaves every system partition untouched. Undo by disabling
  the module.
- **Root with Magisk** (black and white version). Lesson learned the hard way: write the
  patched boot image with `fastboot flash boot_a`. A raw write of the same image to the
  same sectors over FEL lands on disk and reads back correctly, but the bootloader never
  runs it.
- **Stock Android Settings** reachable again through a tiny launcher app (the vendor launcher
  has no entry for it).
- **An "HDMI" app** that switches to the HDMI input without any vendor app.
- **USB audio output** (on a rooted device). The vendor shipped the USB audio HAL
  disabled. A small Magisk module turns it back on, so USB headsets and DACs take over
  audio when you plug them in. Stereo devices work. One 5.1 device (Bose Companion 5)
  still stays silent, probably because of a USB timing limit in this kernel.

## Contents

| Directory | What |
|---|---|
| [fel-backup/](fel-backup/) | full eMMC backup over USB, do this first |
| [debloat/](debloat/) | disable the malware and bloat, no root needed |
| [root/](root/) | root with Magisk, patched on the projector itself |
| [privacy/](privacy/) | privacy hardening script (with undo) and a read-only audit against known malware indicators |
| [launcher/](launcher/) | optional: what is known about using a different launcher (nothing here changes it) |
| [docs/](docs/) | [related projects](docs/related-work.md) and [DRM (Widevine L3)](docs/drm.md) |
| [assistant-fonts/](assistant-fonts/) | keeps the Google Assistant from crashing when Play services are disabled |
| [projection/](projection/) | the vendor's projection settings (keystone, zoom, mode, auto focus) as a root app |
| [hdmi-input/](hdmi-input/) | an "HDMI" app that shows the HDMI input through the stock TV framework |
| [assistant-settings/](assistant-settings/) | an "Assistant Settings" app icon: Google Assistant, Searchable apps |
| [settings-launcher/](settings-launcher/) | an "Android Settings" app icon: the vendor hides the stock Settings app |
| [magisk-debloat/](magisk-debloat/) | remove it for real, systemless Magisk module (needs root) |
| [usb-audio/](usb-audio/) | Magisk module that turns USB audio back on (needs root) |

## Claude Code skills

[.claude/skills/](.claude/skills/) holds notes written for an AI coding assistant (Claude Code) that
doubles as a compact technical reference: FEL backup and guarded writes, rooting with Magisk, systemless
removal, reading the firmware, building APKs without the Android SDK, and the projection controls.
They are plain Markdown and readable without any tool.

## Never overwrite these

Each projector carries data that exists only on that one unit and cannot be recreated:

- **Secure storage** (outside the partition table): serial number and HDCP keys. Losing
  the HDCP keys permanently breaks HDCP-protected HDMI input.
- **`Reserve0_a`**: the panel and color calibration for this specific unit.
- **`frp`**: factory reset protection state.

Any full reflash that does not leave these alone is not safe.

## Related work

- [well0nez/allwinner-h713-linux](https://github.com/well0nez/allwinner-h713-linux):
  mainline Linux and an open boot chain for the H713. Its FEL tools are what make the
  backups here possible.
- [YuujiLab/HY300-H713-Research](https://github.com/YuujiLab/HY300-H713-Research):
  research on the closely related HY300, including a Magisk guide.

## Disclaimer

You can damage your device. Back it up first. None of this is affiliated with or endorsed
by the manufacturer.
