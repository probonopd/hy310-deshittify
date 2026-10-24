#!/bin/sh
# Undo disable.sh: re-enable every package in packages.txt.
# Usage: ./enable.sh [packages.txt]
set -eu

list=${1:-$(dirname "$0")/packages.txt}

sed 's/#.*//' "$list" | awk 'NF { print $1 }' | while read -r pkg; do
	adb shell pm enable "$pkg" </dev/null || echo "$pkg: not installed"
done

sleep 20
