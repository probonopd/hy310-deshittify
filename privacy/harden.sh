#!/bin/sh
# Privacy hardening for Android 11 (developed on a rooted TV projector).
# Runs on the host, drives one device with adb. POSIX sh, no bashisms.
#
#   sh harden.sh status
#   sh harden.sh apply [--yes] [options]     (dry-run unless --yes)
#   sh harden.sh undo  [--yes] [options]     (dry-run unless --yes)
#
# See README.md in this directory for the full table of changes.

set -u

PROG=${0##*/}
ADB=${ADB:-adb}

# Removing any of these breaks hardware protection, root, adb or this toolchain,
# so the script refuses instead of trusting its own lists to stay clean.
PROTECTED_PKGS="android com.android.shell com.android.systemui com.android.settings com.android.providers.settings com.android.bluetooth com.htc.closedialog com.hysd.vafocus com.topjohnwu.magisk com.htc.htcbluetoothremotecontrol"
PROTECTED_PREFIXES="io.github.probonopd."
# Keeping network adb alive is a hard requirement of the target device.
PROTECTED_SETTINGS="adb_enabled adb_wifi_enabled development_settings_enabled"

ADID_PKG=com.google.android.gms
ADID_FILE=/data/data/com.google.android.gms/shared_prefs/adid_settings.xml

LOC_PERMS="android.permission.ACCESS_BACKGROUND_LOCATION android.permission.ACCESS_FINE_LOCATION android.permission.ACCESS_COARSE_LOCATION"
MIC_CAM_PERMS="android.permission.RECORD_AUDIO android.permission.CAMERA"
LOC_OPS="COARSE_LOCATION FINE_LOCATION MONITOR_LOCATION MONITOR_HIGH_POWER_LOCATION"

# A shell command that exits 0 can still print a failure; treat these as errors.
FAIL_RE='exception|^error|failure|unknown command|no such|permission denied|not allowed'

usage() {
    cat <<EOF
Usage: sh $PROG status | apply | undo [options]

  --dry-run                 print every change command, change nothing (default
                            for apply and undo unless --yes is given)
  --yes                     really change the device
  --root                    use 'su -c' for the advertising-ID reset
  --no-gms                  keep Google Play services (and the Services Framework)
  --keep-google-assistant   keep the Google app/Assistant and what it needs
  --strict                  also deny clipboard read and screen overlay appops
                            for all non-system apps (breaks paste in those apps)
  --captive-portal MODE     alt (default): non-Google probe URLs; off: no probing;
                            keep: leave untouched
  --ntp-server HOST         set the NTP server (default: untouched)
  --private-dns HOST        set private DNS to hostname mode (default: untouched)
  --state FILE              state file (default ./privacy-state-<serial>.txt)

Environment:
  ANDROID_SERIAL            device to use (required if several are attached)
  HARDEN_KEEP               comma separated packages that keep microphone/camera
  HARDEN_DISABLE_EXTRA      comma separated extra packages to disable
  HARDEN_RESTRICT_BG        comma separated packages whose background activity
                            is denied (appops RUN_IN_BACKGROUND)
EOF
}

die() { printf '%s: %s\n' "$PROG" "$*" >&2; exit 2; }

# ---------------------------------------------------------------- arguments
CMD=${1:-}
[ -n "$CMD" ] || { usage; exit 2; }
shift
case $CMD in status|apply|undo) ;; -h|--help|help) usage; exit 0 ;; *) usage; exit 2 ;; esac

DRY_FLAG=0; YES=0; ROOT=0; NO_GMS=0; KEEP_ASSISTANT=0; STRICT=0
CAPTIVE=alt; NTP=; PDNS=; STATE=

