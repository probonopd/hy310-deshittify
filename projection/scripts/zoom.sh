#!/system/bin/sh
# Digital zoom / keystone helper. Re-implements the vendor Projection screen
# (com.htc.spectraos ProjectActivity.changeform + KeystoneUtils) as root shell.
#
# Usage: zoom.sh get | step DELTA | set N | reset | reapply | remap OLD NEW | show N
# Env:   ZOOM_MODE=16:9|4:3|16:10 (default 16:9)
#        ZOOM_DRY=1   print every mutating command instead of running it
#        LCD_W/LCD_H  override the size otherwise read from `wm size`
#        ZOOM_AUTO=0|1 override persist.sys.tpryauto (host-side testing)
#        ZOOM_PROPFILE=file  read properties from "key=value" lines instead of getprop

ZOOM_MAX=20
SF_CODE=1050
KEYS="lb_X lb_Y lt_X lt_Y rt_X rt_Y rb_X rb_Y"

die() { echo "zoom.sh: $*" >&2; exit 1; }

prop() { # prop KEY DEFAULT
    if [ -n "$ZOOM_PROPFILE" ]; then
        _v=$(sed -n "s/^$1=//p" "$ZOOM_PROPFILE" | tail -n 1)
    else
        _v=$(getprop "$1")
    fi
    [ -n "$_v" ] || _v=$2
    echo "$_v"
}

run() { # every state-changing command goes through here
    if [ "$ZOOM_DRY" = 1 ]; then
        echo "DRY: $*"
    else
        "$@" || die "failed: $*"
    fi
}

isint() { case "$1" in ''|*[!0-9-]*|-|*?-*) return 1;; esac; return 0; }

get_auto() {
    if [ -n "$ZOOM_AUTO" ]; then echo "$ZOOM_AUTO"; return; fi
    [ "$(prop persist.sys.tpryauto 0)" = 1 ] && echo 1 || echo 0
}

get_zoom() {
    _z=$(settings get global zoom_value)
    case "$_z" in null|'') _z=0;; esac
    isint "$_z" || die "bad zoom_value '$_z'"
    echo "$_z"
}

lcd_size() { # sets LCD_W LCD_H; a physical override (wm size -> Override size) wins, as in DisplayMetrics
    if [ -n "$LCD_W" ] && [ -n "$LCD_H" ]; then return; fi
    _wm=$(wm size) || die "wm size failed"
    _s=$(echo "$_wm" | sed -n 's/^Override size: *//p' | tail -n 1)
    [ -n "$_s" ] || _s=$(echo "$_wm" | sed -n 's/^Physical size: *//p' | tail -n 1)
    LCD_W=${_s%x*}
    LCD_H=${_s#*x}
    isint "$LCD_W" && isint "$LCD_H" || die "cannot parse wm size: $_wm"
}

mode_params() { # sets SCALE STEP_X STEP_Y (vendor initData zoom_mode switch)
    case "${ZOOM_MODE:-16:9}" in
        16:9)  SCALE=1.0;   STEP_X=16; STEP_Y=9;;
        4:3)   SCALE=0.875; STEP_X=12; STEP_Y=9;;
        16:10) SCALE=0.95;  STEP_X=16; STEP_Y=10;;
        *) die "bad ZOOM_MODE '$ZOOM_MODE'";;
    esac
}

# Output: eight per-mille integers in KEYS order. Mirrors ProjectActivity.changeform
# with all four zoom args equal; rounding is DecimalFormat("0") HALF_EVEN on doubles,
# the Y terms use Java int division (truncation) before formatting.
compute_corners() { # compute_corners N
    lcd_size
    mode_params
    awk -v z="$1" -v W="$LCD_W" -v H="$LCD_H" -v sc="$SCALE" -v sx="$STEP_X" -v sy="$STEP_Y" '
    function rnd(x,  f, d) { f = int(x); d = x - f
        if (d > 0.5) return f + 1
        if (d < 0.5) return f
        return (f % 2 == 0) ? f : f + 1 }
    BEGIN {
        zsx = W / 100.0
        ltx = rnd((((100.0 - sc * 100.0) * zsx) + sx * z) * 1000.0 / W)
        lty = 1000 - int(((H - sy * z) * 1000) / H)
        lbx = ltx
        lby = int((sy * z * 1000) / H)
        rtx = 1000 - rnd((W * sc - sx * z) * 1000.0 / W)
        rty = lty
        rbx = rtx
        rby = lby
        print lbx, lby, ltx, lty, rtx, rty, rbx, rby
    }'
}

