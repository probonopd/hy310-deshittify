#!/bin/sh
# Read-only security audit for Android 11 (developed on a rooted TV projector).
# Runs on the host, drives one device with adb. POSIX sh, no bashisms.
#
#   sh audit.sh [--ioc FILE] [--no-root]
#
# Never changes the device: only adb shell reads (getprop, pm list, ss, ls,
# stat, find, grep). Temporary files live on the host only.
# Prints PASS / WARN / INFO per check; exits 1 if any WARN was printed.
# See README.md (section "Audit") and ioc.txt.

set -u

PROG=${0##*/}
ADB=${ADB:-adb}
HERE=$(cd "$(dirname "$0")" && pwd)
IOC=$HERE/ioc.txt
ROOT=1

die() { printf '%s: %s\n' "$PROG" "$*" >&2; exit 2; }

while [ $# -gt 0 ]; do
    case $1 in
        --ioc) [ $# -ge 2 ] || die "--ioc needs a file"; IOC=$2; shift ;;
        --no-root) ROOT=0 ;;
        -h|--help) echo "Usage: sh $PROG [--ioc FILE] [--no-root]"; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
    shift
done
[ -r "$IOC" ] || die "cannot read IOC file"

command -v "$ADB" >/dev/null 2>&1 || die "adb not found"
DEVICES=$("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')
if [ -n "${ANDROID_SERIAL:-}" ]; then
    printf '%s\n' "$DEVICES" | grep -qxF -- "$ANDROID_SERIAL" || die "device $ANDROID_SERIAL is not attached in state 'device'"
    SERIAL=$ANDROID_SERIAL
else
    COUNT=$(printf '%s\n' "$DEVICES" | grep -c .)
    [ "$COUNT" -ge 1 ] || die "no adb device attached"
    [ "$COUNT" -le 1 ] || die "several adb devices attached; set ANDROID_SERIAL"
    SERIAL=$DEVICES
fi

TMPD=$(mktemp -d) || die "mktemp failed"
trap 'rm -rf "$TMPD"' EXIT HUP INT TERM
WARNS=0

# ------------------------------------------------------------------ helpers
pass() { printf 'PASS %s\n' "$*"; }
info() { printf 'INFO %s\n' "$*"; }
warn() { printf 'WARN %s\n' "$*"; WARNS=$((WARNS + 1)); }
head1() { printf '\n== %s\n' "$*"; }

# stdin from /dev/null: adb would otherwise swallow the input of read loops.
# The timeout keeps one stuck command from hanging the whole audit.
sh_() { timeout 20 "$ADB" -s "$SERIAL" shell "$1" </dev/null 2>/dev/null | tr -d '\r'; }
# Root reads; the command text must not contain single quotes (use double).
su_() { sh_ "su -c '$1'"; }

# Section entries of ioc.txt: first word of each non-comment line.
ioc() {
    awk -v s="[$1]" '
        /^\[/ { cur = $1; next }
        cur == s { sub(/#.*/, ""); if (NF) print $1 }' "$IOC"
}

HAVE_ROOT=0
if [ "$ROOT" = 1 ]; then
    su_ id | grep -q 'uid=0' && HAVE_ROOT=1
fi

printf 'Audit of device (read-only), IOC file: %s\n' "${IOC##*/}"
if [ "$HAVE_ROOT" = 1 ]; then info "root shell available (su -c works)"
else info "no root shell: checks 2, 3 and parts of 5-7 are limited"; fi
REL=$(sh_ 'getprop ro.build.version.release')
[ "$REL" = 11 ] || info "Android release is '$REL', the script was written for 11"

# Run a command as root if possible, else as the shell user.
rd() { if [ "$HAVE_ROOT" = 1 ]; then su_ "$1"; else sh_ "$1"; fi; }

# Mode, owner and size of one path.
fstat() { rd "stat -c \"%A %U:%G %s bytes\" $1"; }

# ----------------------------------------------------------- 1 adb exposure
head1 "1 adb exposure"
SECURE=$(sh_ 'getprop ro.adb.secure')
DEBUG=$(sh_ 'getprop ro.debuggable')
TCP1=$(sh_ 'getprop service.adb.tcp.port')
TCP2=$(sh_ 'getprop persist.adb.tcp.port')
if [ "$SECURE" = 1 ]; then pass "ro.adb.secure=1 (adb keys are required)"
else warn "ro.adb.secure='$SECURE': adb accepts any host without key authorization"; fi
if [ "$DEBUG" = 0 ]; then pass "ro.debuggable=0"
else warn "ro.debuggable='$DEBUG': adbd may run as root and apps are debuggable"; fi
TCPON=0
for p in "$TCP1" "$TCP2"; do
    if [ -n "$p" ] && [ "$p" != 0 ]; then TCPON=1; fi
done
if [ "$TCPON" = 1 ]; then
    info "network adb is on (service.adb.tcp.port='${TCP1:-}', persist.adb.tcp.port='${TCP2:-}'): convenient, but anyone on the network who is authorized (or everyone, if ro.adb.secure is 0) can get a shell"
else
    pass "network adb is off"
fi

# ----------------------------------------------------- 2 listening ports
head1 "2 listening TCP/UDP ports"
if [ "$HAVE_ROOT" = 1 ]; then
    su_ 'ss -tulnp' >"$TMPD/listen"
    # Wildcard binds are reachable from the network; loopback-only are not.
    awk 'NR>1 && ($5 ~ /^(0\.0\.0\.0|\*|\[::\]):/) {
            n = "?"; if (match($0, /\(\("[^"]*"/)) n = substr($0, RSTART + 3, RLENGTH - 4)
            print $1, $5, n }' "$TMPD/listen" >"$TMPD/wild"
    NW=0
    while read -r proto addr name; do
        NW=$((NW + 1))
        case $name in
            adbd) info "$proto $addr adbd (network adb)" ;;
            mdnsd) info "$proto $addr $name (service discovery)" ;;
            *) if [ "$proto" = tcp ]; then warn "$proto $addr listens on all interfaces: process '$name'"
               else info "$proto $addr listens on all interfaces: process '$name'"; fi ;;
        esac
    done <"$TMPD/wild"
    [ "$NW" -gt 0 ] || pass "no listener on all interfaces"
    LOOP=$(awk 'NR>1 && $5 ~ /^127\./' "$TMPD/listen" | wc -l | tr -d ' ')
    info "$LOOP loopback-only listeners (not reachable from the network)"
else
    info "skipped: needs root to see process names"
fi

# ------------------------------------------------- 3 outbound connections
head1 "3 established outbound connections"
if [ "$HAVE_ROOT" = 1 ]; then
    su_ 'ss -tnp' >"$TMPD/conn"
    # Strip the IPv4-mapped prefix and the port; keep process names.
    awk 'NR>1 && $1 == "ESTAB" {
            r = $5; sub(/:[0-9]+$/, "", r); sub(/^\[::ffff:/, "", r); sub(/\]$/, "", r); gsub(/[\[\]]/, "", r)
            n = "?"; if (match($0, /\(\("[^"]*"/)) n = substr($0, RSTART + 3, RLENGTH - 4)
            print r, n }' "$TMPD/conn" | sort -u >"$TMPD/remote"
    NC=0
    while read -r raddr name; do
        NC=$((NC + 1))
        if ioc ips | grep -qxF -- "$raddr"; then
            warn "connection to IOC address $raddr (process '$name')"
        else
            info "$raddr <- $name"
        fi
    done <"$TMPD/remote"
    [ "$NC" -gt 0 ] || info "no established connections"
else
    info "skipped: needs root to see process names"
fi

# ---------------------------------------------------------- 4 IOC packages
head1 "4 IOC packages"
sh_ 'pm list packages -u' | sed 's/^package://' | sort >"$TMPD/pk_all"
sh_ 'pm list packages -d' | sed 's/^package://' | sort >"$TMPD/pk_dis"
sh_ 'pm list packages' | sed 's/^package://' | sort >"$TMPD/pk_cur"
for pkg in $(ioc packages); do
    if grep -qxF -- "$pkg" "$TMPD/pk_cur"; then
        if grep -qxF -- "$pkg" "$TMPD/pk_dis"; then info "$pkg: installed, disabled"
        else warn "$pkg: installed and ENABLED"; fi
    elif grep -qxF -- "$pkg" "$TMPD/pk_all"; then
        info "$pkg: removed for user 0 (data kept, APK still on disk)"
    else
        pass "$pkg: absent"
    fi
done

# ------------------------------------------------ 5 hidden root helpers
head1 "5 hidden root helpers and SUID/SGID files"
for path in $(ioc paths); do
    if [ -n "$(rd "ls -d $path 2>/dev/null")" ]; then
        warn "$path exists: $(fstat "$path")"
    else
        pass "$path absent"
    fi
done
# Only system directories: searching / would also walk /proc and /sys.
SUID=$(rd 'find /system/bin /system/xbin /vendor/bin /product/bin -perm /6000 -type f 2>/dev/null')
if [ -z "$SUID" ]; then pass "no SUID/SGID file in /system/bin /system/xbin /vendor/bin /product/bin"
else
    printf '%s\n' "$SUID" | while read -r f; do
        [ -n "$f" ] || continue
        echo "WARN SUID/SGID file: $f ($(fstat "$f"))"
    done >"$TMPD/suid"
    cat "$TMPD/suid"
    WARNS=$((WARNS + $(grep -c . "$TMPD/suid")))
fi

# ----------------------------------------------- 6 /oem and the eMMC node
head1 "6 /oem and the eMMC block node"
OEM=$(rd 'stat -c "%A %U:%G" /oem 2>/dev/null')
if [ -z "$OEM" ]; then info "/oem not present"
else
    case $OEM in
        d???????w?*) warn "/oem is world-writable: $OEM" ;;
        *) pass "/oem not world-writable: $OEM" ;;
    esac
fi
MM=$(rd 'ls -l /dev/block/mmcblk0 2>/dev/null')
if [ -z "$MM" ]; then info "/dev/block/mmcblk0 not present"
else
    MODE=$(printf '%s' "$MM" | awk '{print substr($1, 2, 9)}')
    case $MODE in
        ??????r??|???????w?) warn "eMMC node readable or writable by every app (raw flash access): $MM" ;;
        *) pass "eMMC node: $MM" ;;
    esac
fi

# ------------------------------------------------------ 7 reinstall paths
head1 "7 reinstall paths"
# Only directories: /bin is a symlink to /system/bin, which holds the script.
for d in $(sh_ 'for d in /*/preinstall; do [ -d $d ] && echo $d; done'); do
    N=$(rd "ls $d 2>/dev/null" | grep -c .)
    if [ "$N" -gt 0 ]; then warn "$d is not empty ($N entries): packages may be reinstalled"
    else pass "$d is empty"; fi
done
if [ -n "$(rd 'ls /system/bin/preinstall 2>/dev/null')" ]; then
    warn "/system/bin/preinstall script present: $(fstat /system/bin/preinstall)"
else
    pass "/system/bin/preinstall absent"
fi
IS=$(sh_ 'getprop persist.sys.install_start')
if [ -n "$IS" ]; then info "persist.sys.install_start='$IS'"; else pass "persist.sys.install_start unset"; fi
RC=$(rd 'grep -l -i -E "appsdisable|preinstall" /system/etc/init/* /vendor/etc/init/* /product/etc/init/* 2>/dev/null')
if [ -z "$RC" ]; then pass "no init .rc mentions appsdisable or preinstall"
else printf '%s\n' "$RC" | while read -r f; do echo "WARN init script mentions appsdisable/preinstall: $f"; done >"$TMPD/rc"
    cat "$TMPD/rc"; WARNS=$((WARNS + $(grep -c . "$TMPD/rc")))
fi

# ------------------------------------------------------- 8 OTA / updaters
head1 "8 OTA and updater indicators"
sh_ 'getprop' >"$TMPD/props"
HIT=0
for dom in $(ioc domains); do
    if grep -qF -- "$dom" "$TMPD/props"; then
        HIT=1; warn "IOC domain $dom appears in system properties"
    fi
done
[ "$HIT" = 1 ] || pass "no IOC domain in getprop values"
for pkg in com.htc.htcotaupdate android.rockchip.update.service; do
    if grep -qxF -- "$pkg" "$TMPD/pk_cur" && ! grep -qxF -- "$pkg" "$TMPD/pk_dis"; then
        info "updater package $pkg is enabled (also reported in check 4)"
    fi
done

# ------------------------------------------------------ 9 Google / ad ID
head1 "9 Play services, advertising ID, location"
if grep -qxF com.google.android.gms "$TMPD/pk_cur"; then
    if grep -qxF com.google.android.gms "$TMPD/pk_dis"; then info "Play services: disabled"
    else info "Play services: enabled (see harden.sh to turn off)"; fi
else info "Play services: not installed for user 0"; fi
info "location_mode=$(sh_ 'settings get secure location_mode')"
info "limit_ad_tracking / adid: see 'sh harden.sh status'"

# ----------------------------------------------------------------- summary
printf '\n'
if [ "$WARNS" -gt 0 ]; then
    printf 'Result: %s WARN. Matches are leads, not proof; see README.md "Audit".\n' "$WARNS"
    exit 1
fi
printf 'Result: no WARN.\n'
exit 0
