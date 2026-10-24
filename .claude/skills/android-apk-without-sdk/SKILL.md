---
name: android-apk-without-sdk
description: Use when an Android app has to be built on a host that has java and apktool but no Android SDK (no javac, aapt, d8, apksigner), e.g. a tiny launcher or shortcut APK for a TV box or projector. Covers a hand-written smali activity plus manifest and vector icon built with apktool b, the apktool.yml fields and framework install it needs, a pure-Python v1 (JAR) signer using cryptography, targetSdk 28 so v1-only is accepted on Android 11, and install and test steps.
---

# Build and sign a tiny APK without the Android SDK

Worked example: `settings-launcher/` in this repo (src/ and README); shared tooling in `tools/build-apk.sh` and `tools/sign.py`.

## Recipe
- `src/AndroidManifest.xml`, `src/smali/<pkg path>/Foo.smali` (one Activity, `Theme.NoDisplay`, `finish()` in onCreate), `src/res/drawable/icon.xml` (vector). No Java compile needed: write the smali by hand (constructor, `onCreate` calling super, building an Intent with `setClassName`, `startActivity`, `finish`).
- A launcher entry needs MAIN + LAUNCHER, and MAIN + LEANBACK_LAUNCHER for TV launchers; add `uses-feature` touchscreen and leanback with `required=false`; set `android:banner`.
- apktool needs a framework: once, `adb pull /system/framework/framework-res.apk` then `apktool if framework-res.apk`. Without `usesFramework: ids: [1]` in a hand-written `apktool.yml` the link step fails with "attribute android:name not found" (which hides the real cause). apktool.yml minimal: version, usesFramework, sdkInfo min 21 target 28, versionInfo.
- `apktool b proj -o unsigned.apk`, then sign. targetSdk 28 means v1-only signing is accepted on Android 11 (apps targeting R need v2). `sign.py`: MANIFEST.MF, CERT.SF with SHA-256 digests, CERT.RSA from `cryptography` `PKCS7SignatureBuilder` with DetachedSignature, Binary, NoCapabilities; self-signed RSA 2048 key kept outside version control (the repo ignores `build/`) so that later updates install over earlier ones; keep resources.arsc stored.
- Run the scripts with `sh` when the project disk is mounted noexec.
- Install: `adb install x.apk`; test with `am start -n pkg/.Activity` and `dumpsys activity activities | grep mResumedActivity`, screenshot with `adb exec-out screencap -p`.

## Pitfalls
- Check `which javac aapt2 d8 apksigner jarsigner` first; a minimal host may only have java, keytool, apktool and python3.
- apktool `if` overwrites the installed framework (`~/.local/share/apktool/framework/1.apk`); do not delete one you did not install.
- Manifest lines in the v1 signer are limited to 72 bytes; keep entry names short or implement wrapping.
- Whether the vendor launcher lists the app is launcher specific; check on the device.

## Second example: TV input viewer
`hdmi-input/` in the same repo: a TvView in a fullscreen activity, `TvInputManager.getTvInputList()` filtered on `getType()==1007` (TYPE_HDMI), `tune(id, TvContract.buildChannelUriForPassthroughInput(id))`, `reset()` in onPause, ordered insert by id in smali (`compareTo`). One signing key in `build/` (repo root) serves all apps so updates install over each other.
