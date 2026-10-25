# Two vendor binaries that look suspicious: `qw` and `dbgserver`

A community write-up calls `/system/bin/qw` a hidden su helper with a daemon on TCP port 65528, and the
[audit script](../privacy/) flags both files. We analyzed copies of the two binaries from the black and white logo
firmware (`Projector.20250214.153635`). For `qw` the root-escalation finding below is proven live (one harmless
command, `id`, run through it from an unprivileged UID); `dbgserver` was analyzed statically only, nothing
executed and the device only read. Items marked UNVERIFIED are inferred from the code and were not tested.

**Neither binary comes from anything in this repository or from rooting the unit.** Both sit in `/system`, carry
the firmware's original `2008-12-31` placeholder build timestamp (the marker other stock files in this image carry;
a file added afterward would show the real date), and `qw`'s SELinux labels (`qw_exec`, `qw_socket`) are custom
types that only resolve because the vendor's own precompiled policy defines them. Rooting this unit only ever
touched the `boot_a` partition (a Magisk-patched kernel and ramdisk, flashed with `fastboot flash boot_a`, see
[../root](../root/)); nothing we do writes to `/system`. `qw` is also unrelated to Magisk's own su: the package
name baked into it, `com.koushikdutta.superuser`, belongs to an old, separate Android root app ("Superuser",
Chainfire/Koush era, roughly 2011-2014), not anything Magisk uses. The vendor shipped this daemon running,
unauthenticated, by default, before anyone roots or modifies the unit.

| | `/system/bin/qw` | `/vendor/bin/dbgserver` |
|---|---|---|
| sha256 | `4c60fe89e8334f4d18f83b575ec84375ccdbc93c8cb8acd08fdb11a26ef5354e` | `c695c4aed53d9c36547925509c8f7594d74141d495cd0f4266f11f5cb9d452e0` |
| Type | 32-bit ARM, statically linked, stripped, 388 KB | 32-bit ARM, dynamic, stripped, 31 KB |
| Owner, mode | `root:shell` 0755 | `root:shell` 0755 |
| SELinux label | `qw_exec` | `dbgserver_exec` |
| Started by | init, `/system/etc/init/qw.rc`: `service qw /system/bin/qw --daemon`, `user root`, `class core` | init, `/vendor/etc/init/dbgserver.rc`: only when `persist.vendor.dbgserver` is 1 |
| State on the tested unit | running as root, all capabilities, SELinux domain `qw` | not running, the property is unset |

## `qw`: an unauthenticated root daemon, proven live

- It is a build of the Android **Superuser** su (Koush's `com.koushikdutta.superuser`, version string
  `15 com.koushikdutta.superuser`), statically linked. Evidence: its usage text (`--daemon`), its paths for the
  Superuser app data, and its log messages ("Allowing root/system/radio", "Allowing shell", "request rejected").
  There is no proxy, reverse shell, URL, domain or IP address in it.
- **The claim of a daemon on TCP port 65528 is wrong for `qw`.** It only creates an `AF_UNIX` socket:
  `/dev/com.koushikdutta.superuser.daemon/server`, mode 0777, label `qw_socket`. Port 65528 belongs to
  `dbgserver` (below), which is probably where the confusion comes from.
- The daemon reads the caller's identity from `SO_PEERCRED` (unspoofable) and **proven live: it performs no
  real authorization**. We reverse-engineered its wire protocol (plain integers over the stream socket: pid,
  isatty, uid, ppid, a mount flag, then a length-prefixed argv; the client then opens per-pid FIFOs under
  `/dev/com.koushikdutta.superuser.daemon/<pid>.{stdout,stderr,stdin}` for I/O and reads back an exit code; no
  file-descriptor passing), built a minimal native client for it, and connected from an ordinary, unprivileged app
  UID (10071) that could not even create its own file in `/data/local/tmp`. The daemon forked a root child anyway
  and ran `id`, which wrote, as root, a file in that same directory containing `uid=0(root) gid=0(root)
  groups=0(root) context=u:r:qw:s0`. The Superuser app and its database are not installed, so there is no prompt,
  password or allow-list anywhere on this path. The separate client-side check in the official `qw` binary (it
  refuses to even try connecting unless its parent process's name is one of three vendor test-app strings) is not
  a security boundary: it is client code the caller controls, and the test above bypassed it entirely by speaking
  the protocol directly.
- **Consequence:** any code that can run at all on the device, with no privileges of its own, becomes root with no
  prompt. An installed app, a compromised app, or anyone with `adb shell` access, all become root immediately. A
  network peer cannot reach it directly (it is a local unix socket, not a TCP port), but once such a peer has any
  local code execution, this closes the gap to root instantly. SELinux was in permissive mode on the tested unit,
  so its rules restricted nothing there (whether enforcing policy would stop the connect is UNVERIFIED). We found
  no sign of command and control: it looks like an insecure vendor or ODM root helper left enabled, not a
  deliberate backdoor, though the practical effect is the same.
- Nothing else in the init files starts or mentions it (the `qw_sign` line in the USB script is an unrelated
  gadget attribute). Likely casualties if it were removed: the vendor aging and factory test apps, if they use it
  (UNVERIFIED). Magisk root is a separate path and does not depend on it.

## `dbgserver`: dormant, but unauthenticated if switched on

- A vendor hardware bring-up debug server (banner `dbgserver2 version 3.0`, Allwinner/Trident lineage). It is
  not a shell and not a process-memory dumper.
- It would listen on **TCP 65528 on all interfaces with no authentication**, as root, up to 100 clients. The
  protocol is a 2-byte command, a 2-byte length and a payload of up to 16 KB. The 45 handlers include SoC
  register read and write through a mapped window, raw I2C on three buses, SPI, UART, and generic device and file
  access: a client-supplied file name is prefixed with `/Reserve0/mips/` or `/tmp/` and opened with
  client-supplied flags (whether `..` is rejected is UNVERIFIED), plus a few fixed `system()` calls such as
  mounting a FAT partition on `/tmp` (whether any handler passes client text to `system()` is UNVERIFIED).
- It starts only if `persist.vendor.dbgserver` is 1 (`=0` stops it). The property was empty on the tested unit and
  nothing listened on 65528. The `persist.vendor.` namespace is not settable by ordinary apps under stock policy
  (not verified against the compiled policy).
- If it were ever switched on, a LAN peer could read and write registers and I2C devices (display, panel and
  projector hardware) and create or read files in those two directories, or crash it.

## What to do

- Check, read-only: `adb shell getprop persist.vendor.dbgserver` (empty or 0 is fine) and
  `adb shell su -c 'ss -tln'` (nothing on 65528). The [audit script](../privacy/) does both and lists the two
  binaries as leads.
- Keep the projector off untrusted networks (a separate guest network or VLAN), and block TCP 65528 at the router
  as a precaution.
- `qw` is the one that matters locally, and it is already running by default on a stock unit. Removing its init
  script (`/system/etc/init/qw.rc`) needs a change to the system image or a Magisk overlay and has not been built
  yet, so it is not part of this repository. Do not delete the binaries by hand on a unit that boots from a
  verified `/system`.
