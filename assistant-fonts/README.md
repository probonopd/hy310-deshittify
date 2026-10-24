# Assistant fonts (for use without Google Play services)

With Google Play services disabled, the Google app (Assistant, voice search, the remote's voice
button) recognizes your speech and then crashes: its result screen asks the Play services font
provider for Google Sans and dies with `Font resource ID ... could not be retrieved`. This was
already the case before any privacy hardening, as soon as Play services is off.

The font descriptors in the app prefer a **system font family of the same name**. This Magisk
module adds the `google-sans*` family names to `/system/etc/fonts.xml`, backed by the Roboto
files that every Android ships. Google's own font is not included. Needs root.

```sh
./install.sh
adb reboot
```

`./install.sh --build-only DIR` writes the module tree without touching the device. The script
builds the module from the device's own `fonts.xml`, and does nothing if a `google-sans` family
already exists. `/system` is not modified, Magisk overlays the one file.

Remove: `adb shell su -c "touch /data/adb/modules/hy310_fonts/disable"` and reboot.

## Tested

Black and white logo version, Android 11: after the module and a reboot the voice query shows its
result without a crash (before: crash every time). The text uses Roboto instead of Google Sans.