while [ $# -gt 0 ]; do
    case $1 in
        --dry-run) DRY_FLAG=1 ;;
        --yes) YES=1 ;;
        --root) ROOT=1 ;;
        --no-gms) NO_GMS=1 ;;
        --keep-google-assistant) KEEP_ASSISTANT=1 ;;
        --strict) STRICT=1 ;;
        --captive-portal) [ $# -ge 2 ] || die "--captive-portal needs a value"; CAPTIVE=$2; shift ;;
        --ntp-server) [ $# -ge 2 ] || die "--ntp-server needs a value"; NTP=$2; shift ;;
        --private-dns) [ $# -ge 2 ] || die "--private-dns needs a value"; PDNS=$2; shift ;;
        --state) [ $# -ge 2 ] || die "--state needs a value"; STATE=$2; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
    shift
done

case $CAPTIVE in alt|off|keep) ;; *) die "--captive-portal must be alt, off or keep" ;; esac
valid_host() { printf '%s' "$1" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$'; }
[ -z "$NTP" ] || valid_host "$NTP" || die "invalid --ntp-server"
[ -z "$PDNS" ] || valid_host "$PDNS" || die "invalid --private-dns"

DRY=0
if [ "$DRY_FLAG" = 1 ] || [ "$YES" = 0 ]; then DRY=1; fi
[ "$CMD" = status ] && DRY=1

# Package lists coming from the environment end up inside remote commands.
csv_to_list() {
    printf '%s' "${1:-}" | tr ', ' '\n\n' | grep -v '^$' || true
}
check_pkg_list() {
    for _p in $1; do
        printf '%s' "$_p" | grep -Eq '^[A-Za-z0-9._]+$' || die "invalid package name in environment: $_p"
    done
}
KEEP_LIST=$(csv_to_list "${HARDEN_KEEP:-}");           check_pkg_list "$KEEP_LIST"
EXTRA_LIST=$(csv_to_list "${HARDEN_DISABLE_EXTRA:-}"); check_pkg_list "$EXTRA_LIST"
BG_LIST=$(csv_to_list "${HARDEN_RESTRICT_BG:-}");      check_pkg_list "$BG_LIST"

# ------------------------------------------------------------------- device
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

if [ -z "$STATE" ]; then
    STATE=./privacy-state-$(printf '%s' "$SERIAL" | tr -c 'A-Za-z0-9._\n-' '_').txt
fi
case $STATE in /*) ;; *) STATE=$PWD/${STATE#./} ;; esac
ADID_BAK=${STATE%.txt}-adid.xml

TMPD=$(mktemp -d) || die "mktemp failed"
trap 'rm -rf "$TMPD"' EXIT HUP INT TERM
FAILED=$TMPD/failed; : >"$FAILED"
CHANGED=0; ALREADY=0; SKIPPED=0

# ------------------------------------------------------------------ helpers
q() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }

# stdin from /dev/null: adb would otherwise swallow the input of callers' read loops.
rcmd() {
    "$ADB" -s "$SERIAL" shell "$1" </dev/null >"$TMPD/out" 2>&1
    RC=$?
    OUT=$(tr -d '\r' <"$TMPD/out")
}
rsu() { rcmd "su -c $(q "$1")"; }

fail() {
    _ft=$1
    printf '  FAIL %s\n' "$_ft"
    shift
    for _m in "$@"; do printf '       %s\n' "$_m"; done
    printf '%s\n' "$_ft" >>"$FAILED"
}
note_fail() { printf '%s\n' "$1" >>"$FAILED"; }
ok_already() { printf '  ok   %s (already as wanted)\n' "$1"; ALREADY=$((ALREADY+1)); }
skip() { printf '  skip %s\n' "$1"; SKIPPED=$((SKIPPED+1)); }
section() { printf '\n== %s\n' "$1"; }

# A read that fails must not be mistaken for an empty value.
rread() {
    rcmd "$1"
    if [ "$RC" -ne 0 ]; then
        printf '  FAIL read: %s\n       rc=%s: %s\n' "$1" "$RC" "$OUT"
        note_fail "read: $1"
        return 1
    fi
}

# Every mutation goes through here: dry-run prints, otherwise run and check.
change() {
    if [ "$DRY" = 1 ]; then printf '  DRY  %s\n       adb shell %s\n' "$1" "$2"; return 0; fi
    rcmd "$2"
    if [ "$RC" -ne 0 ] || printf '%s\n' "$OUT" | grep -Eqi "$FAIL_RE"; then
        printf '  FAIL %s\n       cmd: %s\n       rc=%s: %s\n' "$1" "$2" "$RC" "$OUT"
        note_fail "$1"
        return 1
    fi
    printf '  done %s\n' "$1"
    CHANGED=$((CHANGED+1))
}

# Records the value before the first change only: a re-run must never overwrite
# the original with an already hardened value.
record() {
    _key=$1; _val=$2
    if [ -f "$STATE" ] && awk -v k="$_key|" 'index($0,k)==1 {f=1} END {exit !f}' "$STATE"; then
        return 0
    fi
    if [ "$DRY" = 1 ]; then printf '       (would record %s|%s)\n' "$_key" "$_val"; return 0; fi
    printf '%s|%s\n' "$_key" "$_val" >>"$STATE" || { fail "cannot write state file"; return 1; }
}

is_protected() {
    for _pp in $PROTECTED_PKGS; do [ "$_pp" = "$1" ] && return 0; done
    for _pp in $PROTECTED_PREFIXES; do case $1 in "$_pp"*) return 0 ;; esac; done
    return 1
}
is_protected_setting() { for _s in $PROTECTED_SETTINGS; do [ "$_s" = "$1" ] && return 0; done; return 1; }
in_list() { for _x in $2; do [ "$_x" = "$1" ] && return 0; done; return 1; }
pkg_installed() { grep -qx "package:$1" "$TMPD/pkgs"; }

# VAL holds the setting, or the string "null" when the key is unset.
sget() { rread "settings get $1 $2" && VAL=$OUT || VAL=__readfail__; }

apply_setting() { # ns key value
    if is_protected_setting "$2"; then fail "refusing protected setting $2"; return; fi
    sget "$1" "$2"
    [ "$VAL" = __readfail__ ] && return
    if [ "$VAL" = "$3" ]; then ok_already "$1 $2=$3"; return; fi
    record "setting|$1|$2" "$VAL" || return
    change "settings put $1 $2 $3 (was $VAL)" "settings put $1 $2 $(q "$3")"
}

# ------------------------------------------------------------- appops, perms
# Mode names are what 'cmd appops get' prints; "default" when nothing is set.
appop_apply() { # pkg op mode
    is_protected "$1" && return
    rcmd "cmd appops get $1 $2"
    _uid=pkg
    case $OUT in *"Uid mode: $2:"*) _uid=uid ;; esac
    _line=$(printf '%s\n' "$OUT" | grep -m1 "$2:" || true)
    if [ -n "$_line" ]; then
        _prev=$(printf '%s' "$_line" | sed -E "s/.*$2: ([a-z_]+).*/\\1/")
    else
        _prev=default
    fi
    if [ "$_prev" = "$3" ]; then ok_already "appop $1 $2=$3"; return; fi
    record "appop|$1|$2" "$_prev|$_uid" || return
    if [ "$_uid" = uid ]; then _f='--uid '; else _f=; fi
    change "appops $1 $2 $3 (was $_prev)" "cmd appops set ${_f}$1 $2 $3"
}

