#!/bin/sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
python3 -I "$here/embed-scripts.py"
exec sh "$here/../tools/build-apk.sh" "$here" "$here/hy310-projection.apk"