sf_cmd() { # sf_cmd v1 .. v8 -> service call command line, floats = value * 0.001
    echo "$@" | awk -v c="$SF_CODE" '{ s = "service call SurfaceFlinger " c
        for (i = 1; i <= 8; i++) s = s " f " sprintf("%.3f", $i / 1000.0); print s }'
}

csv() { echo "$*" | sed 's/ /,/g'; }

push_sf() { # push_sf v1 .. v8
    _cmd=$(sf_cmd "$@")
    # shellcheck disable=SC2086
    run $_cmd
}

persist_zoom() { run setprop persist.sys.zoom.value "$(csv "$@")"; }

apply_zoom() { # apply_zoom N  (vendor set_screen_zoom -> changeform)
    _n=$1
    run settings put global zoom_value "$_n"
    _c=$(compute_corners "$_n") || exit 1
    if [ "$(get_auto)" = 1 ]; then
        # auto keystone owns the panel: persist only, then let its service recompute
        # shellcheck disable=SC2086
        persist_zoom $_c
        run am broadcast -a android.intent.hotack_keystone --ei ratio 1 -f 0x10000000
    else
        if [ "$(prop persist.sys.camok 0)" = 1 ]; then
            echo "zoom.sh: note: vendor uses updateZoom (not changeform) for camok=1 + auto off; that path is not implemented" >&2
        fi
        # shellcheck disable=SC2086
        push_sf $_c
        # shellcheck disable=SC2086
        persist_zoom $_c
    fi
}

cmd_reapply() { # vendor updateZoomValue: put the saved corners back on the panel after auto keystone is switched off
    _v=$(prop persist.sys.zoom.value 0,0,0,0,0,0,0,0)
    _c=$(echo "$_v" | tr ',' ' ')
    [ "$(echo "$_c" | wc -w)" -eq 8 ] || die "persist.sys.zoom.value must hold 8 values, got: $_v"
    for _x in $_c; do isint "$_x" || die "persist.sys.zoom.value has a non-integer: $_v"; done
    # shellcheck disable=SC2086
    push_sf $_c
}

cmd_show() {
    _n=$1
    isint "$_n" && [ "$_n" -ge 0 ] && [ "$_n" -le $ZOOM_MAX ] || die "N must be 0..$ZOOM_MAX"
    lcd_size
    mode_params
    _c=$(compute_corners "$_n") || exit 1
    echo "zoom=$_n mode=${ZOOM_MODE:-16:9} lcd=${LCD_W}x${LCD_H} auto=$(get_auto)"
    _i=1
    for k in $KEYS; do
        printf '%s=%s ' "$k" "$(echo "$_c" | cut -d' ' -f$_i)"
        _i=$((_i + 1))
    done
    echo
    # shellcheck disable=SC2086
    echo "persist.sys.zoom.value=$(csv $_c)"
    if [ "$(get_auto)" = 1 ]; then
        echo "path: persist only + am broadcast -a android.intent.hotack_keystone --ei ratio 1 -f 0x10000000"
    else
        echo "path: SurfaceFlinger transact then persist"
    fi
    # shellcheck disable=SC2086
    sf_cmd $_c
}

cmd_reset() { # KeystoneUtils.resetKeystone + zoom_value 0
    push_sf 0 0 0 0 0 0 0 0
    for k in ltx lty rtx rty lbx lby rbx rby; do
        run setprop persist.htc.keystone.$k 0
    done
    run setprop persist.sys.zoom.value 0,0,0,0,0,0,0,0
    run settings put global zoom_value 0
}