perm_revoke() { # pkg perm
    record "perm|$1|$2" granted || return
    change "revoke $2 from $1" "pm revoke --user 0 $1 $2"
}

# Revokes only what is really granted, so re-runs are quiet and undo is exact.
revoke_granted() { # pkg "perm list"
    rcmd "dumpsys package $1"
    _granted=$(printf '%s\n' "$OUT" | sed -n 's/^ *\(android\.permission\.[A-Z_]*\): granted=true.*/\1/p' | sort -u)
    for _perm in $2; do
        if printf '%s\n' "$_granted" | grep -qx "$_perm"; then
            perm_revoke "$1" "$_perm"
        fi
    done
}

# --------------------------------------------------------------- packages
pkg_state() { # prints 0 default,1 enabled,2 disabled,3 disabled-user
    rcmd "dumpsys package $1"
    printf '%s\n' "$OUT" | sed -n 's/^ *User 0:.* enabled=\([0-9]\).*/\1/p' | head -1
}

disable_pkg() {
    _dp=$1
    if is_protected "$_dp"; then fail "refusing to disable protected package $_dp"; return; fi
    if ! pkg_installed "$_dp"; then skip "$_dp not installed"; return; fi
    _st=$(pkg_state "$_dp")
    case $_st in
        3|2) ok_already "$_dp disabled"; return ;;
        0|1) ;;
        *) fail "cannot read enabled state of $_dp"; return ;;
    esac
    record "pkg|$_dp" "$_st" || return
    change "disable $_dp (state was $_st)" "pm disable-user --user 0 $_dp"
}

