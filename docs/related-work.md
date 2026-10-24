# Related work

Other public projects about the Allwinner H713 projectors (MAGCUBIC HY300, HY300 Pro, HY310 and rebadges).
Nearly all of them are partly or fully written with AI assistance, and most are the work of one person. Treat
numbers and claims as plausible until you have reproduced them on your own unit. Checked in October 2026.

## Hardware and Linux

| Project | What it is |
|---|---|
| [well0nez/allwinner-h713-linux](https://github.com/well0nez/allwinner-h713-linux) | Mainline Linux (6.18) and an open boot chain for the H713, with extensive hardware notes (HDMI input, audio, video decode, GPU, AIC8800 WLAN and Bluetooth, remote, keystone, autofocus). Reported as verified on the HY310. Its README says the code is AI-generated and not yet human-reviewed; known issues listed there include no standby, lamp flicker and no AV1. Its FEL tools are what our [fel-backup](../fel-backup/) uses. |
| [cstenger/allwinner-h713-mainline](https://github.com/cstenger/allwinner-h713-mainline) | Independent mainline bring-up on bench boards; useful warnings about DRAM parameters. |
| [YuujiLab/HY300-H713-Research](https://github.com/YuujiLab/HY300-H713-Research) | Android-side research: partition table, UART and FEL triggers, `/oem` customization, OTA protocol, fastboot notes. |
| [shift/sun50iw12p1-research](https://github.com/shift/sun50iw12p1-research) | Early mainline attempt, heavily AI-generated and hardware-untested; superseded by the projects above. |
| sunxi-tools | Upstream has no merged H713 support. The patched `sunxi-fel` in the well0nez releases is what works; open upstream changes: [linux-sunxi/sunxi-tools#229](https://github.com/linux-sunxi/sunxi-tools/pull/229) and [probonopd/sunxi-tools#1](https://github.com/probonopd/sunxi-tools/pull/1). |

There is no Armbian or LineageOS image for the H713 (see the
[Armbian forum thread](https://forum.armbian.com/topic/42114-magcubic-hy300-android-11-projector-allwinner-h713-1gb8gb)).

## Root, firmware and tools

| Project | What it is |
|---|---|
| [well0nez/magcubic-root](https://github.com/well0nez/magcubic-root) | Root and debloat for the HY310 and L018 builds, with `awimg.py`, an unpacker and repacker for the IMAGEWTY update container. It reports that PhoenixSuit 1.19 fails and PhoenixUSBPro works, which differs from our fastboot way of flashing a patched `boot_a`. |
| [gniax/magcubic-hy300-root](https://github.com/gniax/magcubic-hy300-root) | Magisk modules for HDMI plug detection and an IR key override. |
| [KURTEcl/hy300plus-setup](https://github.com/KURTEcl/hy300plus-setup) | Projectivy and HDMI at boot. |
| [adrbn/nt30-airplay-guide](https://github.com/adrbn/nt30-airplay-guide) | An AirPlay receiver replacement for the vendor one. |
| [probonopd gist on the HY300](https://gist.github.com/probonopd/3ad6b7777caea1503f00d5fe7710ad06) | Notes on the vendor launcher, keystone, HDMI input and flashing. |
| androidpctv.com ["cleaned" firmware](https://androidpctv.com/firmware-magcubic-hy300-hy320/) | Third-party images with Google Drive downloads. Not audited, treat as untrusted binaries. |

## Security write-ups

| Project | What it covers |
|---|---|
| [Kavan00/Android-Projector-C2-Malware](https://github.com/Kavan00/Android-Projector-C2-Malware) | A staged chain (store app, SilentSDK, plugin manager, plugins: residential proxy, ad fraud) with command-and-control domains, on a rebadged H713 device. |
| [zane-programs/reversing-with-claude-code](https://github.com/zane-programs/reversing-with-claude-code) | Package and domain analysis on another H713 projector. |
| [jrm360seclab/aodin-vo1d-malware](https://github.com/jrm360seclab/aodin-vo1d-malware) | A disclosure for a related AODIN model (promotional tone; the indicators are useful, the claims need care). |
| [micha102/hy300pro-debloat](https://github.com/micha102/hy300pro-debloat) | The first public write-up of the proxy components (README says AI-generated). |
| [florentineprinzessinzusachsen/badbox-h713-projector](https://github.com/florentineprinzessinzusachsen/badbox-h713-projector) | Another H713 firmware family (not Magcubic) with a different malware set. |

The malware differs per firmware build, and some units are clean. The indicators we use are in
[../privacy/ioc.txt](../privacy/ioc.txt); the audit script in [../privacy](../privacy/) checks a unit against them
without changing anything.

## Not relevant to the H713

HY320 and some "HY300 Pro" variants use a different chip (H726), and several projects named HY300 are Rockchip
clones. Do not assume firmware or notes carry over.
