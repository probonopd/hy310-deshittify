# Stop the qw root daemon from starting at boot

The vendor ships `/system/bin/qw`, a su daemon derived from the old "Superuser" app, running as root at
every boot with **no authentication**: any code running on the device, with no privileges of its own, can get
a root shell through it. This was proven live, not just inferred from the binary; see
[../docs/qw-and-dbgserver.md](../docs/qw-and-dbgserver.md) for the evidence. It predates this project: it is
part of the stock firmware, not something rooting or any other tool here adds.

This module stops it from starting at boot. It does not delete or patch the binary, and does not need
`/system` to be writable. `qw` is a `class core` service, and first-stage init starts class-core services
before a Magisk module's file overlay for `/system` takes effect, so marking it `disabled` in an overlaid
`qw.rc` alone does **not** stop it (we tried that first; it did not work, see below). The module overlays
`qw.rc` anyway for documentation and in case a future firmware parses it later, but the actual enforcement is
two Magisk boot scripts (`post-fs-data.sh` and `service.sh`) that call `setprop ctl.stop qw` and, if that does
not take, kill the process directly, each retrying for a few seconds. `post-fs-data.sh` runs too early on this
firmware to catch it (`qw` has not started yet), `service.sh` runs later and does. Both are kept since boot
order is not guaranteed to be identical on every build. Needs root (Magisk).

```sh
./install.sh
adb reboot
```

`./install.sh --build-only DIR` writes the module tree without touching the device. The script reads the
device's own `qw.rc` and refuses to install anything if that file does not look exactly like what this script
expects, rather than guessing.

## Verify

```sh
adb shell su -c "pidof qw"
```

Before: prints a pid. After the module and a reboot: prints nothing. (`getprop init.svc.qw` is not reliable
here: init still reports `running` even after the process has been killed, because init started it itself and
does not know the module's script then stopped it.)

## Undo

```sh
adb shell su -c "touch /data/adb/modules/hy310_qw_disable/disable"
adb reboot
```

The daemon starts again at the next boot after that.

## What this does not fix

- `qw` could still be started manually by anyone who already has root (`su -c 'start qw'`), which is not a new
  risk: they already have root at that point.
- There is a short window early in boot, before `service.sh` runs, where `qw` may be up; this closes it well
  before the system is usable, but it is not instant-at-power-on.
- The vendor factory and aging test apps may use `qw` to get root; if any of them stop working after this
  module is installed, that is why (not confirmed either way; see the docs page).
- It does not touch `/vendor/bin/dbgserver`, which already stays off by default
  (`persist.vendor.dbgserver` unset) and needs no module.

## Tested

Black and white logo version, Android 11, Magisk 30.7. Installed and rebooted on the device twice: the first
version (rc-overlay only) left `qw` running despite the file correctly showing `disabled`, confirming the
timing problem above; the current version (with the two boot scripts) was verified on the device after a
reboot with `pidof qw` returning empty, where it had returned a pid before.
