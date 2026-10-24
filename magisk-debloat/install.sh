#!/bin/sh
# Remove the packages in ../debloat/packages.txt for real, without touching the system partitions:
# builds a Magisk module that hides each package's directory (an empty ".replace" marker), and
# removes /data updates of those packages. Needs a rooted device (Magisk).
#
# Usage: ./install.sh [--no-backup] [--build-only DIR]    then: adb reboot
#   --no-backup       do not pull the APKs to ./backup-<serial> first
#   --build-only DIR  only write the module tree to DIR; do not push, do not uninstall anything
# Set ANDROID_SERIAL to pick a device.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
MOD=hy310_debloat
backup=1
build_only=
while [ $# -gt 0 ]; do
	case $1 in
	--no-backup) backup=0 ;;
	--build-only) shift; build_only=${1:?--build-only needs a directory} ;;
	*) echo "unknown option: $1" >&2; exit 2 ;;
	esac
	shift
done

names() { sed 's/#.*//' "$1" | awk 'NF { print $1 }'; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
tree=${build_only:-$tmp/$MOD}
mkdir -p "$tree"

names "$here/../debloat/packages.txt" >"$tmp/pkgs"
[ -s "$tmp/pkgs" ] || { echo "no packages to remove" >&2; exit 1; }

# A /data copy is an update of a system app. Remove it first, otherwise "pm path" points at /data.
if [ -z "$build_only" ]; then
	while read -r pkg; do
		case $(adb shell pm path "$pkg" </dev/null | head -n 1) in
		package:/data/*) adb shell pm uninstall "$pkg" </dev/null ;;
		esac
	done <"$tmp/pkgs"
fi

: >"$tmp/dirs"
while read -r pkg; do
	apk=$(adb shell pm path "$pkg" </dev/null | head -n 1 | tr -d '\r')
	apk=${apk#package:}
	if [ -z "$apk" ]; then echo "$pkg: not installed, skipped"; continue; fi
	dir=$(dirname "$apk")
	case $dir in
	/product/app/*|/product/priv-app/*|/system/app/*|/system/priv-app/*|/system/system_ext/app/*|/system/system_ext/priv-app/*|/vendor/app/*|/vendor/priv-app/*) ;;
	*) echo "$pkg: $apk is not in a per-app directory of a known partition, refusing" >&2; exit 1 ;;
	esac
	echo "$pkg $dir" >>"$tmp/dirs"
done <"$tmp/pkgs"
[ -s "$tmp/dirs" ] || { echo "nothing to remove (already done?)" ; exit 0; }

if [ "$backup" = 1 ] && [ -z "$build_only" ]; then
	out="$here/backup-$(adb get-serialno)"
	mkdir -p "$out"
	while read -r pkg dir; do
		mkdir -p "$out/$pkg"
		adb pull -a "$dir" "$out/$pkg/" >/dev/null
	done <"$tmp/dirs"
	echo "APKs saved in $out"
fi

while read -r pkg dir; do
	# /system is the root of the system partition; the other partitions appear below /system/<partition> in a module.
	case $dir in
	/system/*) rel=${dir#/system/} ;;
	*) rel=${dir#/} ;;
	esac
	mkdir -p "$tree/system/$rel"
	: >"$tree/system/$rel/.replace"
done <"$tmp/dirs"

cat >"$tree/module.prop" <<PROP
id=$MOD
name=HY310 debloat
version=v1
versionCode=1
author=hy310-deshittify
description=Hides the OEM malware and bloat app directories (see debloat/packages.txt). Systemless; disable the module to bring them back.
PROP

if [ -n "$build_only" ]; then
	echo "Module tree written to $build_only"
	exit 0
fi

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
