# Assistant Settings

The Google Assistant's own settings (on/off, view permissions, **Searchable apps**, SafeSearch)
have no entry in the vendor launcher or in the stock Settings app. This 5 KB app is a launcher
entry named "Assistant Settings" that opens that screen
(`com.google.android.katniss/com.google.android.apps.tvsearch.preferences.activity.GoogleSettingsActivity`).
No root needed.

```sh
adb install hy310-assistant-settings.apk
```

Start it from the launcher's app list, or from the PC:

```sh
adb shell am start -n io.github.probonopd.hy310assistant/.Launch
```

Remove: `adb uninstall io.github.probonopd.hy310assistant`

## Why you want it

Voice commands such as "open SmartTube" only find apps that are switched on under
**Searchable apps**. An app that is switched off there is silently ignored by the Assistant.

## Build

Same as [../settings-launcher](../settings-launcher/): `sh ../tools/build-apk.sh . hy310-assistant-settings.apk`.

## Tested

Black and white logo version, Android 11, Google TV voice search 7.1: opens the Assistant settings.
