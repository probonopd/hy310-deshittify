#!/bin/sh
exec sh "$(dirname "$0")/../tools/build-apk.sh" "$(dirname "$0")" "$(dirname "$0")/hy310-settings.apk"