google_extra_packages() {
    _skip='^com\.google\.android\.(gms|gsf|katniss)$|networkstackconfig|tetheringconfig|\.overlay$'
    # the remote's voice button reaches the Assistant through this service; disabling it silences the button
    [ "$KEEP_ASSISTANT" = 1 ] && _skip="$_skip|^com\\.google\\.android\\.tv\\.remote\\.service\$"
    grep -E '^package:com\.google\.android\.' "$TMPD/pkgs" | sed 's/^package://' \
        | grep -Ev "$_skip" || true
}

# ------------------------------------------------------------------ sections
s_location() {
    section "Location"
    sget secure location_mode
    _lm=$VAL
    if [ "$_lm" = 0 ]; then
        ok_already "location master switch (location_mode=0)"
    elif [ "$_lm" != __readfail__ ]; then
        record loc "$_lm" || return
        change "location master switch off (location_mode was $_lm)" "cmd location set-location-enabled false"
    fi
    sget secure location_providers_allowed
    if [ "$VAL" != __readfail__ ] && [ "$VAL" != null ] && [ -n "$VAL" ]; then
        for _pv in $(printf '%s' "$VAL" | tr ',' ' '); do
            record "locprov|$_pv" on || continue
            change "location provider $_pv off" "settings put secure location_providers_allowed $(q "-$_pv")"
        done
    else
        ok_already "location_providers_allowed empty"
    fi
    apply_setting global wifi_scan_always_enabled 0
    apply_setting global ble_scan_always_enabled 0
    apply_setting global assisted_gps_enabled 0
    apply_setting global wifi_wakeup_enabled 0
    apply_setting global wifi_networks_available_notification_on 0
    apply_setting global network_recommendations_enabled 0
}

s_adid() {
    section "Advertising ID"
    if [ "$ROOT" = 0 ]; then
        skip "opt-out and reset need --root: Android 11 has no Settings key for it (limit_ad_tracking does not exist); the opt-out flag lives in a Play services preference file"
        return
    fi
    rsu id
    case $OUT in *uid=0*) ;; *) fail "advertising ID: su is not available" "$OUT"; return ;; esac
    rsu "test -f $ADID_FILE"
    if [ "$RC" -ne 0 ]; then fail "advertising ID: $ADID_FILE not found"; return; fi
    if [ "$DRY" = 1 ]; then
        printf '  DRY  back up %s to %s\n' "$ADID_FILE" "$ADID_BAK"
        printf '  DRY  su -c am force-stop %s\n' "$ADID_PKG"
        printf '  DRY  overwrite %s in place with only enable_limit_ad_tracking=true\n' "$ADID_FILE"
        return
    fi
    if [ ! -f "$ADID_BAK" ]; then
        # The backup holds the old advertising ID, so keep it owner-only.
        ( umask 077; "$ADB" -s "$SERIAL" shell "su -c $(q "cat $ADID_FILE")" </dev/null >"$ADID_BAK" 2>"$TMPD/err" )
        if [ $? -ne 0 ] || [ ! -s "$ADID_BAK" ]; then
            rm -f "$ADID_BAK"
            fail "advertising ID: backup of preference file failed" "$(cat "$TMPD/err")"
            return
        fi
        record adid "$ADID_BAK" || return
    fi
    _cnt=$(grep -o 'adid_reset_count" value="[0-9]*' "$ADID_BAK" | grep -o '[0-9]*$' | head -1)
    _cnt=$(( ${_cnt:-0} + 1 ))
    _xml="<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
    <int name=\"adid_reset_count\" value=\"$_cnt\" />
    <boolean name=\"enable_limit_ad_tracking\" value=\"true\" />
