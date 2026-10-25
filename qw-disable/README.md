# Stop the qw root daemon from starting at boot

The vendor ships `/system/bin/qw`, a su daemon derived from the old "Superuser" app, running as root at
every boot with **no authentication**: any code running on the device, with no privileges of its own, can get
a root shell through it. This was proven live, not just inferred from the binary; see
[../docs/qw-and-dbgserver.md](../docs/qw-and-dbgserver.md) for the evidence. It predates this project: it is
part of the stock firmware, not something rooting or any other tool here adds.

This module stops it from starting at boot. It does not delete or patch the binary, and does not need
`/system` to be writable: it overlays `/system/etc/init/qw.rc` with the same content plus `disabled` added to
the service, which is how Android's own init marks a service as present but not auto-started. Nothing else in
init starts or references `qw`, so this is enough. Needs root (Magisk).

```sh
./install.sh
adb reboot
```

`./install.sh --build-only DIR` writes the module tree without touching the device. The script reads the
device's own `qw.rc` and refuses to install anything if that file does not look exactly like what this script
expects, rather than guessing.

## Verify

```sh
adb shell getprop init.svc.qw
```

Before: `running`. After the module and a reboot: not `running` (service exists but was never started).

## Undo

```sh
adb shell su -c "touch /data/adb/modules/hy310_qw_disable/disable"
adb reboot
```

The daemon starts again at the next boot after that.

## What this does not fix

- `qw` could still be started manually by anyone who already has root (`su -c 'start qw'`), which is not a new
  risk: they already have root at that point.
- The vendor factory and aging test apps may use `qw` to get root; if any of them stop working after this
  module is installed, that is why (not confirmed either way; see the docs page).
- It does not touch `/vendor/bin/dbgserver`, which already stays off by default
  (`persist.vendor.dbgserver` unset) and needs no module.

## Tested

Black and white logo version, Android 11, Magisk. Build and property-insertion logic tested against a copy of
the device's `qw.rc`; the full install-reboot-verify cycle on the device is pending (the installer failed
before it reaches the device if the file does not match, so it is safe to try).
