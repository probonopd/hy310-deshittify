#!/bin/sh
# Build and sign an APK from <appdir>/src (manifest, smali, res). Needs apktool with a framework installed (once:
# adb pull /system/framework/framework-res.apk && apktool if framework-res.apk) and python3 with
# "cryptography". Usage: sh tools/build-apk.sh <appdir> <out.apk>
set -eu
here=$(cd "$(dirname "$0")" && pwd)
app=$(cd "${1:?usage: build-apk.sh <appdir> <out.apk>}" && pwd)
out=$(cd "$(dirname "${2:?}")" && pwd)/$(basename "$2")
root=$(dirname "$here")
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
cp -r "$app/src" "$work/proj"
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
mkdir -p "$root/build"
python3 -I "$here/sign.py" "$work/unsigned.apk" "$out" "$root/build/signing-key.pem"
echo "$out"
