#!/bin/sh
# Stops /system/bin/qw (a Superuser-derived su daemon the vendor ships running by default, unauthenticated,
# on a world-writable socket: see ../docs/qw-and-dbgserver.md) from starting at boot.
#
# Builds a Magisk module that overlays /system/etc/init/qw.rc with the same content plus "disabled" added to
# the service stanza, the same technique Android init itself uses elsewhere (a disabled service is still
# parsed, just never auto-started). Nothing else in init starts or references qw, so this is enough: the
# daemon never runs unless someone deliberately starts it as root (`start qw`), which already requires the
# root access this is meant to take away from everyone else. The binary itself is left in place; it is inert
# with the daemon not running. Needs root (Magisk).
#
# Usage: ./install.sh [--build-only DIR]    then: adb reboot
# Set ANDROID_SERIAL to pick a device.
set -eu

MOD=hy310_qw_disable
RC_PATH=/system/etc/init/qw.rc
SERVICE_LINE="service qw /system/bin/qw --daemon"

build_only=
if [ "${1:-}" = "--build-only" ]; then build_only=${2:?--build-only needs a directory}; fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
tree=${build_only:-$tmp/$MOD}
mkdir -p "$tree/system/etc/init"

adb pull "$RC_PATH" "$tmp/qw.rc" >/dev/null

if grep -q '^[[:space:]]*disabled[[:space:]]*$' "$tmp/qw.rc"; then
	echo "qw.rc already has 'disabled' (module active, or already neutered on the device), nothing to do"
	exit 0
fi
grep -qxF "$SERVICE_LINE" "$tmp/qw.rc" || {
	echo "qw.rc does not contain the expected line '$SERVICE_LINE': this firmware's file differs from what" >&2
	echo "this script was written for. Not guessing; refusing to edit it blind." >&2
	exit 1
}

# insert "disabled" right after the service line, leaving everything else in the file untouched
awk -v svc="$SERVICE_LINE" '
	{ print }
	$0 == svc { print "    disabled" }
' "$tmp/qw.rc" >"$tree/system/etc/init/qw.rc"

grep -q '^[[:space:]]*disabled[[:space:]]*$' "$tree/system/etc/init/qw.rc" || {
	echo "insertion did not take effect, refusing to install a no-op module" >&2
	exit 1
}

cat >"$tree/module.prop" <<PROP
id=$MOD
name=HY310 qw daemon disable
version=v1
versionCode=1
author=hy310-deshittify
description=Stops the vendor qw (Superuser-derived) root daemon from starting at boot; see docs/qw-and-dbgserver.md
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
echo "After reboot, verify: adb shell getprop init.svc.qw   (should NOT say 'running')"
