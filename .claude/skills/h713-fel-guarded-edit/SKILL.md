---
name: h713-fel-guarded-edit
description: Use when a change must be written to an HY310/H713 projector's eMMC over FEL (well0nez sunxi-fel + u-boot-installer exposing the eMMC as /dev/sdX), e.g. env_a, /oem (media_data vfat), /data (UDISK f2fs), or when restoring a unit to its dump. Covers the guarded script pattern (identity proof, size checks, in-place writes, read-back), FEL link pitfalls, which files init reads from /oem, and how to find what a boot changed by diffing the live disk against the dump.
---

# H713 guarded FEL edit and restore

Get the tools and a verified full dump first: [fel-backup/](../../../fel-backup/) and the
`h713-fel-backup` skill. Never write without that dump.

## Script pattern
1. Stop any automounter first (re-enable afterwards). Copy the tools to a scratch directory that is not `noexec`; run with sudo.
2. `./sunxi-fel uboot u-boot-installer.bin`, wait for the partition devices (`/dev/sdX26` etc.). ABORT on any error before writing; a failed link never wrote anything.
3. Identity before every write: `blockdev --getsz /dev/sdX` equals the sector count from your own dump, and a hash of the secure-storage region (LBA 12288, 2048 sectors) equals the hash taken from your own dump. Check the target partition size too. Never overwrite secure storage (it holds the unit's identity).
4. Save the live file first (`*.before`), edit a copy, write IN PLACE (`sh -c 'cat new > file'`, never cp/mv: keeps inode, owner, SELinux label), `sync`, `cmp`, umount.
5. Mounts: vfat `-t vfat -o rw,nosuid,nodev,noexec /dev/sdX23`, f2fs `-t f2fs -o rw,nosuid,nodev,noexec /dev/sdX26` (no `noload` for f2fs). Partition numbers = GPT numbers.
6. Raw writes of a bounded region: `dd ... conv=fsync`, assert the range, read back with `cmp` against the source.
7. Power cycle is the only way out of the exposed state.
8. Boot images: a raw FEL write of a patched boot image never runs; use `fastboot flash` (see `h713-magisk-root`).

## FEL link pitfalls
Use the A-to-A cable with VBUS cut. Errors `usb_bulk_send/recv`, "unable to enumerate", or a 1f3a:1010 fastboot leftover mean: power-cycle the unit again, wait for 1f3a:efe8. Do not use `pkill -f` with a pattern that also matches your own command line; kill by PID.

## Restore to original and prove it
Compare the live disk to your dump per region (python, 1 MiB chunks, list differing sectors): GPT, env_a/b, boot_a, vendor_boot_a, dtbo_a, super. Units dirty some regions on their own at boot: ext4 superblock mount count and group flags, FAT dirty bit, /data logs. Rewrite differing sectors from the dump only inside a region you can justify (assert the range), then re-read for 0 differences. Copy a partition out with `dd` and run `fsck.vfat -n` on the COPY, never the live one.

## Where init reads from (no system/vendor edit needed)
`/oem` is partition media_data, mounted in first stage with fstab flag `check` (fsck every boot), then second stage with `errors=panic`, so a damaged /oem filesystem stops boot. `/oem/customer.prop` is loaded by vendor init.
