# Privacy hardening for Android 11

`harden.sh` turns off location, the advertising ID, Google Play services and other tracking surfaces on an Android 11 device, over adb from the host. Developed against an Android 11 TV projector (rooted with Magisk), but everything except the advertising-ID reset works without root.

```
sh privacy/harden.sh status                 # read-only report
sh privacy/harden.sh apply                  # dry run: prints every command
sh privacy/harden.sh apply --yes --root     # really do it, including the ad-ID reset
sh privacy/harden.sh undo --yes --root      # restore exactly the recorded values
```

(The disk this repo lives on may be mounted noexec; run with `sh`.)

## Behavior

- Device: honors `ANDROID_SERIAL`; refuses to run with zero or several attached devices.
- `apply` and `undo` are dry runs unless `--yes` is given. Reads (settings get, pm list, dumpsys) always run, so the dry run shows the real commands for the packages that are really installed.
- Before each change the previous value is written to a state file (default `./privacy-state-<serial>.txt`). Only the first value is kept, so re-running `apply` is idempotent and never records a hardened value as the original. `undo` replays the file newest first, then renames it to `*.undone`.
- No silent fallbacks: a failing command is printed with its error, the run continues, and the script ends with a summary and exit code 1 if anything failed. A skipped item (for example the ad-ID reset without `--root`) is reported as skipped, not as success.
- A protected list makes the script refuse to touch the fan/overtemperature protection, the autofocus app, Magisk, the Settings app, the Bluetooth remote service, the packages of this repo (`io.github.probonopd.*`), and the adb settings (`adb_enabled`, `adb_wifi_enabled`, `development_settings_enabled`). Network adb keeps working.

## Options

| Option | Effect |
|---|---|
| `--yes` / `--dry-run` | really change / only print (dry-run wins) |
| `--root` | use `su -c` for the advertising-ID reset |
| `--no-gms` | keep Play services and the Services Framework |
| `--keep-google-assistant` | keep the Google app/Assistant (`com.google.android.katniss`) and what it needs (Play services, Services Framework) |
| `--strict` | also deny the clipboard-read and screen-overlay appops for all non-system apps |
| `--captive-portal alt\|off\|keep` | alt (default): non-Google probe URLs; off: no probing; keep: untouched |
| `--ntp-server HOST` | set the NTP server (default: untouched) |
| `--private-dns HOST` | private DNS hostname mode (default: untouched) |
| `--state FILE` | state file location |
| `HARDEN_KEEP=a.b,c.d` | packages that keep microphone and camera |
| `HARDEN_DISABLE_EXTRA=...` | additional packages to disable |
| `HARDEN_RESTRICT_BG=...` | packages whose background activity is denied (appops RUN_IN_BACKGROUND and RUN_ANY_IN_BACKGROUND) |

## What is changed

"Verified" means: checked read-only on an Android 11 device that the key or command exists (settings get, `cmd ... help`, `pm help`, string present in the framework or services dex, file present). It does NOT mean the change was applied; the script was only ever dry-run against a device. "Behavior" entries marked "source" rest on the AOSP source, not on a device test.

### Location

