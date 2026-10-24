---
name: android-privacy-hardening
description: Use when asked to harden the privacy of an Android 11 device (TV projector or box) over adb - disable location, reset or disable the advertising ID, disable Google Play services, Play Store and the Google Assistant, revoke location/microphone/camera permissions, set privacy defaults, or undo all of that. Covers privacy/harden.sh (status, apply, undo, dry-run, state file), what needs root, what breaks without Play services, and which settings do not exist on Android 11.
---

# Android privacy hardening

In this repo: `privacy/harden.sh` (run with `sh`, disk may be noexec) and `privacy/README.md` (table of every change: command, protects, breaks, verified).

## Run
- `sh privacy/harden.sh status` is read-only. `apply` and `undo` are dry runs until `--yes`; read the printed commands first.
- Needs exactly one adb device or `ANDROID_SERIAL`. Real run: `sh privacy/harden.sh apply --yes --root`.
- Options: `--no-gms`, `--keep-google-assistant`, `--strict`, `--captive-portal alt|off|keep`, `--ntp-server`, `--private-dns`, `--state`; env `HARDEN_KEEP` (packages that keep mic/camera), `HARDEN_DISABLE_EXTRA`, `HARDEN_RESTRICT_BG`.
- Each change records the old value in `privacy-state-<serial>.txt` (first value wins, so re-running is idempotent). `undo --yes` restores it newest first. Failures are printed, the run continues, exit code 1 with a summary. Do not hide failures.

## Facts to remember (Android 11, checked on a device)
- `wifi_scan_always_enabled` and `ble_scan_always_enabled` are GLOBAL, not secure. Location master switch: `cmd location set-location-enabled false`.
- There is no Settings key for the advertising ID. The opt-out and the ID are in Play services `shared_prefs/adid_settings.xml` (`enable_limit_ad_tracking`); only root can touch it. Never `pm clear` Play services: it wipes accounts. Disabling Play services alone makes the ID unusable.
- No usage-and-diagnostics, `limit_ad_tracking` or Play Protect upload key exists; those live in Play services. Verify a key exists (`settings get`, framework dex strings) before adding it; `settings get` printing `null` does not prove it is unknown.
- Disabling Play services, gsf, Play Store and katniss breaks: Play Store, Google sign-in, push, Assistant voice, Cast, SafetyNet. Undo re-enables to the recorded state.
- Packages already disabled stay disabled after undo; do not "fix" that.

## Safety
The script refuses protected packages and adb settings: fan/overtemperature protection (`com.htc.closedialog`), autofocus (`com.hysd.vafocus`), Magisk, Settings, the Bluetooth remote service, this repo's `io.github.probonopd.*` apps, `adb_enabled`, `adb_wifi_enabled`. Extend that list rather than bypassing it. Never read or write the projector nodes under `/sys/class` (a read hung the unit).

## Pitfalls
- `adb shell` inside a `while read` loop swallows the loop's input; the script redirects stdin from /dev/null.
- Test changes to the script with a fake `adb` (env `ADB=...`) before touching a device.

- Do not disable `com.google.android.tv.remote.service` on an Android TV device that uses the Assistant: it hosts the search/voice service the remote's voice button talks to. Disabling it silently kills the button (found by testing; `--keep-google-assistant` now keeps it).
- With Play services disabled the Google app (Assistant) crashes right after recognizing speech: `Font resource ID ... could not be retrieved` (Google Sans comes from the Play services font provider). Fix without GMS: the `assistant-fonts/` Magisk module adds `google-sans*` families (Roboto-backed) to `/system/etc/fonts.xml`; verified: no crash after a reboot. Find such crashes with `logcat -b crash`.
