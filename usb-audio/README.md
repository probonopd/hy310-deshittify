# USB audio

Out of the box, USB headsets and DACs are detected but audio never switches to them: the
vendor commented out the USB audio HAL in `/vendor/etc/audio_policy_configuration.xml`.

This Magisk module fixes it without touching `/vendor`. Needs root.

```sh
./install.sh
adb reboot
```

Remove:

```sh
adb shell su -c "'rm -rf /data/adb/modules/usb_audio_autoswitch'"
adb reboot
```

Check it is active (the file is served from `/data`, not `/vendor`):

```sh
adb shell su -c "'mount | grep audio_policy'"
```

## Status

- Stereo USB devices work: plug in, audio switches over.
- The USB ports get a fixed stereo profile. Without it, 5.1 devices get an "indexed"
  channel mask (`0x8000003f` instead of `0x3f` in `logcat`) and stay silent.
- A Bose Companion 5 (`05a7:1020`) is still silent even in stereo. It is a full-speed
  device on the SoC's OHCI controller and plays with constant underruns
  (`dumpsys media.audio_flinger`). Not fixable in config. The kernel parameter
  `snd_usb_audio.quirk_alias=05a71020:047f02f7` was tried and made it worse.
