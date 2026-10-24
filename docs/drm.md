# DRM (Widevine) on the projector

Measured on the black and white logo version (`Projector.20250214.153635`) by asking the Widevine engine through
`MediaDrm` (vendor, version, `securityLevel`, `maxHdcpLevel`, `hdcpLevel`):

| Property | Value |
|---|---|
| Widevine CDM | Google, version 16.0.1 |
| `securityLevel` | **L3** (software only) |
| `maxHdcpLevel` / `hdcpLevel` | Unprotected |

What it means: streaming apps that require Widevine L1 for HD or UHD (Netflix, Disney+ and others) will play
at most standard definition, or refuse to play. This is a property of the firmware, not something rooting or the
settings in this repository change. For premium streaming use an external stick on an HDMI input.

The firmware also ships a PlayReady plugin and a Widevine HIDL service, but no OEMCrypto library, which fits L3.

## Check it yourself

Any "DRM info" app shows the same values. Without an app you can only see that the engine exists:

```sh
adb shell ls /vendor/lib/mediadrm
```

(`libwvdrmengine.so`, `libplayreadydrmplugin.so`, `libdrmclearkeyplugin.so`).
