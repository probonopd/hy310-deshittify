---
name: h713-fel-backup
description: Use when asked to back up, dump, or image the eMMC of an Allwinner H713-based projector (HY310, HY300 Pro, HY260Pro and similar rebadges) via FEL/USB mode, or to get this device into a known-good FEL state before any other FEL work. Covers entering FEL mode, the well0nez/allwinner-h713-linux installer tools (sunxi-fel, u-boot-installer.bin) versus mainline sunxi-tools, the udevil/devmon auto-mount trap that corrupts a "read-only" dump, the installer's hardcoded SECTORS_EXPECTED refusing a same-model-different-eMMC-size device, and the 20-second drive-enumeration race that reports "No drive has appeared" even though the drive is already up. Also covers verifying a backup with a second pass and a byte-for-byte compare before trusting it.
---

# H713 FEL eMMC backup

Step-by-step for end users: [fel-backup/README.md](../../../fel-backup/README.md). This skill
is the condensed procedure plus pitfalls. Re-check every parameter on a new unit.

## Before anything: stop the automounter

Stop any automounter first (and re-enable it afterward).

Check:

```bash
ps aux | grep -i devmon
```

If a `devmon` process (from `udevil`) is running, **kill it before exposing any eMMC as a
USB drive**. It auto-mounts ext4 partitions read-write (its config only forces `ro` for
FAT/ISO/UDF, not ext4), which can collide with a "read-only" dump mid-transfer and bring
the whole USB link down. This happened in practice: it produced a real write attempt on the exposed disk.

```bash
kill <devmon-pid>
```

Check `ps aux | grep -iE 'udisks|gvfs'` too if unsure what this system runs.

## Get the right tools

Do **not** rely on a mainline/distro `sunxi-tools` build for anything beyond
`sunxi-fel version` or `spiflash-*`. Use the `well0nez/allwinner-h713-linux` project's own
prebuilt release instead -- their `sunxi-tools` fork adds H713-specific reserved-region
guards that mainline lacks; a raw SPL/U-Boot upload at the wrong address with the stock
tool can hang the BootROM's USB stack.

```bash
BASE='https://github.com/well0nez/allwinner-h713-linux/releases/download/v0.95-beta'
curl -sS -L -o sunxi-fel "$BASE/sunxi-fel"
curl -sS -L -o u-boot-installer.bin "$BASE/u-boot-installer.bin"
curl -sS -L -o BUILD.txt "$BASE/h713-hy310-v0.95-beta.BUILD.txt"
chmod +x sunxi-fel
```

Verify `u-boot-installer.bin` against the truncated sha256 in `BUILD.txt` (the release's own
`.sha256` manifest only covers the install-image parts, not the tool binaries):

```bash
grep u-boot-installer.bin BUILD.txt
sha256sum u-boot-installer.bin           # leading hex digits must match
```

Also clone the repo itself (for `installer/h713-install`, the actual backup driver):

```bash
git clone --depth 1 https://github.com/well0nez/allwinner-h713-linux.git
```

If the working directory is mounted `noexec`, run the tools from a scratch directory
elsewhere.

## Enter FEL mode

Unplug power -> hold reset -> plug power in -> hold ~2 more seconds -> release. Device
stays dark; that's expected. The FEL flag does not survive a power cycle, and nothing
persists if something goes wrong -- a plain power cycle always recovers to normal boot.

```bash
lsusb | grep -i allwinner     # expect: 1f3a:efe8 ... FEL/flashing mode
```

## Run the backup

```bash
sudo python3 allwinner-h713-linux/installer/h713-install dump --full \
  --sunxi-fel ./sunxi-fel --uboot ./u-boot-installer.bin \
  -o ./out --yes
```

`--full` reads the whole eMMC (`--small` is only the ~49 MiB device-unique regions --
not enough for a real backup). This loads U-Boot over FEL ("not one byte onto the eMMC"),
exposes the eMMC as a plain USB drive, and reads it -- nothing is written. When it
finishes, power cycle the device (the only way out of the exposed-drive state).

### If it refuses with "X has N sectors, expected M -- wrong drive?"

The installer has a hardcoded `SECTORS_EXPECTED` matching the one profile it knows
(HY310's size at the time of writing). There is no override flag for `dump`. Don't patch the
constant -- instead, once the eMMC is already exposed (see next section to confirm it is),
back it up directly:

```bash
sudo blockdev --getsize64 /dev/sdX          # confirm the real size first
sudo dd if=/dev/sdX of=emmc-full.img bs=4M conv=sync,noerror
```

This is exactly as read-only as the installer's own path -- plain `dd` from a block
device, no mount involved.

### If it reports "No drive has appeared"

This can be a genuine failure, or it can be the installer's own 20-second wait
(`installer/h713/fel.py`, a 20 x 1 s loop) simply being too short for
this cable/port. **Check before re-triggering FEL from scratch:**

```bash
lsusb                      # does it show 1f3a:1010 (fastboot) instead of efe8 (FEL)?
lsusb -t                   # look for "Mass Storage ... Driver=usb-storage"
lsblk                      # is /dev/sdX (with ~26 partitions) already there?
```

If the drive is already up, skip the FEL+wait step entirely and use it directly:

```bash
sudo python3 allwinner-h713-linux/installer/h713-install identify --device /dev/sdX --yes
```

(or jump straight to the `dd` backup above). Only re-trigger a fresh FEL cycle if the
device truly isn't exposing anything after this check.

## Always verify with a second pass

One dump proves nothing by itself -- verify by repeating the whole thing (power cycle,
re-enter FEL, dump again to a second file) and comparing:

```bash
sha256sum pass1/emmc-full.img pass2/emmc-full.img
cmp pass1/emmc-full.img pass2/emmc-full.img && echo IDENTICAL
```

Only trust the backup once both the hash and the byte-for-byte `cmp` agree.

## Don't assume one device's parameters fit another

Same model name/branding does not mean same hardware. Confirm per-device, every time:

- eMMC sector count (`blockdev --getsize64`) -- can differ between "identical" units.
- Build fingerprint from `identify`'s output -- can be a completely different build date.
- Whether `identify` finds a matching profile at all (an unmatched device is a note, not
  a stop, for reading -- but never assume a *write*/install image built for one device is
  safe on another without a fresh profile match).
