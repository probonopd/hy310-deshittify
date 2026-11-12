# X96Q (not a HY310 device - kept here for the overlapping research)

A generic "X96Q" Android TV box, sold as "Allwinner H313". Not a MAGCUBIC HY310 projector
or rebadge - a different product from a different vendor entirely. Kept in this repository
because the FEL/Allwinner findings below overlap with this project's own research, not
because it belongs under the HY310 umbrella.

## Identity

**Chip: FEL identifies it as H616, not a distinct "H313" silicon.**

```
$ sudo sunxi-fel version
AWUSBFEX soc=00001823(H616) ...
```

FEL SoC ID `0x1823` is mainline `sunxi-tools`' "H616" table entry - there is no separate
FEL ID for "H313". Independently corroborated by Armbian's own build docs
(`config/boards/README.md`): *"H618 and H313 boards use `sun50i-h616`"*. H313 is a
market-binned/rebranded H616, not different silicon.

**Android side - a real discrepancy, recorded rather than resolved by guessing:**

`ro.hardware`/`ro.boot.hardware` report `sun50iw9p1` - Allwinner's internal platform
codename baked into this vendor's kernel/BSP, a different string than the FEL-confirmed
"H616" identity. Does not contradict it (the BootROM's numeric SoC ID is unambiguous);
vendor BSPs for cheap TV boxes commonly carry over strings from whatever reference
platform their kernel fork originated from.

**Build - worth knowing if you have one of these:**

- `ro.build.version.release=11` but `ro.build.version.sdk=29` (Android 10's real API
  level, matching `ro.product.first_api_level=29`) - the release-version string is
  cosmetically overridden; the real framework underneath is Android 10. This is also why
  there is no "Wireless debugging" toggle in Developer options - that's a genuine Android
  11 AOSP feature, absent from the real API-29 framework.
- `ro.build.type=eng`, `ro.build.tags=test-keys` - **this is an engineering build, not a
  production one.** Consequence: `adbd` already runs as root out of the box -
  `adb root` succeeds immediately, no separate rooting procedure needed or attempted.

## USB device-mode gotcha

With Android booted normally, this box's USB-A port(s) present **no USB device at all** to
a host PC - not even unrecognized. The OTG controller only acts as a USB peripheral during
the BootROM/FEL stage; once Android's kernel takes over, it reconfigures that port as a USB
**host** (for a mouse/flash drive), not as a device a PC can talk to.

This unit has a vendor-added runtime toggle for it, in its own settings app: a switch
literally called **"USB0 device mode enable"**. Turning it on and rebooting makes the port
present itself as an Android USB device and `adb` can see it. There is no "Network ADB
debugging" vendor toggle on this build, and no "Wireless debugging" UI (see above) - USB
plus that switch is the only way in.

## Partition layout (GPT, single-slot, no A/B)

eMMC: 15,758,000,128 bytes (14.68 GiB), plus two 4 MiB hardware boot partitions
(`mmcblk0boot0`/`boot1`, mirror copies of each other) and an RPMB partition (not plain-dd
readable).

17 GPT partitions: `bootloader`, `env`, `boot`, `super` (dynamic: system/vendor/...),
`misc`, `recovery`, `cache`, `vbmeta`, `vbmeta_system`, `vbmeta_vendor`, `metadata`,
`private`, `frp`, `empty`, `media_data`, `Reserve0`, `UDISK` (`/data`, by far the largest
at 11.8G). Same `UDISK`/`frp`/`Reserve0` naming convention as the H713/H726 devices
elsewhere in this repository, despite being an unrelated product - evidently a shared
Allwinner reference layout/toolchain convention, not vendor-specific.

## Backup method used

Two full reads over USB `adb` (as root - see above), `adb exec-out dd if=/dev/block/mmcblk0
...` plus both hardware boot partitions. A **live** read while Android keeps running, not a
cold/FEL-level one (see below) - so exact byte-identity between two passes isn't expected
the way it is for a cold backup. In practice: both boot partitions were byte-identical
across passes, and hashing everything from the GPT through the last partition before
`UDISK` also matched exactly between passes - every byte of difference (about 0.24% of the
image) was confined to the live `/data` partition, consistent with normal filesystem
writes during the time each pass took, not a verification failure.

## What was tried and ruled out: the FEL/cold-boot path

The original plan was a cold, bootloader-level backup via FEL (`sunxi-fel uboot <file>`,
then `ums 0 mmc 0` to expose the eMMC as a USB drive, `dd` it from the host - nothing
written to eMMC, Android never boots for this), matching this repository's own
[fel-backup/](../fel-backup/) approach for the H713 devices. It did not work here and was
abandoned in favor of the live-adb method above:

- Built mainline U-Boot + ARM Trusted Firmware (`PLAT=sun50i_h616`) from source: first with
  a generic H616 board config (`orangepi_zero2_defconfig`), then with mainline's own
  **board-specific** `x96q_defconfig` (device tree `allwinner/sun50i-h313-x96q` - built for
  this exact model, not a generic stand-in).
- All three attempts - a UMS-modified generic config, a UMS-modified board-specific
  config, and a completely stock/unmodified board-specific config as a control - failed
  **identically**: `sunxi-fel` uploads the SPL, tells the BootROM to jump to it, and the
  USB connection goes unresponsive within about 250 ms, before SPL can write back its
  success signature (`usb_bulk_send() ERROR -1: Input/Output Error` on the readback). The
  device then needs a power cycle to recover. Nothing was ever written to eMMC at any
  point - FEL/SPL execution is RAM-only, regardless of outcome.
- Ruled out: image corruption (the built SPL's eGON.BT0 header, length and checksum were
  independently verified correct, matching exactly what `sunxi-fel`'s own pre-upload check
  computes); our own build changes (the stock, unmodified board-specific config failed the
  same way); a wrong/generic DRAM config (the real board-specific config failed identically
  to the generic one).
- Leading unconfirmed hypothesis: this specific unit's hardware (DRAM or another
  component) differs from whatever reference unit mainline's `x96q_defconfig` was tested
  against - a known issue with cheap TV boxes shipping the same model name across
  manufacturing batches with substituted components. Confirming this would need a
  UART/serial connection to see the SPL's own console output.