| Setting | Command | Protects | Can break | Verified |
|---|---|---|---|---|
| Location master switch | `cmd location set-location-enabled false` | all location to apps and the system | maps, weather and WLAN/Bluetooth scanning apps, "find my" style features | yes (command listed in `cmd location help`; `location_mode` readable) |
| `location_mode` | read only, to record and verify the master switch | n/a | n/a | yes (secure, key exists) |
| `location_providers_allowed` | `settings put secure location_providers_allowed -gps` per provider found | redundant with master switch on Android 11 | nothing beyond the master switch | yes (key exists; empty on the test device, so nothing to change there) |
| WLAN scanning always available | `settings put global wifi_scan_always_enabled 0` | location by scanning WLAN while WLAN is off. NOTE: global namespace, not secure | WLAN-based location | yes (global key, was 0) |
| Bluetooth scanning always available | `settings put global ble_scan_always_enabled 0` | location by Bluetooth scans. Global namespace | BLE beacons, some remotes pairing while Bluetooth is off | yes (key in framework, unset on the device) |
| Assisted GPS | `settings put global assisted_gps_enabled 0` | SUPL/aiding requests to network servers | slower GNSS fix (irrelevant without GNSS) | yes (was 1) |
| WLAN wakeup | `settings put global wifi_wakeup_enabled 0` | uses location history to toggle WLAN | WLAN no longer turns on near saved networks | yes (was 1) |
| Open-network notification | `settings put global wifi_networks_available_notification_on 0` | network scanning for open networks | no "open network nearby" prompt | yes (was 1) |
| Network recommendations | `settings put global network_recommendations_enabled 0` | network scorer sending scan data | automatic WLAN picking by a scorer | yes (was already 0) |
| Location permissions | `pm revoke --user 0 PKG android.permission.ACCESS_{BACKGROUND,FINE,COARSE}_LOCATION` for every non-system app that holds them | per-app location | apps asking again or failing to find nearby devices | yes (`pm revoke` exists; `dumpsys package` shows granted state) |
| Location appops | `cmd appops set PKG {COARSE_LOCATION,FINE_LOCATION,MONITOR_LOCATION,MONITOR_HIGH_POWER_LOCATION} ignore` | second layer if an app is later re-granted; also hides passive monitoring | same as above | yes (all four op names accepted by `cmd appops get`) |

### Advertising ID

Android 11 has NO Settings key for the advertising ID: `limit_ad_tracking` does not exist in the framework (checked). The real opt-out and the ID live in the Play services preference `adid_settings.xml` (keys `enable_limit_ad_tracking`, `adid_reset_count`, and the ID itself), which only root can read or write.

| Setting | Command | Protects | Can break | Verified |
|---|---|---|---|---|
| Opt out and reset | with `--root`: back up the file to the host (owner-only, it contains the old ID), `am force-stop` Play services, overwrite the file in place with only `enable_limit_ad_tracking=true` and an incremented `adid_reset_count`, read it back | apps get a zeroed/limited ID; the old ID is gone, a new one is generated only when Play services runs again (and then opted out) | apps that require a non-zero ad ID (some ads SDKs) | file name and keys: yes, read as root. Whole write sequence: no (never applied). The ID key was already absent on the test device because Play services had been disabled for a long time, so the removal itself could not be observed |
| Without root | nothing works; the script says so and skips | n/a | n/a | yes |
| Disabling Play services | see below | the ID cannot be read by apps at all, so this alone makes it unusable | see below | yes (package state read) |

The file is overwritten in place instead of deleted: that keeps owner and SELinux label, so Play services can still read it. `pm clear` is deliberately not used: it would wipe accounts.

### Google packages

`pm disable-user --user 0 PKG`, only for packages that are installed. `undo` restores the recorded state of each (default, enabled, disabled or disabled-user), so a package that was already disabled stays disabled.

| Package | Role | Disabled by default | Verified |
|---|---|---|---|
| `com.google.android.gms` | Play services | yes (`--no-gms`, `--keep-google-assistant` skip it) | yes (present; was already disabled on the test device) |
| `com.google.android.gsf` | Services Framework | yes (same flags) | yes |
| `com.android.vending` | Play Store | yes | yes (was already disabled) |
| `com.google.android.katniss` | Google app / Assistant / voice search | yes (`--keep-google-assistant` skips it) | yes |
| `com.google.android.tv.remote.service` | Google TV phone remote service | yes, except with `--keep-google-assistant`: the remote's voice button reaches the Assistant through this service, and disabling it made the button stop working (any other installed `com.google.android.*` package except overlays and network-stack config is also disabled) | yes |

What breaks when Play services are disabled: Play Store installs and updates, Google sign-in and every Google account, push messages (FCM) so apps that rely on them get no notifications, Assistant voice search and voice input on the remote (katniss needs Play services and the Services Framework; it declares the gsf `READ_GSERVICES` permission), Chromecast/Cast receiving through Google services, location from Play services (already off), SafetyNet/Play Integrity, Play Protect scanning. System functions, the WLAN, HDMI, the apps of this repo and apps installed from F-Droid keep working. The `voice_interaction_service` and `voice_recognition_service` settings still point at katniss; that is harmless while it is disabled and is not changed.

