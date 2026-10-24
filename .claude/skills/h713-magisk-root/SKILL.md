---
name: h713-magisk-root
description: Use when asked to root an Allwinner H713-based Android projector (HY310, HY300 Pro and similar rebadges) with Magisk, or to edit a vendor config file or kernel cmdline parameter on an already-rooted one. Covers why a byte-correct Magisk patch written via FEL/dd can silently never execute while the same image written via fastboot works immediately, how to build a reversible Magisk module overlay instead of writing the real /vendor partition, and how to edit the kernel cmdline on a GKI header-v3 device (it lives in vendor_boot, not boot's own header).
---

# H713 Magisk root, fastboot write path, and vendor-config overlay editing

Step-by-step for end users: [root/README.md](../../../root/README.md). Debloat afterwards:
[magisk-debloat/](../../../magisk-debloat/). This skill is the condensed procedure plus the
lessons behind it.

## The core finding: write boot images via fastboot, not FEL/dd

A raw FEL/dd write to `boot_a`'s GPT sectors can land on disk -- read back and
checksum-verified correct -- and still never take effect at boot. Confirmed directly:
three independently-produced Magisk-patched `boot_a` images, all written via FEL/dd, all
silently ignored by the bootloader (device booted completely normally, patch present on
disk but `magiskinit` never ran, zero trace in `dmesg`/`logcat`). The *same* image,
written instead via `fastboot flash boot_a`, worked immediately.

fastboot's flash path does real partition-aware handling a plain sector copy doesn't --
it logs this itself (`Warning: skip copying boot_a image avb footer (boot_a partition
size: 0, boot_a image size: ...)`), confirming it's doing more than `dd`. Whatever that
is, this bootloader apparently requires it to treat a write as a legitimate boot image.

**Practical rule: always use `fastboot flash`, never FEL/dd, for any boot-image write on
this hardware family**, unless the device genuinely cannot reach fastboot mode (no
working adb to run `adb reboot bootloader` and no button combo found).

```bash
adb reboot bootloader
lsusb | grep -i allwinner   # expect: 1f3a:1010 ... fastboot mode
fastboot devices -l
fastboot flash boot_a patched-boot_a.img
fastboot reboot
```

Don't put a short timeout on `fastboot flash` for a 64 MiB+ image -- killing the host
process mid-transfer leaves the device's fastboot USB protocol state hung (enumerates,
but stops responding to anything, even `getvar`). Recoverable with a plain power cycle,
same as a stuck FEL session -- no corruption, just retry after the cycle.

## Rooting procedure

1. Pre-flight: confirm no AVB/`verify` fstab flag (dm-verity not enforced -- check the
   device's own `vendor_a` fstab from its backup), confirm architecture
   (`ro.product.cpu.abilist` from `system_a/system/build.prop`), confirm
   `ro.boot.slot_suffix` (A/B slot actually active).
2. Get a stock `boot_a` backup first, always -- either from the full eMMC backup already
   taken, or carved live: `adb shell "cat /sys/block/mmcblk0/mmcblk0p5/start
   /sys/block/mmcblk0/mmcblk0p5/size"` then `adb exec-out "dd if=/dev/block/mmcblk0
   bs=512 skip=<start> count=<size> status=none" > boot_a-stock.img`.
3. Install the Magisk app on-device (`adb install Magisk-vX.Y.apk`), push the stock
   `boot_a.img`, use the app's own "Select and Patch a File" flow (on-device patching
   correctly auto-detects the real pre-init storage partition -- a host-side
   `boot_patch.sh` run can't, since `./magisk --preinit-device` needs a real Android
   device to resolve). Pull back `magisk_patched-*.img`.
4. `adb reboot bootloader`, `fastboot flash boot_a magisk_patched-*.img`, `fastboot
   reboot`.
5. Verify: `adb shell "su -c id"` should show `uid=0(root) ... context=u:r:magisk:s0`;
   `dmesg` should show the `magisk --post-fs-data`/`--service`/`--boot-complete` chain
   actually executing.
