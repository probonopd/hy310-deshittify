#!/bin/sh
# Copy the FEL-exposed eMMC to an image file. Read-only.
# Usage: ./backup.sh /dev/sdX out.img
set -eu

dev=$1
out=$2

# Refuse anything that does not look like this projector's eMMC.
sectors=$(sudo blockdev --getsz "$dev")
parts=$(lsblk -nr -o TYPE "$dev" | grep -c part)
case $sectors in
15269888) echo "eMMC with yellow-logo size" ;;
15335424) echo "eMMC with black-and-white-logo size" ;;
*) echo "$dev: $sectors sectors, unknown size" >&2 ;;
esac
[ "$parts" -eq 26 ] || { echo "$dev: $parts partitions, expected 26. Wrong disk?" >&2; exit 1; }

sudo dd if="$dev" of="$out" bs=4M conv=fsync status=progress
sha256sum "$out"
