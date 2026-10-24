---
name: h713-projection-controls
description: Use when reading, changing or reimplementing the vendor projection controls of an HY310/H713 projector (auto keystone, auto focus, auto four corner, screen recognition, obstacle avoidance, digital zoom, reset, manual four-corner keystone, installation mode front/rear/ceiling, camera), when the vendor launcher (com.htc.spectraos) may be removed, or when building a root-driven Android app from shell snippets and smali. Covers where each control lives (properties, Settings.Global, SurfaceFlinger transact 1050, vendor HIDL ITvServer, broadcasts), what the camera features do, the line-driven root script pattern, the HwBinder helper via app_process, and the pitfalls hit.
---

# H713 projection controls without the vendor launcher

Public result: `projection/` in this repo (app in `src/`, `scripts/zoom.sh`, `scripts/keystone.sh`, `src/smali/.../Helper.smali`, `build.sh`, `embed-scripts.py`). Related skills: android-apk-without-sdk, and the Magisk root setup in `root/README.md`.

## Why a new app
The vendor screen (`ProjectActivity` in com.htc.spectraos) runs as `android.uid.system`, is not exported, and cannot be moved into stock Settings: Settings is also uid system, and a patched APK changes its signature, which Android refuses. So: a normal app that uses root (Magisk `su -c`) for the writes. The device owner must allow it in Magisk once.

## Where each control lives
- Switches are plain properties holding 0/1: auto keystone `persist.sys.tpryauto`, auto focus `persist.sys.vafocus`, auto four corner `persist.sys.tpryxcrt`, screen recognition `persist.sys.mbrecognize`, obstacle avoidance `persist.sys.obstacle`. The consumers are native (the autofocus app `com.hysd.vafocus`, lib `libduRYXtp.so`); no broadcast needed except auto keystone ON: `am broadcast -a android.intent.hotack_keystone --ei ratio 1`. Auto keystone OFF re-applies the saved corners (`persist.sys.zoom.value`).
- The four camera features (auto focus, auto four corner, screen recognition, obstacle avoidance) all need the USB camera (0bda:5803, `/dev/video2`, external camera HAL, API1 camera 0). Obstacle avoidance finds objects in the projected area (the lib has add/reset obstacle points) so the fitted picture avoids them; screen recognition finds the screen to fit to. The autofocus app logs "no camera exists, disable ..." without it. `persist.sys.camok` (1 = camera ok) and `persist.sys.focusupdn` select which rows the vendor shows.
- Compositor corners: `service call SurfaceFlinger 1050 f lb.x f lb.y f lt.x f lt.y f rt.x f rt.y f rb.x f rb.y`, each value per-mille / 1000 (0x41a = 1050 on `android.ui.ISurfaceComposer`; `service call` takes `f` floats). Positive = inward. SurfaceFlinger itself stores them in `persist.display.keystone_{lt,lb,rt,rb}{x,y}` on every call (so reboot persistence is native) and `persist.htc.keystone.*` is the copy the vendor code reads: write both. Clamp each axis: v >= 0 and v + opposite corner <= 1000 (pairs x: lt/rt, lb/rb; y: lt/lb, rt/rb). Zero all = reset (also `persist.sys.zoom.value 0,0,0,0,0,0,0,0`).
- Digital zoom 0..20: `settings put global zoom_value N`, corners per vendor `changeform` (16:9: scale 1.0, steps 16 x 9; 4:3 and 16:10 differ), SurfaceFlinger push when auto keystone is off, persist only plus the broadcast when it is on.
- Installation mode 0 front, 1 rear front, 2 front ceiling, 3 rear ceiling: HIDL `vendor.aw.homlet.tvsystem.tvserver@1.0::ITvServer` instance `default`, transaction 0x8d get / 0x8c set, parcel: interface token, int32 type=3 (MIRROR), [int32 value]; reply verifySuccess then int32. Then `setprop persist.sys.panelvalue N`; if camok=1 and focusupdn=0 remap the stored corners; if auto keystone is on broadcast `android.intent.projective_mode`.
- The remote's keystone key starts the activity named by `persist.sys.manualkeystone_package` / `_class` (vendor value is com.htc.spectraos CorrectionActivity).
- Manual keystone is refused by the vendor while auto keystone or auto four corner is on; copy that.

## Patterns that worked
- Rows as data: `Label@@read cmd@@act cmd` in a string-array, run as `su -c "P=<filesDir> APK=<apk> sh -c '<cmd>' sh <arg>"` on a background thread; scripts embedded as string resources and written to the files dir at start (`embed-scripts.py`; escape and use `formatted="false"`, `\n`).
- A line-driven root server for interactive screens: the activity starts `su -c 'sh keystone.sh server 2>&1'`, writes `key CODE REPEAT` lines to its stdin and shows every stdout line (`|` = newline); all logic (selection, step ramp 1..8, clamping, hold-OK reset at repeat 10) stays in shell. Catch the reader's IOException on exit or the app crashes when leaving.
- Vendor binder calls from a non-system app: write an original smali class with `HwBinder.getService(desc, "default")` and `HwParcel`, run it as root with `CLASSPATH=<our apk> app_process /system/bin <class> args`. Do not copy vendor smali into a public repo.
- Camera preview: stock API1 `Camera.open(0)` + SurfaceView; `pm grant ... CAMERA` from the root command that launches the activity; the camera is 640x480 4:3 only, so letterbox. `screencap` shows the preview surface black; check by eye.
- Test live but put everything back: record `getprop`/`settings` baseline first, restore after, check the SurfaceFlinger pid and `logcat -b crash`.

## Pitfalls
- smali: non-range invoke takes at most 5 registers including `this`; `move-object` and `if-*` use 4-bit registers, so keep parameters low (reduce `.locals`) or use `/from16`; `invoke-virtual/range` needs consecutive registers.
- A stray `KEYCODE_BACK` in a test script closes the app mid-test; keep key scripts explicit.
- `su` grant: the first launch's Magisk prompt can be recorded as Deny if nobody answers; only the device owner should allow it. Do not delete the policy or press the dialog for them.
- If the project disk is noexec, run scripts with `sh`; `adb pull -a <dir>` into a non-existing target flattens it.
- Properties differ per unit and over time (auto keystone may be on, then off): read before assuming.
- Never `cat` the files under `/sys/class/prj/` to look around: one of them (`bl_duty`) blocks on read, and the unit went offline and restarted shortly after. Only touch nodes you know, and never write `fan2power` (fan, lamp panel and status LED share that switch).
- Display sleep (`KEYCODE_SLEEP` / `goToSleep`) is the vendor's standby: the unit left the network even with a kernel wake lock held, so it is not a way to switch only the projection off.