### Privacy defaults

| Setting | Command | Protects | Can break | Verified |
|---|---|---|---|---|
| Assist structure | `settings put secure assist_structure_enabled 0` | stops sending screen content structure to the assistant app | contextual assistant features | yes (key in framework; unset = default on) |
| Assist screenshot | `settings put secure assist_screenshot_enabled 0` | stops sending screenshots to the assistant | same | yes |
| App error reporting | `settings put global send_action_app_error 0` | the "send feedback" report action on crashes | no crash reporting prompt | yes |
| Verify apps over adb | `settings put global verifier_verify_adb_installs 0` | stops sending the package of adb-installed apps to a verifier | only matters if a verifier (Play Protect) is present | yes (key in framework and services) |
| Captive portal, alt | `settings put global captive_portal_{http_url,https_url,fallback_url}` to a non-Google 204 endpoint | stops contacting Google at each network connect | network checks depend on that third party; if it is down the network shows as "no internet" | keys: yes (strings in the network stack APK; defaults there are Google URLs). Endpoint answered 204 from the host on the day of writing. Behavior: source |
| Captive portal, off | `settings put global captive_portal_mode 0` | no probing at all | no captive portal login prompt; network never shows validated state | key: yes. Behavior: source |
| NTP server | `settings put global ntp_server HOST` (only with `--ntp-server`) | time sync with a server you choose | wrong time if the server is unreachable | key: yes (framework) |
| Private DNS | `settings put global private_dns_mode hostname` plus `private_dns_specifier` (only with `--private-dns`) | DNS queries are encrypted and go to your resolver | no name resolution if the resolver is down or not DoT | keys: yes (was `off`) |
| Backup | `bmgr enable false` | no backup transport (Google backup via Play services) | no device backup | read: yes (`bmgr enabled`). Write: no |
| Clipboard (`--strict`) | `cmd appops set PKG READ_CLIPBOARD ignore` | non-system apps cannot read the clipboard | paste in those apps | op name: yes. Android 11 has no clipboard setting; background reads are already blocked |
| Screen overlay (`--strict`) | `cmd appops set PKG SYSTEM_ALERT_WINDOW ignore` | no overlays over other apps (tap-jacking) | apps drawing overlays | op name: yes |
| Microphone, camera | `pm revoke --user 0 PKG android.permission.{RECORD_AUDIO,CAMERA}` for every non-system app not in `HARDEN_KEEP` | recording without your knowledge | voice search or camera apps until re-granted | yes |
| Background activity | appops `RUN_IN_BACKGROUND` and `RUN_ANY_IN_BACKGROUND` `ignore` for `HARDEN_RESTRICT_BG` packages | background network/CPU of chosen packages | their sync and notifications | op names: yes. No default list: on the test device the known trackers are the Google packages above, which are disabled |

### Looked at, deliberately not changed

- Usage and diagnostics, `limit_ad_tracking`, `usage_reporting`, `package_verifier_enable`, `package_verifier_user_consent`, `adaptive_connectivity_enabled`: no such AOSP key on Android 11 (the first four are absent from the framework; the consent key exists on the device but is owned by Play services). Usage and diagnostics and Play Protect upload are Play services preferences; disabling Play services is the only switch.
- Install referrer: delivered by the Play Store; no setting; gone with `com.android.vending`.
- WLAN MAC randomization: `wifi_connected_mac_randomization_enabled` is a legacy key. On the test device `dumpsys wifi` already shows `macRandomizationSetting: 1` (persistent randomized MAC per network), so `status` reports it and `apply` leaves it. Per-connection randomization needs the WLAN settings UI.
- Notification listeners and accessibility services: `status` prints them so you can audit them; changing them is not safe to automate.
- Nothing touches `/sys`, the network configuration, or adb.

