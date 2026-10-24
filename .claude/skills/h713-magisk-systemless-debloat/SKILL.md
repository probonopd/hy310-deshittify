---
name: h713-magisk-systemless-debloat
description: Use when removing (not just disabling) vendor apps on a rooted HY310/H713 projector or any Magisk device with read-only /product and /system, when deciding whether a disabled package is safe to delete, when building or editing a Magisk module that hides app directories with .replace markers, or when deciding what the vendor firmware needs kept (com.htc.closedialog). Covers the safety analysis, module layout per partition, the generator in this repo, verification and undo.
---

# Systemless removal of vendor apps (Magisk .replace)

In this repo: `magisk-debloat/install.sh` (generator), `debloat/packages.txt` (list), keep list in `debloat/README.md`, root setup in `root/README.md`. Back up the APKs before removing anything.

## Is it safe to delete a disabled package?
Runtime view: removed == disabled. Check, per package: path (`pm path`), sharedUserId (UID 1000 packages are fine while others share it), anything it actually does for the hardware. Static check without trusting permission lists: pull the APK, scan dex strings (`zipfile`, regex for URLs, java/net, MediaRecorder, AudioRecord); look at requested permissions, not granted ones (a system UID is granted everything, which made `com.htc.closedialog` look like malware: it has no INTERNET permission, no URLs, no audio code, and it shows the fan-error and overtemp screen, then powers off). Keep safety paths.

## How (no remount, partitions untouched)
Module `/data/adb/modules/<id>/` with `module.prop` and, per app directory, an empty `.replace` file: `/product/app/X` -> `system/product/app/X/.replace`, `/system/priv-app/X` -> `system/priv-app/X/.replace`, `/system/system_ext/...` -> `system/system_ext/...`, `/vendor/...` -> `system/vendor/...`. Magisk overlays an empty directory at boot. The generator refuses packages not in a per-app directory of a known partition and removes /data updates with `pm uninstall` first (otherwise `pm path` points at /data and the system copy stays). Back up APKs first (`adb pull -a`; create the target dir first or the pull flattens it). Copy the module with `su -c cp -r`, chown root, `chcon u:object_r:system_file:s0`.
Test without touching the device: `install.sh --build-only DIR`.

## Verify and undo
Reboot (~1 min), `pm path` empty for each, `pm list packages -d` shows only the expected, launcher up, `logcat -b crash` empty, hardware apps (autofocus `com.hysd.vafocus`, remote) running. Undo: `touch /data/adb/modules/<id>/disable` and reboot; disabled state was never changed, so apps return disabled. A reflash or OTA restores everything from super.

## Pitfalls
- `pm disable-user` is persisted ~10 s later: wait 20 s before `adb reboot`.
- The no-root `debloat/disable.sh` is for unrooted units; the module is the rooted path.