</map>"
    change "stop Play services before editing its preference" "su -c $(q "am force-stop $ADID_PKG")" || return
    # In place rather than rm: keeps owner and SELinux label, so Play services can still read it.
    printf '%s\n' "$_xml" | "$ADB" -s "$SERIAL" shell "su -c $(q "cat > $ADID_FILE")" >"$TMPD/out" 2>&1
    if [ $? -ne 0 ]; then fail "advertising ID: writing preference failed" "$(cat "$TMPD/out")"; return; fi
    rsu "cat $ADID_FILE"
    if printf '%s\n' "$OUT" | grep -q 'enable_limit_ad_tracking" value="true"' && ! printf '%s\n' "$OUT" | grep -q adid_key; then
        printf '  done advertising ID reset and opt-out written (reset count %s)\n' "$_cnt"
        CHANGED=$((CHANGED+1))
    else
        fail "advertising ID: verification of the written preference failed" "$OUT"
    fi
}

s_packages() {
    section "Google packages"
    if [ "$NO_GMS" = 1 ]; then skip "Play services and Services Framework (--no-gms)"
    elif [ "$KEEP_ASSISTANT" = 1 ]; then skip "Play services and Services Framework (needed by the Assistant)"
    else disable_pkg com.google.android.gms; disable_pkg com.google.android.gsf
    fi
    disable_pkg com.android.vending
    if [ "$KEEP_ASSISTANT" = 1 ]; then skip "com.google.android.katniss (--keep-google-assistant)"
    else disable_pkg com.google.android.katniss
    fi
    for _p in $(google_extra_packages); do disable_pkg "$_p"; done
    for _p in $EXTRA_LIST; do disable_pkg "$_p"; done
}

s_defaults() {
    section "Privacy defaults"
    apply_setting secure assist_structure_enabled 0
    apply_setting secure assist_screenshot_enabled 0
    apply_setting global send_action_app_error 0
    apply_setting global verifier_verify_adb_installs 0
    case $CAPTIVE in
        alt)
            apply_setting global captive_portal_http_url http://connectivitycheck.grapheneos.network/generate_204
            apply_setting global captive_portal_https_url https://connectivitycheck.grapheneos.network/generate_204
            apply_setting global captive_portal_fallback_url http://connectivitycheck.grapheneos.network/generate_204
            ;;
        off) apply_setting global captive_portal_mode 0 ;;
        keep) skip "captive portal probing untouched" ;;
    esac
    if [ -n "$NTP" ]; then apply_setting global ntp_server "$NTP"; fi
    if [ -n "$PDNS" ]; then
        apply_setting global private_dns_specifier "$PDNS"
        apply_setting global private_dns_mode hostname
    fi
    rread "bmgr enabled" && {
        case $OUT in
            *"currently disabled"*) ok_already "backup manager disabled" ;;
            *"currently enabled"*)
                record bmgr enabled || return
                change "backup manager off" "bmgr enable false" ;;
            *) fail "cannot parse 'bmgr enabled'" "$OUT" ;;
        esac
    }
}

s_apps() {
    section "Per-app permissions and appops"
    for _p in $APPS; do
        printf ' - %s\n' "$_p"
        revoke_granted "$_p" "$LOC_PERMS"
        _k=0; in_list "$_p" "$KEEP_LIST" && _k=1
        if [ "$_k" = 1 ]; then skip "$_p keeps microphone and camera (HARDEN_KEEP)"
        else revoke_granted "$_p" "$MIC_CAM_PERMS"
        fi
        for _op in $LOC_OPS; do appop_apply "$_p" "$_op" ignore; done
        if [ "$STRICT" = 1 ]; then
            appop_apply "$_p" READ_CLIPBOARD ignore
            appop_apply "$_p" SYSTEM_ALERT_WINDOW ignore
        fi
    done
    for _p in $BG_LIST; do
        if is_protected "$_p"; then fail "refusing to restrict protected package $_p"; continue; fi
        if ! pkg_installed "$_p"; then skip "$_p not installed"; continue; fi
        appop_apply "$_p" RUN_IN_BACKGROUND ignore
        appop_apply "$_p" RUN_ANY_IN_BACKGROUND ignore
    done
}

