#!/bin/sh
# Turn on the USB audio HAL the vendor shipped disabled, as a Magisk module.
# Needs a rooted device (Magisk). Builds the module from the device's own files.
# Usage: ./install.sh    then: adb reboot
set -eu

MOD=/data/adb/modules/usb_audio_autoswitch
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

adb exec-out cat /vendor/etc/audio_policy_configuration.xml >"$tmp/apc.xml"
adb exec-out cat /vendor/etc/usb_audio_policy_configuration.xml >"$tmp/usb.xml"

# 1. The include of the USB module is commented out; uncomment it.
sed -e 's#<!-- Usb Audio HAL$#<!-- Usb Audio HAL -->#' \
    -e 's#\(<xi:include href="usb_audio_policy_configuration.xml"/>\)-->#\1#' \
    "$tmp/apc.xml" >"$tmp/apc.new"
grep -q '^[[:space:]]*<xi:include href="usb_audio_policy_configuration.xml"/>$' "$tmp/apc.new" ||
	{ echo "audio_policy_configuration.xml: include not found, unknown firmware" >&2; exit 1; }

# 2. Give the USB output ports a fixed stereo profile. Without one, a 5.1 device gets an
#    "indexed" channel mask that nothing can play into: the device is selected, but silent.
P='<profile name="" format="AUDIO_FORMAT_PCM_16_BIT" samplingRates="44100,48000" channelMasks="AUDIO_CHANNEL_OUT_STEREO"/>'
sed -e "s#<mixPort name=\"usb_device output\" role=\"source\"/>#<mixPort name=\"usb_device output\" role=\"source\">$P</mixPort>#" \
    -e "s#<devicePort tagName=\"USB Device Out\" type=\"AUDIO_DEVICE_OUT_USB_DEVICE\" role=\"sink\"/>#<devicePort tagName=\"USB Device Out\" type=\"AUDIO_DEVICE_OUT_USB_DEVICE\" role=\"sink\">$P</devicePort>#" \
    -e "s#<devicePort tagName=\"USB Headset Out\" type=\"AUDIO_DEVICE_OUT_USB_HEADSET\" role=\"sink\"/>#<devicePort tagName=\"USB Headset Out\" type=\"AUDIO_DEVICE_OUT_USB_HEADSET\" role=\"sink\">$P</devicePort>#" \
    "$tmp/usb.xml" >"$tmp/usb.new"
[ "$(grep -c 'samplingRates="44100,48000"' "$tmp/usb.new")" -eq 3 ] ||
	{ echo "usb_audio_policy_configuration.xml: ports not found, unknown firmware" >&2; exit 1; }

cat >"$tmp/module.prop" <<EOF
id=usb_audio_autoswitch
name=USB Audio Autoswitch
version=v1
versionCode=1
author=hy310-deshittify
description=Enables the USB audio HAL the vendor left disabled
EOF

adb push "$tmp/apc.new" /data/local/tmp/apc.xml >/dev/null
adb push "$tmp/usb.new" /data/local/tmp/usb.xml >/dev/null
adb push "$tmp/module.prop" /data/local/tmp/module.prop >/dev/null

adb shell su -c "'
set -e
mkdir -p $MOD/system/vendor/etc
mv /data/local/tmp/apc.xml $MOD/system/vendor/etc/audio_policy_configuration.xml
mv /data/local/tmp/usb.xml $MOD/system/vendor/etc/usb_audio_policy_configuration.xml
mv /data/local/tmp/module.prop $MOD/module.prop
touch $MOD/auto_mount
chmod 644 $MOD/module.prop $MOD/system/vendor/etc/*.xml
chcon u:object_r:vendor_configs_file:s0 $MOD/system/vendor/etc/*.xml
'"

echo "Installed. Reboot to activate: adb reboot"
