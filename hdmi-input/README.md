# HDMI input app

A full-screen "HDMI" app that shows the projector's HDMI input. It uses only Android's stock
TV Input Framework: a `TvView` tuned to the passthrough URI of an HDMI input. It does not
use the vendor's source selector or TV app (`com.softwinner.awsource`, `com.softwinner.awlivetv`)
or any vendor launcher, so those can be removed. No root needed.

```sh
adb install hy310-hdmi.apk
```

It registers as a launcher and a Leanback (TV) launcher app named "HDMI". Start it from the
launcher's app list, or from the PC:

```sh
adb shell am start -n io.github.probonopd.hy310hdmi/.HdmiActivity
```

Keys: left/right (or channel down/up) switch between the HDMI inputs (a short "HDMI n/m"
note appears), back leaves. The last input is remembered. Without a signal the system's input
service shows its own blue "No signal" screen.

## What it needs from the system

The system's video input service (`com.softwinner.vis`, `/system/priv-app/VideoInputService`,
running as `com.softwinner.awtvinputservice`) registers the inputs `HW1` to `HW3` as HDMI and
`HW4` as CVBS. That is the driver side of the TV input and has to stay installed. The app asks
`TvInputManager` for all inputs of type HDMI, sorted by id, and shows an error toast and exits if
there are none.

## Build

Sources in [src/](src/) (manifest, one smali class, vector icon); build and signing as in
[../settings-launcher](../settings-launcher/):

```sh
sh ../tools/build-apk.sh . hy310-hdmi.apk
```

## Tested

Black and white logo version, Android 11: shows the HDMI input and switches between inputs.
