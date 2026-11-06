# A different chip: Allwinner H726 (sun50iw15)

**Everything else in this repository is about the H713 (`sun50iw12`). This page is about a
different SoC that is sold in the same family of white-label projectors** - Magcubic,
Gojodoq, HY300 Ultra/Pro/Max, model `ADT-3` - with Android 14 instead of Android 11.

Check which one you have before using anything here:

```sh
adb shell getprop ro.hardware     # H713: sun50iw12p1   H726: sun50iw15p1
```

or, in FEL mode:

```sh
sunxi-fel version                 # H713: soc=00001860(H713)   H726: soc=00001911(unknown)
```

If you have an H713, use the rest of this repository instead. Do not mix the two: partition
offsets, boot image formats, and the root method are all different.

## What's known so far

This is newer and much less mapped than the H713. No public `sunxi-fel`/U-Boot port exists
for this chip at the time of writing, and `sunxi-fel exec` against test payloads hangs the
unit (needs a hardware reset to recover; see "FEL" below). What follows works entirely
without FEL, over `adb` only, with the device otherwise untouched until you choose to write
anything.

Two independent community write-ups (not part of this repository) cover the same chip and
the same `ADT-3` board; where this page says "also reported elsewhere," that is them, not a
claim verified twice over here:
- a guide covering flashing a prebuilt rooted image via PhoenixSuit/FEL and keystone/display
  reverse-engineering
- an audit of the stock firmware's malware, with a root method very close to the one below

## Backup: a full `dd` over `adb`, no FEL, no root

Check first:

```sh
adb shell ls -l /dev/block/mmcblk0
```

On this firmware the whole eMMC block device is `brw-rw-rw-` - world read **and write** -
with SELinux permissive at runtime. That is not supposed to happen on a production device;
it is the single fact everything else on this page relies on. If your unit's `mmcblk0` is
not world-writable, none of the `dd`-based steps below apply to it as-is.

```sh
adb shell "dd if=/dev/block/mmcblk0 bs=1048576 2>/dev/null" > emmc-full.img
```

Take it twice, compare with `cmp`, and diff partition by partition (the GPT is readable with
any `gdisk`/Python `struct` parse) - everything should be byte-identical except `userdata`
and whatever else is actively mounted read-write while the device is powered on. Unlike the
H713 FEL backup elsewhere in this repository, this is a **live** dump (the device stays
booted), not an offline one; it is still a full, verified backup, just not a bit-for-bit
power-off image.

Find a partition's sector offset and size the same way (parse the GPT, or `adb shell ls -l
/dev/block/by-name/`), then `dd ... skip=<LBA> count=<sectors>` to pull just that one.

## Root: a raw write, no FEL, no bootloader unlock

The short version: patch `init_boot` with Magisk (offline, on a PC, since the device is not
rooted yet to patch itself), disable AVB verification in `vbmeta`, write both back to their
sectors on `/dev/block/mmcblk0` with plain `dd` from an **unprivileged** `adb shell`, reboot.

### 1. Get the stock partitions

```sh
adb shell cat /proc/partitions                       # or parse the GPT from the full dump
dd if=emmc-full.img of=init_boot_a.img bs=512 skip=<LBA> count=<sectors>   # 8 MiB partition
dd if=emmc-full.img of=vbmeta_a.img    bs=512 skip=<LBA> count=<sectors>   # 64 KiB partition
sha256sum init_boot_a.img vbmeta_a.img      # write these down
```

Slot B is typically empty (all zero) on these units - there is no fallback slot to switch to
if something goes wrong, only the stock image you just saved.

### 2. Patch `init_boot` with Magisk, offline

With no root yet, Magisk's own `boot_patch.sh` (inside the official APK, under `assets/`)
has to run somewhere. A PC with `qemu-arm-static` and the armeabi-v7a `libmagiskboot.so`
/`libmagiskinit.so`/`libmagisk.so`/`libinit-ld.so` extracted from the APK works, run step by
step rather than via the script directly (it re-execs into `bash` and expects on-device
`getprop`/`toybox`, neither of which exist on a plain Linux PC):

```sh
qemu-arm-static ./magiskboot unpack init_boot_a.img        # -> ramdisk.cpio, no kernel (init_boot is ramdisk-only)
KEEPVERITY=true KEEPFORCEENCRYPT=true qemu-arm-static ./magiskboot cpio ramdisk.cpio \
  "add 0750 init magiskinit" "mkdir 0750 overlay.d" "mkdir 0750 overlay.d/sbin" \
  "add 0644 overlay.d/sbin/magisk.xz magisk.xz" "add 0644 overlay.d/sbin/stub.xz stub.xz" \
  "add 0644 overlay.d/sbin/init-ld.xz init-ld.xz" "patch" "backup ramdisk.cpio.orig" \
  "mkdir 000 .backup" "add 000 .backup/.magisk config"
