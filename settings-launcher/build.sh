#!/bin/sh
# Build and sign hy310-settings.apk. Needs apktool with a framework installed (once:
# adb pull /system/framework/framework-res.apk && apktool if framework-res.apk) and python3 with
# "cryptography". Usage: sh build.sh
set -eu
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
cp -r "$here/src" "$work/proj"
cat >"$work/proj/apktool.yml" <<YML
version: 2.9.3
usesFramework:
  ids:
  - 1
apkFileName: unsigned.apk
sdkInfo:
  minSdkVersion: '21'
  targetSdkVersion: '28'
packageInfo:
  renameManifestPackage: null
versionInfo:
  versionCode: '1'
  versionName: '1.0'
YML
apktool b "$work/proj" -o "$work/unsigned.apk" >/dev/null
mkdir -p "$here/build"
python3 -I "$here/sign.py" "$work/unsigned.apk" "$here/hy310-settings.apk" "$here/build/signing-key.pem"
echo "$here/hy310-settings.apk"
