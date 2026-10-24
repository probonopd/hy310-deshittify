---
name: h713-firmware-static-analysis
description: Use when asked what a piece of the HY310/H713 projector firmware does (autofocus, fan/tachometer, reboot or power-off paths, who handles a broadcast or uevent) by reading a full eMMC dump (see fel-backup/) without touching the device. Covers cutting partitions out of the dump with dd, parsing the dynamic-partition table of super in Python, mounting system/vendor/product (ext2-with-extents) read-only, unpacking boot_a (boot image v3) and vendor_boot_a (header offsets), the kernel's embedded config (IKCFG), the LZ4-legacy ramdisks without an lz4 tool, a Python device-tree walk without dtc, apktool/dex-string scans of APKs and services.jar, and established findings for the autofocus app and the fan/temperature shutdown path.
---

# H713 firmware static analysis (read the dump, never the live device)

Start from a full eMMC dump made with `fel-backup/`. Work on copies, never on the backup itself (keep it read-only, e.g. `chattr +i`). If the working disk is mounted noexec, run scripts with `sh`/`python3`.

## 1. Cut partitions out of the dump
`dd if=emmc-full.img of=X bs=512 skip=LBA count=SECTORS`. Take the LBAs and sizes from the GPT in the dump (`sgdisk -p emmc-full.img` or parse it). Partitions of interest: `boot_a`, `vendor_boot_a`, `super`, `env_a`, `dtbo_a`. Secure storage lies outside the GPT.

## 2. super: system_a / vendor_a / product_a
No lpunpack needed. Parse the LP metadata in Python: geometry magic 0x616c4467 at byte 4096; header at 12288 (magic 0x414c5030, header_size u32 at 8, tables_size u32 at 44, partitions {offset,num,entry_size} at 80, extents at 92); tables follow the header. Partition entry 52 bytes (name[36], attrs, first_extent, num_extents, group); extent 24 bytes `<QIQI` = (num_sectors, target_type, target_data, source). Cut each partition with dd from super (skip = target_data; `_b` slots are empty).
The images are ext2 with extents (ext4 without journal): `debugfs -R "rdump /app/X out" img` (ownership warnings are harmless) or `sudo mount -o ro,loop,noexec,nosuid img dir`. `umount` when done.

## 3. Boot images
- `boot_a` is Android boot v3: kernel size u32 @8, ramdisk size u32 @12, kernel at 4096, ramdisk at 4096 + align4096(ksize). Cmdline is empty (the U-Boot env supplies it). The kernel is a raw arm64 `Image`.
- Kernel config is embedded: find `IKCFG_ST` ... `IKCFG_ED`, `zlib.decompress(blob, 16+zlib.MAX_WBITS)`. Look up the CONFIG_ options you care about there.
- `vendor_boot_a` v3: page u32 @12, vendor ramdisk size @24, cmdline @28, **header_size @2096 (2112), dtb_size @2100**, ramdisk at align(hs,page), DTB at ramdisk + align(size,page). (@2104 is dtb_addr, not the header size.)
- Ramdisks are LZ4 legacy (magic `02 21 4c 18`, blocks of 8 MiB, 4-byte size each). No lz4 binary needed: a ~25-line Python LZ4 block decoder works. Then `cpio -idm`.
- DTB: no dtc needed. Walk the FDT structure block in Python (tokens 1=begin, 2=end, 3=prop, 9=end; strings at off_dt_strings).

## 4. Apps and the framework
- `apktool d -f -o dir app.apk` WITHOUT `-s` to get smali. `services.jar` decodes the same way (vendor patches live in `com/android/server/policy/PhoneWindowManager*`).
- Scan dex strings with `zipfile` (classes*.dex are compressed; plain grep on the APK finds nothing). Scan `.so` the same way. Restrict smali greps to the app's own package (`com/hysd`, `com/htc`); a loose regex drowns in okio/androidx output.
- Native libs: `readelf -sW --dyn-syms` for symbols; the UND list shows what a library can call at all (no reboot/system/audio import means it cannot reboot or play sound).

## 5. Component findings (firmware build Projector07241019)
- **Autofocus:** `com.hysd.vafocus` (/product/app/tpjz_allwinner, uid system, persistent) + `libduRYXtp.so` (`thread_fun_LCD_vafo10_HY260`, 0x23141 in lib/arm; vafo1..11 exist, chosen by `VaFocus` in camprjspe.ini). Motor via `/sys/devices/platform/motor_ctr/motor_ctrl` (driver built into the kernel). The library imports only log/ioctl/open/write. A 22 s timer (0x55f0 ms in LocalService) only resets `hotack.vaf.runend`/`hotack.touch.isProc` and calls `stopSelf`. Errors broadcast `system.exception.show` (code, tpflag); `PhoneWindowManager$52` shows toasts only.
- **Fan/tach:** the kernel logs `fan error,shutdown` and emits `FAN_STATE=RPM_ERR`; `PhoneWindowManager$19` (UEventObserver) broadcasts `com.htc.fanError`; the `CloseDialog_QZ` ManualFocusService (package `com.htc.closedialog`) shows a view for 4 s, then `PowerManager.shutdown` (power-off, not reboot). `TEMP_STATE=SHUTDOWN` -> `com.htc.tempHigh` -> 3 s view -> shutdown. This is a safety path; keep that package when debloating.

## Pitfalls
- Never write inside the backup; copy out first.
- `dd` offsets of an extent in super are relative to super, not the disk.
