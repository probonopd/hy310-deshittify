#!/bin/sh
# Disable every package in packages.txt on the connected device.
# Usage: ./disable.sh [packages.txt]    (set ANDROID_SERIAL to pick a device)
set -eu

list=${1:-$(dirname "$0")/packages.txt}

sed 's/#.*//' "$list" | awk 'NF { print $1 }' | while read -r pkg; do
	# </dev/null: adb would otherwise eat the rest of the list from stdin
	adb shell pm disable-user --user 0 "$pkg" </dev/null || echo "$pkg: not installed"
done

# PackageManager saves the state about 10 s later; a reboot before that undoes it.
echo "Waiting 20 s for the change to be saved..."
sleep 20

echo "Disabled packages:"
adb shell pm list packages -d