## Factory malware/spyware

Checked the full package list (`pm list packages -f`) against each app's actual granted
permissions (`dumpsys package <name>`), not just suspicious-sounding names. Found the same
category of factory-installed spyware already documented in this repository for the HY310
projectors (`com.android.vending` = a trojanized clone of the real Play Store, same
finding, same package name) - this appears to be an ODM-wide supply-chain pattern, not
specific to any one chip vendor or product line:

- **`com.android.vending`** ("Tubesky") - its own dex strings contain genuine Google Play
  endpoints (`android.clients.google.com`, `gvt1.com`): a repackaged/trojanized clone of
  the real Play Store, not a from-scratch fake. Requests `INSTALL_PACKAGES`,
  `DELETE_PACKAGES`, `SEND_SMS_NO_CONFIRMATION`, `RECORD_AUDIO`.
- **An unauthorized third-party app store** - silent-install capability
  (`REQUEST_INSTALL_PACKAGES`), `DISABLE_KEYGUARD`, overlay windows, bundling Chinese
  ad/analytics SDKs for its own storefront.
- **A fake "memory cleaner" and a generic "system update" app sharing the exact same
  overprivileged permission template** - both pre-grant themselves (`SYSTEM_FIXED`/
  `GRANTED_BY_DEFAULT`, not revokable from Settings) call-log and fine-location access
  that neither has any legitimate reason to need. Two differently-named, differently-
  purposed apps stamped from the same template is not a coincidence.
- **Factory burn-in/aging-test apps** with `INJECT_EVENT` (synthetic touch/key input
  anywhere in the system), `CAMERA`, `RECORD_AUDIO`, `DEVICE_POWER`, `MASTER_CLEAR` and
  `INTERNET` all together - a full remote-control profile if ever triggered over the
  network, the same category as the `runin.sh` backdoor documented elsewhere in this
  repository for the HY310 projectors, but considerably more capable.
- On a related device from the same ODM (different, non-Allwinner chip - out of scope for
  this repository, not detailed here): two further factory-test-named apps with an even
  more extreme permission set - `INJECT_EVENTS`, `MASTER_CLEAR`, `REBOOT`,
  `MANAGE_DEBUGGING`, `WRITE_SECURE_SETTINGS`, plus pre-granted camera/microphone/SMS/
  call/contacts/location access, all without ever showing a permission dialog. A textbook
  BadBox-class remote-control backdoor profile, not bloat.

All disabled via `pm disable-user --user 0 <package>` - reversible, no root procedure
needed on either device (both run `adbd` as root out of the box, being `eng`/`userdebug`
test-keys builds rather than production `user` builds - itself worth knowing, since it
means `adb root` works immediately on this ODM's units without any separate exploit).

## Disclaimer

Same as the rest of this repository: you can damage your device, back it up first, none of
this is affiliated with or endorsed by any manufacturer involved.
