# Root with Magisk

Needed for [../magisk-debloat](../magisk-debloat/) and [../usb-audio](../usb-audio/). The
boot image is patched by the Magisk app on the projector itself. Nothing is uploaded to any
website, and no patching tool runs on the PC.

Tested on the black and white logo version (`Projector.20250214.153635`) with Magisk 30.7.
The partition layout of the yellow version is the same, but rooting it was not tried.

## Already rooted?

```sh
adb shell su -c id
```

`uid=0(root)` means yes, skip this page. `su: not found` means continue.

## Needs

- A full backup of the eMMC, see [../fel-backup](../fel-backup/). Do not skip this.
- `adb` and `fastboot` on the PC, and ADB enabled on the projector (Settings > Developer
  options > USB debugging, or ADB over network).
- The Magisk APK from the official
  [releases page](https://github.com/topjohnwu/Magisk/releases) (tested: `Magisk-v30.7.apk`).

## 1. Get the stock boot image

The boot image is the GPT partition `boot_a`: sector 205824, 131072 sectors (64 MiB). Cut it
out of your own backup, so it is the image of this very unit:

```sh
dd if=emmc-1.img of=boot_a.img bs=512 skip=205824 count=131072
sha256sum boot_a.img        # write this down
```

Keep `boot_a.img`: it is the way back.

## 2. Patch it with the Magisk app

```sh
adb install Magisk-v30.7.apk
adb push boot_a.img /sdcard/Download/
```

On the projector, with the remote or a mouse:

1. Open the Magisk app. If it asks for additional setup, decline or ignore it for now.
2. **Install** > **Select and Patch a File** > pick `boot_a.img` in Downloads.
3. Wait for "All done!". The app writes `magisk_patched-<version>_<random>.img` to Downloads.
   The log should say `Pre-init storage partition: metadata`.

```sh
adb pull /sdcard/Download/magisk_patched-*.img .
```

The app offers no "Direct Install" on this device. That is expected: use the file patch.

## 3. Flash it with fastboot

```sh
adb reboot bootloader
fastboot devices                       # shows the projector (USB id 1f3a:1010)
fastboot flash boot_a magisk_patched-*.img
fastboot reboot
```

`Warning: skip copying boot_a image avb footer` is normal. Do not put a short timeout around
`fastboot flash`: it takes a while, and killing it mid-transfer leaves the bootloader hung
(unplug power and start again; the old boot image is still intact until a flash completes).

**Use fastboot, not a raw write.** The same patched image written byte for byte to the
`boot_a` sectors over FEL lands correctly and reads back correctly, but the bootloader never
runs it: Magisk shows `Installed: N/A` and there is no `su`. Flashing it with fastboot works.
Nor does patching on the PC (web patcher or Magisk's `boot_patch.sh`) help here; the write
path was the difference, not the patch.

## 4. Check

```sh
adb shell su -c id
```

The first call raises a root request dialog in the Magisk app; allow it. Expect
`uid=0(root) ... context=u:r:magisk:s0`. Then open the Magisk app once more: it should show
the installed version, not `N/A`.

## Undo

```sh
adb reboot bootloader
fastboot flash boot_a boot_a.img      # the stock image from step 1
fastboot reboot
```

Only `boot_a` is touched. Slot B is unused on this device.

## Notes

- 32-bit device (ARMv7 kernel and userland), so the 32-bit Magisk is what runs. Nothing to choose.
- dm-verity is not enforced and SELinux is permissive on the stock firmware, so no
  vbmeta or verity flags are needed.
- Remove the vendor OTA updaters first ([../debloat](../debloat/)): an OTA overwrites the
  patched `boot_a`.
