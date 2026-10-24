#!/system/bin/sh
# Manual four-corner keystone, the logic of the vendor CorrectionActivity as a line-driven server:
# the app writes "key CODE REPEAT" lines to stdin and shows every line printed on stdout.
# Values are per-mille of the panel, positive always moves a corner inward (vendor KeystoneUtils).
# Usage: keystone.sh server
# Env:   KS_DRY=1  print the mutating commands instead of running them

SF_CODE=1050
SEL=lt
STEP_MAX=8

fmt() { printf '%d.%03d' $(($1 / 1000)) $(($1 % 1000)); }

run() { if [ "$KS_DRY" = 1 ]; then echo "DRY: $*" >&2; else "$@" >/dev/null || echo "FAILED: $*" >&2; fi; }

load() {
    for n in ltx lty rtx rty rbx rby lbx lby; do
        v=$(getprop persist.display.keystone_$n)
        [ -n "$v" ] || v=0
        eval "$n=$v"
    done
}

# SurfaceFlinger keeps persist.display.keystone_* itself on every call, so a reboot restores the picture
apply() {
    run service call SurfaceFlinger $SF_CODE f $(fmt $lbx) f $(fmt $lby) f $(fmt $ltx) f $(fmt $lty) \
        f $(fmt $rtx) f $(fmt $rty) f $(fmt $rbx) f $(fmt $rby)
}

# the vendor screen and its zoom code read the persist.htc.keystone.* copy
persist_corner() {
    eval "run setprop persist.htc.keystone.${1}x \$${1}x; run setprop persist.htc.keystone.${1}y \$${1}y"
}

opposite() {
    case $1 in
        ltx) echo rtx;; rtx) echo ltx;; lbx) echo rbx;; rbx) echo lbx;;
        lty) echo lby;; lby) echo lty;; rty) echo rby;; rby) echo rty;;
    esac
}

next_corner() { case $1 in lt) echo rt;; rt) echo rb;; rb) echo lb;; lb) echo lt;; esac; }

corner_name() { case $1 in lt) echo "top left";; rt) echo "top right";; rb) echo "bottom right";; lb) echo "bottom left";; esac; }

# move CORNER AXIS DELTA: clamp to 0 and to a sum of at most 1000 with the opposite corner, as the vendor does
move() {
    _n=$1$2
    eval "_cur=\$$_n"
    _opp=$(opposite $_n)
    eval "_ov=\$$_opp"
    _new=$((_cur + $3))
    [ $_new -lt 0 ] && _new=0
    [ $((_new + _ov)) -gt 1000 ] && _new=$((1000 - _ov))
    [ $_new = $_cur ] && return 1
    eval "$_n=$_new"
    return 0
}

blocked() {
    if [ "$(getprop persist.sys.tpryauto)" = 1 ]; then echo "Auto keystone is on: switch it off first"; return 0; fi
    if [ "$(getprop persist.sys.tpryxcrt)" = 1 ]; then echo "Auto four corner is on: switch it off first"; return 0; fi
    return 1
}

status() {
    _m=$(blocked) && _msg="$_m|" || _msg=""
    _l=""
    for c in lt rt rb lb; do
        eval "_x=\$${c}x; _y=\$${c}y"
        [ $c = $SEL ] && _mark=">" || _mark=" "
        _l="$_l$_mark $(corner_name $c): $_x, $_y|"
    done
    echo "${_msg}Manual keystone|$_l|Arrows move the marked corner, OK marks the next corner,|hold OK to reset, Back to leave"
}

key() { # key CODE REPEAT
    _code=$1; _rep=$2
    case $_code in
        23|66)
            if [ "$_rep" = 0 ]; then PREV=$SEL; SEL=$(next_corner $SEL)
            elif [ "$_rep" = 10 ]; then
                SEL=$PREV
                ltx=0; lty=0; rtx=0; rty=0; rbx=0; rby=0; lbx=0; lby=0
                apply
                for c in lt rt rb lb; do persist_corner $c; done
                run setprop persist.sys.zoom.value 0,0,0,0,0,0,0,0
            fi
            return;;
        19|20|21|22) ;;
        *) return;;
    esac
    blocked >/dev/null && return
    _step=$((_rep + 1)); [ $_step -gt $STEP_MAX ] && _step=$STEP_MAX
    case $_code in 22) _dx=$_step; _dy=0;; 21) _dx=-$_step; _dy=0;; 20) _dx=0; _dy=$_step;; 19) _dx=0; _dy=-$_step;; esac
    # inward is right on the left corners and down on the top corners
    case $SEL in lt|lb) _sx=1;; *) _sx=-1;; esac
    case $SEL in lt|rt) _sy=1;; *) _sy=-1;; esac
    _changed=0
    [ $_dx != 0 ] && move $SEL x $((_dx * _sx)) && _changed=1
    [ $_dy != 0 ] && move $SEL y $((_dy * _sy)) && _changed=1
    if [ $_changed = 1 ]; then apply; persist_corner $SEL; fi
}

server() {
    load
    PREV=$SEL
    status
    while read -r cmd a b; do
        case $cmd in
            key) key "$a" "$b"; status;;
            quit) break;;
        esac
    done
}

case "$1" in
    server) server;;
    *) echo "usage: keystone.sh server" >&2; exit 1;;
esac