## Limits

- Dry run only against the device so far; the first real run should be on a spare unit or with `status` before and after.
- The ad-ID reset assumes Play services keeps the ID in `adid_settings.xml`; the file name and the opt-out key were read on the device, the ID key was absent there.
- Other Android versions: the script warns when the release is not 11.

## Assistant crash without Play services

With Play services disabled the Google app crashes after it has recognized speech (missing Google Sans font from the Play services font provider). The [assistant-fonts](../assistant-fonts/) Magisk module fixes that without re-enabling Play services.

## Audit

`audit.sh` checks a device for exposure and for known indicators of pre-installed malware. It is strictly read-only: it only runs `adb shell` reads (`getprop`, `pm list`, `ss`, `ls`, `stat`, `find`, `grep`) and keeps temporary files on the host. It never reads block devices, never searches `/`, and never touches `/sys`.

```
sh privacy/audit.sh                  # uses su -c where available
sh privacy/audit.sh --no-root        # shell user only (checks 2 and 3 are skipped)
sh privacy/audit.sh --ioc my.txt     # another indicator file
```

Honors `ANDROID_SERIAL`, refuses zero or several devices, prints `PASS` / `WARN` / `INFO` per check and exits 1 if any `WARN` was printed. Every adb call has a 20 second timeout.

| # | Check | WARN when |
|---|---|---|
| 1 | `ro.adb.secure`, `ro.debuggable`, `service.adb.tcp.port`, `persist.adb.tcp.port` | adb does not require keys, or the build is debuggable. Network adb on is only INFO: it is convenient, but unauthenticated adb on a network is a risk |
| 2 | `ss -tulnp` as root | a TCP listener on all interfaces that is not adbd (UDP ones, and mdnsd, are INFO) |
| 3 | `ss -tnp` as root | a remote address equals an IP in `[ips]`; other remotes are listed as INFO with the process name |
| 4 | `[packages]` against `pm list packages -u` / `-d` | an IOC package is installed and enabled (disabled or removed-for-user is INFO, absent is PASS) |
| 5 | `[paths]`, SUID/SGID files in `/system/bin /system/xbin /vendor/bin /product/bin` | an IOC path exists, or any SUID/SGID file is there (stock builds have none) |
| 6 | `stat /oem`, `ls -l /dev/block/mmcblk0` | `/oem` is world-writable, or the eMMC node is readable or writable by everyone |
| 7 | `/*/preinstall` directories, `/system/bin/preinstall`, `persist.sys.install_start`, init `.rc` files | a preinstall directory is non-empty, the script exists, or an init script mentions `appsdisable` / `preinstall` (these are the paths that bring removed apps back) |
| 8 | `[domains]` against all `getprop` values | an IOC domain appears in a property |
| 9 | Play services state, `location_mode` | never (INFO only; `harden.sh status` has the full privacy picture) |

### How to read the result

A WARN is a lead, not a verdict. Some findings are structural on cheap vendor firmware (a world-writable `/oem`, a preinstall script that is part of the factory image) and are worth knowing about even when nothing malicious runs. A SUID root helper in `/system/bin` that is not part of AOSP deserves a closer look (`strings`, comparison with another unit of the same model). A clean run proves little: it only covers the listed indicators and the checks above.

### ioc.txt

Sections `[packages]`, `[paths]`, `[domains]`, `[ips]`, one entry per line with a trailing comment. The entries come from public community write-ups (github.com/Kavan00/Android-Projector-C2-Malware, github.com/zane-programs/reversing-with-claude-code, github.com/jrm360seclab/aodin-vo1d-malware, github.com/micha102/hy300pro-debloat). Those write-ups are community reports, partly AI-assisted, and unverified by us; the packages among them that this repo removes or disables also came from our own analysis of the firmware. Treat every entry as unconfirmed.

### Not checked

Network traffic content, DNS queries (domains are only matched against properties, not resolved connections), file integrity of system partitions, kernel and bootloader state, and anything under `/sys`.
