#!/bin/sh
# Replaces the device's default UI font (the "sans-serif" family in /system/etc/fonts.xml,
# which is also what "first font is default" aliases arial/helvetica/tahoma/verdana to) with
# GNU FreeSans Bold - every weight, not just Roboto's own Bold/Black. No fonts.xml edit needed:
# fonts.xml already names these exact Roboto-*.ttf files, so a Magisk systemless overlay of
# /system/fonts/ under the same filenames is enough - everything that already points at
# "Roboto-Regular.ttf" etc. just gets FreeSans Bold's glyphs instead, with zero risk of a
# malformed fonts.xml. RobotoCondensed and the per-script Noto/SourceSansPro fallback fonts
# are left untouched: FreeSans has no condensed cut, and touching the script fallbacks isn't
# "the device's font" the way sans-serif is. Needs root (Magisk).
#
# Every weight maps to the Bold/BoldOblique FreeSans faces, not just Roboto's own Bold/Black -
# every bit of UI text, not only headings, renders in bold FreeSans.
#
# Usage: ./install.sh [--build-only DIR]    then: adb reboot
# Set ANDROID_SERIAL to pick a device. Needs fonts-freefont-ttf (Debian/Ubuntu) for the source
# files, read from /usr/share/fonts/truetype/freefont/ by default - override with FREEFONT_DIR.
set -eu

MOD=hy310_freesans
FREEFONT_DIR=${FREEFONT_DIR:-/usr/share/fonts/truetype/freefont}

# target Roboto filename -> source FreeSans face (every normal-style weight also gets the
# Bold face, not just Roboto's own Bold/Black - the point is bold FreeSans everywhere)
MAP="
Roboto-Thin.ttf:FreeSansBold.ttf
Roboto-ThinItalic.ttf:FreeSansBoldOblique.ttf
Roboto-Light.ttf:FreeSansBold.ttf
Roboto-LightItalic.ttf:FreeSansBoldOblique.ttf
Roboto-Regular.ttf:FreeSansBold.ttf
Roboto-Italic.ttf:FreeSansBoldOblique.ttf
Roboto-Medium.ttf:FreeSansBold.ttf
Roboto-MediumItalic.ttf:FreeSansBoldOblique.ttf
Roboto-Bold.ttf:FreeSansBold.ttf
Roboto-BoldItalic.ttf:FreeSansBoldOblique.ttf
Roboto-Black.ttf:FreeSansBold.ttf
Roboto-BlackItalic.ttf:FreeSansBoldOblique.ttf
"

build_only=
if [ "${1:-}" = "--build-only" ]; then build_only=${2:?--build-only needs a directory}; fi

for f in FreeSans.ttf FreeSansBold.ttf FreeSansOblique.ttf FreeSansBoldOblique.ttf; do
	[ -f "$FREEFONT_DIR/$f" ] || { echo "missing $FREEFONT_DIR/$f (apt install fonts-freefont-ttf?)" >&2; exit 1; }
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
tree=${build_only:-$tmp/$MOD}
mkdir -p "$tree/system/fonts"

for pair in $MAP; do
	target=${pair%%:*}
	source=${pair##*:}
	cp "$FREEFONT_DIR/$source" "$tree/system/fonts/$target"
done

cat >"$tree/module.prop" <<PROP
id=$MOD
name=HY310 default font: FreeSans
version=v1
versionCode=1
author=hy310-deshittify
description=Replaces the system default sans-serif font (Roboto) with GNU FreeSans, systemless, by overlaying /system/fonts/Roboto-*.ttf. No fonts.xml edit.
PROP

if [ -n "$build_only" ]; then echo "Module tree written to $build_only"; exit 0; fi

adb shell rm -rf /data/local/tmp/${MOD:?}
adb push "$tree" /data/local/tmp/ >/dev/null
adb shell su -c "'
set -e
rm -rf /data/adb/modules/${MOD:?}
cp -r /data/local/tmp/$MOD /data/adb/modules/
chown -R root:root /data/adb/modules/$MOD
chmod -R u+rwX,go+rX /data/adb/modules/$MOD
chcon -R u:object_r:system_file:s0 /data/adb/modules/$MOD
rm -rf /data/local/tmp/${MOD:?}
'"
echo "Installed. Reboot to activate: adb reboot"
