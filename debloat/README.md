# Debloat

Disables the malware and bloat in [packages.txt](packages.txt) on a running device. No
root needed, no flashing, fully reversible.

```sh
adb connect <projector-ip>:5555
./disable.sh
adb reboot
```

Undo: `./enable.sh`

On a rooted device, [../magisk-debloat](../magisk-debloat/) removes the same packages instead
of disabling them.

Wait for the script to finish before rebooting. Android saves the disabled state about
10 s after `pm disable-user` returns; reboot sooner and the packages come back.

## Keep

Needed for the hardware, do not disable:

| Package | Why |
|---|---|
| `com.hysd.vafocus` | autofocus (app is called `tpjz_allwinner`) |
| `com.htc.magcubicos` | launcher, keystone |
| `com.htc.htcbluetoothremotecontrol` | the remote |
| `com.htc.closedialog` | shows the fan-error and overtemperature screen, then powers the projector off (safety). Requests no `INTERNET` permission, contains no URLs and no audio recording code; the earlier "network, mic" flags came from its shared system UID |
| `com.mphotool.*`, `com.softwinner.miracastReceiver` | AirPlay, DLNA, USB cast, Miracast |
| `com.softwinner.awsource`, `com.softwinner.awlivetv`, `com.softwinner.TvdVideo` | HDMI input |

`com.android.nfc` shows up as disabled by default. That is normal; there is no NFC
hardware.

Netflix, Disney+ and YouTube are not preinstalled. Google Play stays, so install the real
apps from there.

## Disabled, but never removed

[keep-installed.txt](keep-installed.txt) lists packages that `disable.sh` disables but that must stay
installed. Today that is `com.htc.hyk_test` (the vendor's "factory test" app). It looks like pure
bloat, but it is tied to the Bluetooth remote: when the package was removed from the package manager
(by hiding its folder with [../magisk-debloat](../magisk-debloat/)), the remote no longer reconnected on
its own after a reboot. Its first key press then reached the window manager as key code 293, which
hard-codes starting the setup wizard's "Bluetooth remote control connection" screen, so the pairing
screen appeared after every reboot. With the package present but disabled, the remote reconnected at
boot by itself. Disabling is enough, removal is not. This held over four reboots (package hidden: pairing screen
both times; package present, enabled or disabled: no pairing screen). The mechanism is not proven. The package has nothing
to do with the remote itself (its Bluetooth code is a manual speaker test, it has no HID or remote logic, and
the remote service never mentions it). The leading hypothesis is that it shares the system user id 1000 with
the remote service and the other vendor apps: Android grants a shared user id the union of the permissions
requested by all packages with that id, so removing a package can take permissions away from the others,
while a disabled package keeps contributing them. The same may be true of other packages:
when you hide more, hide them one at a time and check the remote after a reboot.

If you ever switch the removal module off for a test, run `disable.sh` again afterwards. Un-hiding a package
resets it to enabled, and the vendor app store then updated itself over the network into `/data/app` within a
couple of minutes (and an AirPlay component updated too). `adb shell pm uninstall <package>` removes such a
copy again.
