#!/bin/sh
# Stops /system/bin/qw (a Superuser-derived su daemon the vendor ships running by default, unauthenticated,
# on a world-writable socket: see ../docs/qw-and-dbgserver.md) from starting at boot.
#
# This is a class "core" service, and Android's first-stage init parses /system/etc/init/*.rc and starts
# class-core services before Magisk's overlay for /system is mounted, so overlaying qw.rc with "disabled" on
# its own does NOT stop it (verified live: the file reads as disabled, the process is running anyway). The
# module overlays qw.rc for documentation/consistency, but the actual enforcement is a post-fs-data.sh script
# that stops the service once Magisk modules are active, with a fallback kill if the property-based stop does
# not take. The binary itself is left in place; it is inert once the daemon is not running. Needs root (Magisk).
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

# the rc overlay may already say "disabled" from a previous (v1, file-overlay-only) install of this module;
# that is fine, it is still correct content, just not sufficient on its own (see the note above the file).
# Only the service line is required to recognize the file; the "disabled" line is optional going in.
grep -qxF "$SERVICE_LINE" "$tmp/qw.rc" || {
	echo "qw.rc does not contain the expected line '$SERVICE_LINE': this firmware's file differs from what" >&2
	echo "this script was written for. Not guessing; refusing to edit it blind." >&2
	exit 1
}

if grep -q '^[[:space:]]*disabled[[:space:]]*$' "$tmp/qw.rc"; then
	cp "$tmp/qw.rc" "$tree/system/etc/init/qw.rc"
else
	# insert "disabled" right after the service line, leaving everything else in the file untouched
	awk -v svc="$SERVICE_LINE" '
		{ print }
		$0 == svc { print "    disabled" }
	' "$tmp/qw.rc" >"$tree/system/etc/init/qw.rc"
fi

grep -q '^[[:space:]]*disabled[[:space:]]*$' "$tree/system/etc/init/qw.rc" || {
	echo "insertion did not take effect, refusing to install a no-op module" >&2
	exit 1
}

cat >"$tree/module.prop" <<PROP
id=$MOD
name=HY310 qw daemon disable
version=v3
versionCode=3
author=hy310-deshittify
description=Stops the vendor qw (Superuser-derived) root daemon from starting at boot; see docs/qw-and-dbgserver.md
PROP

# The enforcement is service.sh, which Magisk runs at "late_start service": verified on the device that
# qw (a class "core" service) is not yet running when post-fs-data.sh executes, so a post-fs-data stop finds
# nothing to stop. service.sh runs after core/main services have started, so it can actually catch it. Also
# install the same logic as post-fs-data.sh, harmless and catches the case where boot order differs.
STOP_QW='
# Stop qw if it is running; retry briefly in case it is still starting, then fall back to a direct kill if
# the property-based stop does not take.
for i in 1 2 3 4 5 6 7 8 9 10; do
	pid=$(pidof qw 2>/dev/null) || pid=
	[ -z "$pid" ] && break
	setprop ctl.stop qw
	sleep 0.5
done
pid=$(pidof qw 2>/dev/null) || pid=
if [ -n "$pid" ]; then
	kill -9 $pid 2>/dev/null
fi
'
printf '#!/system/bin/sh\n%s' "$STOP_QW" >"$tree/post-fs-data.sh"
printf '#!/system/bin/sh\n%s' "$STOP_QW" >"$tree/service.sh"
chmod 0755 "$tree/post-fs-data.sh" "$tree/service.sh"

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
chmod 0755 /data/adb/modules/$MOD/post-fs-data.sh /data/adb/modules/$MOD/service.sh
chcon -R u:object_r:system_file:s0 /data/adb/modules/$MOD
rm -rf /data/local/tmp/$MOD
'"
echo "Installed. Reboot to activate: adb reboot"
echo 'After reboot, verify: adb shell su -c "pidof qw"   (should print nothing)'