# ------------------------------------------------------------------ status
s_status() {
    printf 'device: %s\nstate file: %s (%s)\n' "$SERIAL" "$STATE" "$([ -f "$STATE" ] && echo present || echo absent)"
    section "Settings"
    for _kv in secure:location_mode secure:location_providers_allowed global:wifi_scan_always_enabled \
        global:ble_scan_always_enabled global:assisted_gps_enabled global:wifi_wakeup_enabled \
        global:wifi_networks_available_notification_on global:network_recommendations_enabled \
        secure:assist_structure_enabled secure:assist_screenshot_enabled global:send_action_app_error \
        global:verifier_verify_adb_installs global:captive_portal_mode global:captive_portal_http_url \
        global:captive_portal_https_url global:captive_portal_fallback_url global:ntp_server \
        global:private_dns_mode global:private_dns_specifier; do
        sget "${_kv%%:*}" "${_kv#*:}"
        printf '  %-12s %-45s %s\n' "${_kv%%:*}" "${_kv#*:}" "$VAL"
    done
    rcmd "bmgr enabled"; printf '  backup manager: %s\n' "$OUT"
    rcmd "dumpsys wifi"; printf '%s\n' "$OUT" | grep -m1 macRandomizationSetting | sed 's/^ */  wlan: /'
    rcmd "settings get secure enabled_notification_listeners"; printf '  notification listeners: %s\n' "$OUT"
    rcmd "settings get secure enabled_accessibility_services"; printf '  accessibility services: %s\n' "$OUT"
    section "Google packages"
    for _p in com.google.android.gms com.google.android.gsf com.android.vending com.google.android.katniss $(google_extra_packages); do
        if pkg_installed "$_p"; then
            case $(pkg_state "$_p") in 2|3) _s=disabled ;; *) _s=enabled ;; esac
            printf '  %-45s %s\n' "$_p" "$_s"
        fi
    done
    section "Non-system apps holding location, microphone or camera"
    for _p in $APPS; do
        rcmd "dumpsys package $_p"
        _g=$(printf '%s\n' "$OUT" | sed -n 's/^ *android\.permission\.\(ACCESS_[A-Z_]*LOCATION\|RECORD_AUDIO\|CAMERA\): granted=true.*/\1/p' | sort -u | tr '\n' ' ')
        printf '  %-45s %s\n' "$_p" "${_g:-none}"
    done
    section "Advertising ID (needs --root)"
    if [ "$ROOT" = 1 ]; then
        rsu "test -f $ADID_FILE && sed -E 's/>[^<]{12,}</>REDACTED</' $ADID_FILE"
        printf '%s\n' "$OUT" | sed 's/^/  /'
    else
        printf '  not readable without root\n'
    fi
}