# UNVERIFIED on hardware: derived by interpreting KeystoneUtils.setKeystoneNormalXY
# register moves. Result: each corner takes the X/Y pair of the corner mirrored
# horizontally when the mode's X flip differs, vertically when the Y flip differs.
# Mode flips: 0=(0,0) 1=(1,0) 2=(1,1) 3=(0,1) as (flipX,flipY).
flip_x() { case "$1" in 0|3) echo 0;; 1|2) echo 1;; esac; }
flip_y() { case "$1" in 0|1) echo 0;; 2|3) echo 1;; esac; }

src_corner() { # src_corner CORNER DX DY -> source corner name (lt rt lb rb)
    _h=${1%?}; _v=${1#?}
    if [ "$2" = 1 ]; then case "$_h" in l) _h=r;; r) _h=l;; esac; fi
    if [ "$3" = 1 ]; then case "$_v" in t) _v=b;; b) _v=t;; esac; fi
    echo "$_h$_v"
}

cmd_remap() {
    _o=$1; _n=$2
    case "$_o" in 0|1|2|3) ;; *) die "OLD must be 0..3";; esac
    case "$_n" in 0|1|2|3) ;; *) die "NEW must be 0..3";; esac
    if [ "$(prop persist.sys.camok 0)" != 1 ] || [ "$(prop persist.sys.focusupdn 0)" != 0 ]; then
        echo "remap skipped: needs persist.sys.camok=1 and persist.sys.focusupdn=0" >&2
        return 0
    fi
    _dx=$(( $(flip_x "$_o") ^ $(flip_x "$_n") ))
    _dy=$(( $(flip_y "$_o") ^ $(flip_y "$_n") ))
    # Part 1: factory points (persist.display.keystone_*) go to the panel and zoom.value.
    _sf=""
    for d in lb lt rt rb; do
        s=$(src_corner $d $_dx $_dy)
        eval "${d}_X=$(prop persist.display.keystone_${s}x 0); ${d}_Y=$(prop persist.display.keystone_${s}y 0)"
    done
    # shellcheck disable=SC2154
    set -- $lb_X $lb_Y $lt_X $lt_Y $rt_X $rt_Y $rb_X $rb_Y
    push_sf "$@"
    persist_zoom "$@"
    # Part 2: user points (persist.htc.keystone.*) are rotated in place; read all first.
    for c in lt rt lb rb; do
        eval "u_${c}x=$(prop persist.htc.keystone.${c}x 0); u_${c}y=$(prop persist.htc.keystone.${c}y 0)"
    done
    for d in lt rt lb rb; do
        s=$(src_corner $d $_dx $_dy)
        eval "run setprop persist.htc.keystone.${d}x \$u_${s}x"
        eval "run setprop persist.htc.keystone.${d}y \$u_${s}y"
    done
}

case "$1" in
    get) get_zoom;;
    show) [ $# -eq 2 ] || die "usage: show N"; cmd_show "$2";;
    set)
        [ $# -eq 2 ] || die "usage: set N"
        isint "$2" && [ "$2" -ge 0 ] && [ "$2" -le $ZOOM_MAX ] || die "N must be 0..$ZOOM_MAX"
        apply_zoom "$2"; echo "$2";;
    step)
        [ $# -eq 2 ] || die "usage: step DELTA"
        isint "$2" || die "DELTA must be an integer"
        _cur=$(get_zoom) || exit 1
        _new=$((_cur + $2))
        [ "$_new" -lt 0 ] && _new=0
        [ "$_new" -gt $ZOOM_MAX ] && _new=$ZOOM_MAX
        if [ "$_new" != "$_cur" ]; then apply_zoom "$_new"; fi
        echo "$_new";;
    reset) cmd_reset;;
    reapply) cmd_reapply;;
    remap) [ $# -eq 3 ] || die "usage: remap OLD NEW"; cmd_remap "$2" "$3";;
    *) die "usage: zoom.sh get | step DELTA | set N | reset | reapply | remap OLD NEW | show N";;
esac