6. To revert: `fastboot flash boot_a boot_a-stock.img` (step 2's backup), same way.

## Editing a vendor config file: Magisk module overlay, never a raw `/vendor` write

`/vendor` is typically `ext4`, mounted `ro`, backed by a `dm-linear` node carved out of
the dynamic `super` partition -- not dm-verity (check the fstab flag per-device), so it
remounts rw under root without any bootloader unlock. **Don't actually do that.** A raw
remount-rw-and-edit is unnecessarily risky (an interrupted write corrupts a live system
partition) and non-persistent (reverts to `ro` on next boot without an fstab change
too). Use a Magisk systemless module instead -- it's root-independent of the real
partition, and trivially reversible:

```bash
adb push fixed-config.xml /sdcard/Download/
adb shell "su -c '
MOD=/data/adb/modules/<your-module-name>
mkdir -p \$MOD/system/vendor/etc
cp /sdcard/Download/fixed-config.xml \$MOD/system/vendor/etc/fixed-config.xml
chmod 644 \$MOD/system/vendor/etc/fixed-config.xml
chcon u:object_r:vendor_configs_file:s0 \$MOD/system/vendor/etc/fixed-config.xml
cat > \$MOD/module.prop <<EOF
id=<your-module-name>
name=<Display Name>
version=v1
versionCode=1
author=local
description=...
EOF
touch \$MOD/auto_mount
'"
adb reboot
```

Verify after reboot with `mount | grep <filename>` -- it should show the file served
from `/data` (f2fs), not the real `/vendor` block device. Remove entirely with `rm -rf
/data/adb/modules/<your-module-name>` + reboot.

## Editing the kernel cmdline: check the boot header version first

On a **GKI header v3+** device (check with `magiskboot unpack -h <boot_a.img>` --
pattern-match for `HEADER_VER [3]` or higher), `boot`'s own header has **no cmdline
field at all** (`CMDLINE []` even after a successful unpack). The real cmdline lives in
`vendor_boot`'s header instead. Confirm with the same command against `vendor_boot_a`.

```bash
# find vendor_boot_a's own LBA offset/size (differs by device -- don't assume)
adb shell "su -c 'cat /sys/block/mmcblk0/mmcblk0p7/start /sys/block/mmcblk0/mmcblk0p7/size'"
adb exec-out "su -c 'dd if=/dev/block/mmcblk0 bs=512 skip=<start> count=<size> status=none'" > vendor_boot_a-current.img

mkdir vb_edit && cd vb_edit
magiskboot unpack -h ../vendor_boot_a-current.img   # writes an editable 'header' file here
sed -i 's/^cmdline=.*/& your.new.param=value/' header
magiskboot repack ../vendor_boot_a-current.img ../vendor_boot_a-patched.img
cd ..

adb reboot bootloader
fastboot flash vendor_boot_a vendor_boot_a-patched.img
fastboot reboot

adb shell "su -c 'cat /proc/cmdline'"   # confirm the new param made it through
```

`magiskboot repack` preserves the original image size exactly (pads/compresses to
match) -- confirm the output file size matches the partition's own size before flashing.

A kernel module parameter only shows up this way if it's actually settable via cmdline
(check `ls -la /sys/module/<mod>/parameters/<param>` first -- if it's `-r--r--r--`,
cmdline-only is in fact the *only* way to set it at all, since it's not writable live via
sysfs either).

## Don't assume a workaround that sounds right actually is

A `quirk_alias` kernel parameter set this way (aliasing one USB device's quirk behavior
onto another's) was tried for a USB-audio underrun problem, on the strength of a device
identity match (same VID:PID as a device with a documented upstream ALSA bug) and kernel
version timing (older than the upstream fix). It was fully confirmed active at the
kernel level (`dmesg` showed the alias being applied) -- and made the actual symptom
*worse*, not better. Verify a fix against the actual measured behavior
(`dumpsys media.audio_flinger`'s underrun/overrun counters, in that case), not just
against "did the mechanism activate."

## Notes
An OTA overwrites a patched `boot_a`: remove or disable the vendor OTA updater apps first
(see [debloat/](../../../debloat/)). Stock `boot_a` lives at sector 205824, 131072 sectors, in
the full eMMC dump ([fel-backup/](../../../fel-backup/)).
