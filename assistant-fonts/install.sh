#!/bin/sh
# With Google Play services disabled the Google app (Assistant, voice search) crashes right after it
# recognizes speech: its UI asks the Play services font provider for Google Sans and fails with
# "Font resource ID ... could not be retrieved". The font descriptors prefer a system font family of
# the same name, so this Magisk module adds those family names to /system/etc/fonts.xml, backed by
# the Roboto files every Android has. Google's own font is not shipped. Needs root (Magisk).
#
# Usage: ./install.sh [--build-only DIR]    then: adb reboot
# Set ANDROID_SERIAL to pick a device.
set -eu

MOD=hy310_fonts
FAMILIES="google-sans google-sans-medium google-sans-text google-sans-text-medium google-sans-display google-sans-display-regular google-sans-display-medium"

build_only=
if [ "${1:-}" = "--build-only" ]; then build_only=${2:?--build-only needs a directory}; fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
tree=${build_only:-$tmp/$MOD}
mkdir -p "$tree/system/etc"

# read the stock file: with the module already active the mounted file is already patched, which is detected below
adb pull /system/etc/fonts.xml "$tmp/fonts.xml" >/dev/null
if grep -q 'family name="google-sans"' "$tmp/fonts.xml"; then
	echo "fonts.xml already defines google-sans (module active or stock font present), nothing to do"
	exit 0
fi
marker='<!-- Note that aliases must come after the fonts they reference. -->'
grep -q "$marker" "$tmp/fonts.xml" || { echo "unexpected fonts.xml layout: marker comment not found" >&2; exit 1; }

{
	sed -n "1,/$marker/{/$marker/!p}" "$tmp/fonts.xml"
	echo "    <!-- $MOD: stand-ins for the Google Sans families the Google app wants from Play services -->"
	for n in $FAMILIES; do
		cat <<FAM
    <family name="$n">
        <font weight="400" style="normal">Roboto-Regular.ttf</font>
        <font weight="400" style="italic">Roboto-Italic.ttf</font>
        <font weight="500" style="normal">Roboto-Medium.ttf</font>
        <font weight="500" style="italic">Roboto-MediumItalic.ttf</font>
        <font weight="700" style="normal">Roboto-Bold.ttf</font>
        <font weight="700" style="italic">Roboto-BoldItalic.ttf</font>
    </family>
FAM
	done
	echo
	sed -n "/$marker/,\$p" "$tmp/fonts.xml"
} >"$tree/system/etc/fonts.xml"

cat >"$tree/module.prop" <<PROP
id=$MOD
name=HY310 font stand-ins
version=v1
versionCode=1
author=hy310-deshittify
description=Defines the google-sans font families with Roboto so the Google app does not crash on a missing font when Play services are disabled.
PROP

if [ -n "$build_only" ]; then echo "Module tree written to $build_only"; exit 0; fi

adb shell rm -rf /data/local/tmp/$MOD
adb push "$tree" /data/local/tmp/ >/dev/null
adb shell su -c "'
set -e
rm -rf /data/adb/modules/$MOD
cp -r /data/local/tmp/$MOD /data/adb/modules/
chown -R root:root /data/adb/modules/$MOD
chmod -R u+rwX,go+rX /data/adb/modules/$MOD
chcon -R u:object_r:system_file:s0 /data/adb/modules/$MOD
rm -rf /data/local/tmp/$MOD
'"
echo "Installed. Reboot to activate: adb reboot"
