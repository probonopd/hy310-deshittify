# Magisk debloat

[../debloat](../debloat/) only disables the malware and bloat packages. This module removes
them for real, without modifying any system partition. Needs root (Magisk).

```sh
adb connect <projector-ip>:5555
./install.sh
adb reboot
```

What it does:

1. Reads [../debloat/packages.txt](../debloat/packages.txt).
2. Removes `/data` updates of those packages (`pm uninstall`), so the system copy is what is left.
3. Pulls the APKs to `backup-<serial>/` (skip with `--no-backup`).
4. Builds the Magisk module `hy310_debloat`: for every package, an empty `.replace` marker in
   the package's directory (`system/product/app/<dir>/.replace`, and so on). At boot Magisk
   mounts an empty directory over the original, so the package manager never sees the app.
   `/product`, `/system` and `/vendor` stay byte for byte unchanged.
5. Installs the module to `/data/adb/modules/`. Reboot to activate.

The script stops without changing anything if a package does not live in a per-app
directory of a known partition. `./install.sh --build-only DIR` writes the module tree to
`DIR` and touches neither the device's packages nor its modules.

## Undo

Disable the module and reboot:

```sh
adb shell su -c "'touch /data/adb/modules/hy310_debloat/disable'"
adb reboot
```

The apps come back, still disabled (the disabled state is stored by Android and was never
changed). Re-enable one with `pm enable <package>`. Deleting
`/data/adb/modules/hy310_debloat` makes it permanent to undo as well. A reflash or an OTA
restores the apps from the `super` partition.

## Kept on purpose

Packages the hardware needs are listed under "Keep" in [../debloat/README.md](../debloat/README.md) and are
not in `packages.txt`, so this module never touches them.

## Tested

Black and white logo version (`Projector.20250214.153635`), Magisk 30.7: all 16 listed
packages gone after reboot, launcher, remote and autofocus apps unaffected.
