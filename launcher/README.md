# Optional: a different launcher

Nothing in this repository requires you to replace the vendor launcher, and nothing here changes it. This page
only collects what is known, for those who want to try. **Everything below is untested by us unless it says
otherwise.** Keep the vendor launcher installed until you have checked that you can still reach everything you need.

## What the vendor launcher does and does not do

Verified by reading its code and the framework (static analysis, and the device with the launcher running):

- It does no work at boot and handles no hardware keys. Hardware keys, the HDMI source start at boot, the
  Bluetooth speaker switch and the autofocus start all live in `system_server`, not in the launcher.
- Its settings screens (projection, picture, audio, power, network, Bluetooth) are plain front ends. The
  [projection](../projection/) app in this repository reproduces the hardware ones, and stock Settings covers
  WLAN, hotspot, Bluetooth pairing, date and time, language, apps and factory reset
  ([settings-launcher](../settings-launcher/) gives it an icon).
- It runs as the system user and is signed with the platform key. A normal replacement launcher is not, so it
  cannot do the privileged things the vendor one does (reboot, write secure settings, install packages).

## What points at the vendor launcher

The system starts some vendor screens by name, from system properties. List them on your unit (read-only):

```sh
adb shell getprop | grep -E 'persist.sys.(homePackage|settings_|power_|manualkeystone_|filemanager_|AliveAppName)|lmk_top_app'
```

The ones naming the launcher are `persist.sys.homePackage`, `persist.sys.settings_package` and `_class`,
`persist.sys.manualkeystone_package` and `_class` (the remote's keystone key), and `sys.lmk_top_app`. If the
launcher is gone, keys that open those screens do nothing useful until the properties are changed. The
power and file manager entries name other vendor packages.

## Things to know before trying one

- Other owners report that Projectivy and Molla launchers work, that `cmd package set-home-activity` did not
  stick, and that a launch-on-boot setting did not work
  ([notes](https://gist.github.com/probonopd/3ad6b7777caea1503f00d5fe7710ad06)). Setting the default Home through the
  Android role manager is the next thing to try, and we have not tried it.
- The HDMI input is not tied to the launcher: start it with the [hdmi-input](../hdmi-input/) app, or
  `am start com.softwinner.awlivetv/.MainActivity`.
- Do not disable or remove the vendor launcher until the replacement is the default and you have checked the
  remote, HDMI, Settings and the projection app.
- Undo is always: make the vendor launcher the default again (Settings, Apps, Default apps) and, if you changed
  any property, set it back to the value you noted before.