KEEPVERITY=true KEEPFORCEENCRYPT=true qemu-arm-static ./magiskboot repack init_boot_a.img new-boot.img
```

(`magisk`, `stub.apk`, `init-ld` get `compress=xz`'d into `magisk.xz`/`stub.xz`/`init-ld.xz`
first, same as `boot_patch.sh` does - see its source for the exact calls if reproducing this.)

Verify before doing anything else: `magiskboot cpio new-boot.img test` style check reports
status 1 ("Magisk patched"); the repacked file is the exact same size as the original
partition (ours was - no resize needed); unpacking it again shows `fstab.<your
ro.hardware value>` inside the ramdisk, confirming it is genuinely built from your own
device's image.

### 3. Disable AVB verification in `vbmeta`

Parse the real AVB header (not a guess): `algorithm_type` at byte offset 28 (u32),
`flags` at byte offset 120 (u32). On the unit this was tested on, `vbmeta_a` was
**genuinely signed** (`algorithm_type=1`, SHA256_RSA2048, a real embedded key) and its
descriptor list named `init_boot` among the partitions it covers - so the patched
`init_boot` has to be written together with a `vbmeta` that has verification turned off,
never alone. Flip only the 4-byte `flags` field at offset 120 to `3`
(`VERIFICATION_DISABLED | HASHTREE_DISABLED`); touch nothing else in the file.

### 4. Before trusting any of this: check whether your unit will even accept it

```sh
adb shell getprop ro.boot.verifiedbootstate
```

`orange` is the state both community write-ups above report, and what this page's own
testing found too: AVB verification runs, the result is "not the standard root of trust",
and **by the AVB specification that means warn and continue, never halt** - confirmed live
by a successful boot with a signed stock `vbmeta` producing exactly that state. That is
reassuring but not a guarantee for every build of this firmware; make your own full backup
first regardless (see above), and if `verifiedbootstate` reports anything other than
`orange`, stop and investigate before writing anything.

### 5. Write it

```sh
adb push new-boot.img /data/local/tmp/init_boot_a.new.img
adb push vbmeta_a.flags3.img /data/local/tmp/vbmeta_a.new.img
adb shell sha256sum /data/local/tmp/init_boot_a.new.img /data/local/tmp/vbmeta_a.new.img   # compare to local

adb shell "dd if=/data/local/tmp/init_boot_a.new.img of=/dev/block/mmcblk0 bs=512 seek=<LBA> conv=fsync"
adb shell "dd if=/data/local/tmp/vbmeta_a.new.img    of=/dev/block/mmcblk0 bs=512 seek=<LBA> conv=fsync"

# read back and compare to the files just written, BEFORE rebooting:
adb exec-out "dd if=/dev/block/mmcblk0 bs=512 skip=<LBA> count=<sectors> 2>/dev/null" | sha256sum
adb exec-out "dd if=/dev/block/mmcblk0 bs=512 skip=<LBA> count=<sectors> 2>/dev/null" | sha256sum
```

Only once both read back exactly matching the intended patched files: `adb reboot`. On the
tested unit, boot completed normally and `magiskd` came up running as root
(`adb shell ps -A | grep magiskd`), with no bootloop, across several repeats of this whole
procedure.

### Undo

Same `dd ... of=/dev/block/mmcblk0 seek=<LBA>` with the original `init_boot_a.img` and
`vbmeta_a.img` saved in step 1.

## A convenient `su` shell

`Superuser access` in the Magisk app shows "Apps and ADB" by default, and `magiskd` runs as
root - but `su -c id` through a copy of the Magisk client binary that was separately pushed
to the device (e.g. extracted from the APK to `/data/local/tmp`) is denied ("Accessed
denied"), no matter what the policy database says. The daemon does not treat an ad-hoc copy
as a legitimate caller. Use **Magisk's own properly-mounted binary** instead - `magiskinit`
places one at boot, found with `cat /proc/mounts | grep magisk` (look for a `tmpfs` entry
under `/vendor/xbin` or similar; the exact path can differ by firmware):

```sh
adb shell "/vendor/xbin/magisk su -c id"       # uid=0(root) ... context=u:r:magisk:s0
```

That is a normal, reliable, repeatable root shell - no further setup, no root-eval
workaround needed for this specifically.

Separately, worth knowing regardless of whether you use it: the stock firmware on these
units ships a factory PCBA burn-in script, `/system/bin/runin.sh`, wired into `init` to run
**as root** on every boot (`service runin_test /system/bin/runin.sh ... user root`), which
reads `/sdcard/runin_config` - world-writable, no root needed - line by line and `eval`s any
line starting with `loop=`. A line like `loop=1; <command>` therefore runs `<command>` as
root, triggerable on demand with `adb shell setprop debug.runin.restart 1` (no reboot). This
is a genuine, unauthenticated root-eval backdoor left in the production image, not something
built here - and it is exactly how root-level writes (installing a Magisk module, editing
`magisk.db`) were done above before `su` was available. If you use it, close it afterward
the same way the malware below is closed (a whiteout over `/system/bin/runin.sh` itself) -
leaving it open for your own convenience leaves it open for anyone else's too.

## Malware on this chip family

The same shape of thing documented for the H713 elsewhere in this repository, different
package names:

| What | Package / path | Behavior |
|---|---|---|
| Fake Play Store | `com.android.vending` | A modified store app ("Tubesky"), not Google's; signed by a different key |
| OTA updater | `com.htc.htcotaupdate` (`HtcOtaUpdate_QZ`) | Plain-HTTP check to a vendor OTA server, sends the device serial and MAC in every request; can re-push removed apps |
| App store dropper | `com.htc.storeos` (`StoreOs_QZ`) | Same shape, a second channel |
| Setuid-root `su` backdoor | `/system/xbin/hotacksu` | `-rwsr-sr-x root`, no authentication, any process that can exec it becomes root |

The OTA request is "signed" with a header that is just `SHA1(sorted "key"+"value" pairs of
the JSON body)` - no secret involved, verified by reproducing it independently - so it is a
tamper-check on the wire, not an authentication boundary; worth knowing if you ever need to
understand what that endpoint will or won't accept, not something this page turns into a
ready-made tool.

None of `pm disable-user --user 0 <package>` requires root and is the first thing to try; it
does not survive a factory reset or (on this firmware) always survive every reboot cleanly,
so recheck with `pm list packages -d` after a reboot before relying on it.

### Removing the setuid-root backdoor for real (needs root)

`/system` is read-only (`dm-0`, hardware level) even as root, so true deletion needs an
offline image repack; a systemless Magisk-module whiteout is the practical equivalent and
was what was actually used:

```sh
mkdir -p /data/adb/modules/neutralize_badbox/system/xbin
mknod /data/adb/modules/neutralize_badbox/system/xbin/hotacksu c 0 0
# same for /system/bin/qw, /system/bin/preinstall, and /system/bin/runin.sh once you are
# done using it (see above)
printf 'id=neutralize_badbox\nname=Neutralize firmware backdoors\n...' \
  > /data/adb/modules/neutralize_badbox/module.prop
