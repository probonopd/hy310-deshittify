# Optional: a different launcher

Nothing in this repository requires you to replace the vendor launcher, and nothing here changes it by itself.
This page collects what is known, for those who want to try one, and documents a tested, fully reversible way to
do it: switch the Home role, keep the vendor launcher installed, switch back the same way whenever you want.

## Tried: Projectivy Launcher

[Projectivy Launcher](https://github.com/spocky/miproja1) (`com.spocky.projengmenu`), a free, actively maintained
Android TV launcher, sideloaded from its own GitHub releases (not the Play Store, which is disabled here). No
root or special permission is required for basic use; it asks for both during onboarding for extra features, and
declining both still leaves a fully working launcher.

```sh
adb install ProjectivyLauncher-<version>.apk
adb shell cmd role add-role-holder android.app.role.HOME com.spocky.projengmenu
```

This is the one that actually works: the `cmd package set-home-activity` approach other owners reported as not
sticking is the pre-Android-10 mechanism. Android 10 and later resolve Home through `RoleManager`, and
`cmd role add-role-holder` sets that role directly. Verify with `adb shell cmd shortcut get-default-launcher`.

Tested on the black and white logo version: installs cleanly, the role switch takes immediately (no reboot
needed), its onboarding can be completed without granting root or accessibility access, it auto-detects and
categorizes every installed app including all the ones from this repository, and it switches the HDMI input
itself through the same stock TV framework [hdmi-input](../hdmi-input/) uses, with no conflict between the two.
All of this repository's apps (Settings, HDMI, Projection, Assistant Settings) launch exactly as before; the
launcher has no effect on them.

### Revert to the vendor launcher

```sh
adb shell cmd role add-role-holder android.app.role.HOME com.htc.spectraos
```

Nothing else needs undoing: the vendor launcher was never touched or disabled, and the [projection](../projection/)
app does not depend on either launcher being active.

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

- Other owners report that Molla launcher also works
  ([notes](https://gist.github.com/probonopd/3ad6b7777caea1503f00d5fe7710ad06)); not tried here.
- A launch-on-boot ("start this app automatically") setting was reported by another owner as not working; not
  re-tested here.
- The HDMI input is not tied to the launcher: start it with the [hdmi-input](../hdmi-input/) app, or
  `am start com.softwinner.awlivetv/.MainActivity`.
- Do not disable or remove the vendor launcher until the replacement is the default and you have checked the
  remote, HDMI, Settings and the projection app.
- Undo is always: switch the Home role back (see above), or use Settings, Apps, Default apps, Home; and, if you
  changed any property from the previous section, set it back to the value you noted before.
