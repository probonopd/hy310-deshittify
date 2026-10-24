# Projection

The projector's own "Projection settings" screen lives in the vendor launcher, which runs as the
system user and cannot be moved into the stock Settings app (patching Settings changes its
signature, which Android refuses for a system-user app). This app reimplements the useful
controls on its own. **It needs root:** the settings it changes are protected system
properties and compositor calls. Allow "Projection" in the Magisk app on first start.

```sh
adb install hy310-projection.apk
```

Start it from the launcher's app list ("Projection"), or `adb shell am start -n io.github.probonopd.hy310projection/.ProjectionActivity`.
Up/down move between rows, OK or right changes a value, left goes back, back leaves.

| Row | What it changes |
|---|---|
| Auto keystone | `persist.sys.tpryauto`; switching it on tells the keystone service (`android.intent.hotack_keystone`), switching it off puts the saved corners back on the panel |
| Auto focus | `persist.sys.vafocus` |
| Auto four corner | `persist.sys.tpryxcrt` |
| Screen recognition | `persist.sys.mbrecognize` |
| Obstacle avoidance | `persist.sys.obstacle` |
| Digital zoom (0-20) | `zoom_value`, `persist.sys.zoom.value`, and the four panel corners through SurfaceFlinger |
| Manual keystone (4 corners) | opens a screen for the four corners: arrows move the marked corner (steps grow from 1 to 8 per press while a key is held), OK marks the next corner, holding OK resets, Back leaves. Refused while auto keystone or auto four corner is on, as in the vendor screen |
| Reset keystone | zeroes the manual keystone and the zoom |
| Installation mode | front, rear, front ceiling, rear ceiling, through the vendor TV service (HIDL `ITvServer`) |

Not included: device mode
and audio mode (hidden by default on the vendor screen), the camera calibration.

## How it works

Every row is a line `Label@@read command@@act command` in [src/res/values/strings.xml](src/res/values/strings.xml).
Commands run as root through `su -c` with `P` (the app's files directory), `APK` (the app's APK path)
and `$1` (1 or -1) set. To add a control, add a row. The shell logic for zoom and keystone is
[scripts/zoom.sh](scripts/zoom.sh); the manual keystone is the line-driven server [scripts/keystone.sh](scripts/keystone.sh) behind `KeystoneActivity`, which only shows its output and forwards the remote's keys. SurfaceFlinger itself stores the corners in `persist.display.keystone_*` on every call, so they survive a reboot; the script also keeps the `persist.htc.keystone.*` copy the vendor code reads. `embed-scripts.py` turns every `scripts/*.sh` into a string resource
that the app writes to its files directory at start. The installation mode uses
[Helper](src/smali/io/github/probonopd/hy310projection/Helper.smali), started as root with
`app_process`, which talks to the vendor TV service with `HwBinder`.

The zoom geometry comes from the vendor screen; set `ZOOM_MODE=4:3` or `16:10` for panels that are
not 16:9. `zoom.sh show N` prints what zoom N would do without doing it.

## Build

```sh
sh build.sh
```

(apktool with a framework installed, python3 with `cryptography`; see [../settings-launcher](../settings-launcher/).)

## Tested

Black and white logo version, Android 11, Magisk 30.7: every row changes the property or setting it should, and each was put back afterwards. The projected picture itself (zoom shrinking the image, installation mode flipping it) was not watched.