chown -R 0:0 /data/adb/modules/neutralize_badbox
chcon -R u:object_r:system_file:s0 /data/adb/modules/neutralize_badbox
```

(`mknod` needs root - this is one of the things the root-eval backdoor above was used for,
before being closed by this same module.) Verified after reboot: all four paths
`ls: ... No such file or directory`; `pm path` empty for the store/OTA packages. A `/data`
update of a system app overrides a systemless `/system` whiteout - `pm uninstall --user 0
<package>` first if `pm path` still resolves to `/data/app/...` after installing the module.

## An unauthenticated debug port, baked into the display HAL

Worth checking for on any unit: `TCP 1234`, bound to `0.0.0.0` (every interface), with
**no authentication**. It speaks a line-based debug protocol (banner mentions a
`CF-Vision`-branded build) exposing hardware register read/write and a few other
display-pipeline debug commands - no general shell was found in it, but register-level
access to display/video hardware from anywhere on the same network, unauthenticated, is
still worth closing.

There is a separate binary and `.rc` service named `dbgserver` that looks like the obvious
suspect - it is not. Disabling it (`setprop persist.vendor.dbgserver 0`, the property its
`.rc` file is gated on) does not close the port, and no process by that name is ever
running. Checking which process actually owns the listening socket (walk every PID's open
file descriptors for the socket's inode in `/proc/net/tcp`) found the real owner: the
**`tvserver`** process itself (`/vendor/bin/hw/tvserver`) - the debug protocol is compiled
directly into the core display HAL, not served by the separate binary at all.

`tvserver` is load-bearing for the display - don't disable or restart it. Block the port at
the network layer instead, reapplied on every boot by a Magisk module's `service.sh`:

```sh
iptables -C INPUT -p tcp --dport 1234 -i wlan0 -j DROP 2>/dev/null ||   iptables -I INPUT -p tcp --dport 1234 -i wlan0 -j DROP
```

(scope the interface name to whatever your unit's Wi-Fi interface actually is). Loopback
stays open, so the port is still reachable over `adb forward` if you ever want to look at it
again; only the network path is closed.

## FEL

Does not currently work for anything beyond raw register reads on this chip (`sunxi-fel
version`, `hexdump` of fixed addresses). Loading and running a payload with `sunxi-fel exec`
hung the test unit twice, both for a 32-bit and a 64-bit test payload, requiring a hardware
reset each time; this page does not use FEL for anything as a result. The guides referenced
above describe bringing up DRAM and a full U-Boot this way (the fix being: no RVBAR jump is
needed on this chip, unlike the H713, and loading the vendor's own `fes1.fex` - extracted
from a stock firmware image, not published anywhere - directly to SRAM `0x0010C000` works)
but even that does not reach eMMC read/write; both write-ups still flash through PhoenixSuit
on Windows, not through FEL/U-Boot directly.