# -------------------------------------------------------------------- undo
undo_line() {
    IFS='|' read -r _kind _a _b _c _d <<EOF
$1
EOF
    case $_kind in
        setting)
            _v=$_c${_d:+|$_d}
            if [ "$_v" = null ]; then change "restore $_a $_b (unset)" "settings delete $_a $_b"
            else change "restore $_a $_b=$_v" "settings put $_a $_b $(q "$_v")"
            fi ;;
        loc)
            if [ "$_a" != 0 ] && [ "$_a" != null ]; then
                change "location master switch on" "cmd location set-location-enabled true" || return
                sget secure location_mode
                [ "$VAL" = "$_a" ] || change "location_mode=$_a" "settings put secure location_mode $(q "$_a")"
            fi ;;
        locprov) change "location provider $_a on" "settings put secure location_providers_allowed $(q "+$_a")" ;;
        pkg)
            if ! pkg_installed "$_a"; then skip "$_a not installed"; return; fi
            case $_b in
                0) change "default state of $_a" "pm default-state --user 0 $_a" ;;
                1) change "enable $_a" "pm enable --user 0 $_a" ;;
                2) change "disable $_a" "pm disable --user 0 $_a" ;;
                3) change "disable-user $_a" "pm disable-user --user 0 $_a" ;;
                *) fail "bad pkg state in state file: $1" ;;
            esac ;;
        perm)
            if ! pkg_installed "$_a"; then skip "$_a not installed"; return; fi
            change "grant $_b to $_a" "pm grant --user 0 $_a $_b" ;;
        appop)
            if ! pkg_installed "$_a"; then skip "$_a not installed"; return; fi
            if [ "$_d" = uid ]; then _f='--uid '; else _f=; fi
            change "appops $_a $_b back to $_c" "cmd appops set ${_f}$_a $_b $_c" ;;
        bmgr) [ "$_a" = enabled ] && change "backup manager on" "bmgr enable true" ;;
        adid)
            if [ ! -s "$_a" ]; then fail "advertising ID backup $_a missing"; return; fi
            if [ "$ROOT" = 0 ]; then skip "advertising ID restore needs --root"; return; fi
            if [ "$DRY" = 1 ]; then printf '  DRY  restore %s from %s\n' "$ADID_FILE" "$_a"; return; fi
            change "stop Play services" "su -c $(q "am force-stop $ADID_PKG")" || return
            "$ADB" -s "$SERIAL" shell "su -c $(q "cat > $ADID_FILE")" <"$_a" >"$TMPD/out" 2>&1
            if [ $? -ne 0 ]; then fail "advertising ID restore failed" "$(cat "$TMPD/out")"
            else printf '  done advertising ID preference restored\n'; CHANGED=$((CHANGED+1)); fi ;;
        '') ;;
        *) fail "unknown state line: $1" ;;
    esac
}

s_undo() {
    [ -s "$STATE" ] || die "no state file at $STATE: nothing to undo"
    section "Restoring recorded values (newest first)"
    sed '1!G;h;$!d' "$STATE" >"$TMPD/rev"
    while IFS= read -r _line; do undo_line "$_line"; done <"$TMPD/rev"
}

# -------------------------------------------------------------------- main
printf '%s %s on %s%s\n' "$PROG" "$CMD" "$SERIAL" "$([ "$DRY" = 1 ] && [ "$CMD" != status ] && echo ' (DRY RUN: nothing is changed; add --yes)')"

rread "pm list packages" || exit 1
printf '%s\n' "$OUT" >"$TMPD/pkgs"
rcmd "getprop ro.build.version.release"
[ "$OUT" = 11 ] || printf 'warning: Android %s, this script was verified on Android 11 only\n' "$OUT"
rread "pm list packages -3" || exit 1
APPS=
for _p in $(printf '%s\n' "$OUT" | sed 's/^package://'); do
    is_protected "$_p" || APPS="$APPS $_p"
done

case $CMD in
    status) s_status ;;
    apply)
        s_location
        s_adid
        s_packages
        s_defaults
        s_apps
        ;;
    undo) s_undo ;;
esac

NFAIL=$(grep -c . "$FAILED" || true)
if [ "$CMD" = undo ] && [ "$DRY" = 0 ] && [ "$NFAIL" = 0 ] && [ -f "$STATE" ]; then
    mv "$STATE" "$STATE.undone" && printf 'state file moved to %s\n' "$STATE.undone"
fi
if [ "$CMD" != status ]; then
    printf '\nSummary: %s changed, %s already as wanted, %s skipped, %s failed\n' "$CHANGED" "$ALREADY" "$SKIPPED" "$NFAIL"
fi
if [ "$NFAIL" -gt 0 ]; then
    printf 'Failed items:\n'; sed 's/^/  - /' "$FAILED"
    exit 1
fi
exit 0
