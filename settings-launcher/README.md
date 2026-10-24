# Android Settings launcher

The vendor launcher replaces Settings with its own screens, and the standard
`android.settings.SETTINGS` intent resolves to nothing. The stock Settings app is still
installed (`com.android.settings`, it opens fine when started by component name), it just has
no way in. This is a 5 KB app with a gear icon whose only job is to start it. No root needed.

```sh
adb install hy310-settings.apk
```

It registers as a launcher app and as a Leanback (TV) launcher app, named "Android Settings".
Start it from the app list of the launcher, or from the PC:

```sh
adb shell am start -n io.github.probonopd.hy310settings/.Launch
```

Remove: `adb uninstall io.github.probonopd.hy310settings`

## Build it yourself

[src/](src/) is a manifest, one smali class and one vector icon. You need `apktool`, a
framework installed into it (once: `adb pull /system/framework/framework-res.apk && apktool if
framework-res.apk`) and python3 with `cryptography`:

```sh
sh build.sh
```

`tools/sign.py` signs with a v1 (JAR) signature, which Android 11 accepts for an app that targets
SDK 28, so `apksigner` is not needed. The signing key is created in `build/` (repository root) on the first
run and is not part of the repository; keep it if you want to install updates over the
prebuilt app.

The gear is the Material Design "settings" icon (Apache License 2.0).

## Tested

Black and white logo version, Android 11: the app starts the stock Settings app, listed as
`com.android.settings/.Settings`.
