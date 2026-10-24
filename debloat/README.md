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
| `com.mphotool.*`, `com.softwinner.miracastReceiver` | AirPlay, DLNA, USB cast, Miracast |
| `com.softwinner.awsource`, `com.softwinner.awlivetv`, `com.softwinner.TvdVideo` | HDMI input |

`com.android.nfc` shows up as disabled by default. That is normal; there is no NFC
hardware.

Netflix, Disney+ and YouTube are not preinstalled. Google Play stays, so install the real
apps from there.
