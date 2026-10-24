# power.sh - timed shutdown and Bluetooth speaker mode, run as root via "sh power.sh ...".
# Usage: power.sh timeoff get|set MIN|step DIR|cancel|status
#        power.sh btspeaker get|toggle
# POWER_DRY=1 prints the shutdown / wireless commands instead of running them.
# The timer is volatile on purpose (like the vendor one): the property keeps the chosen
# value for display, but nothing re-arms the watcher after a reboot.

PROP=persist.hy310.timeoff_min
TGT=/data/local/tmp/hy310_timeoff.target
LOG=/data/local/tmp/hy310_timeoff.log
STEP=${POWER_STEP:-5}

log() { echo "$(date '+%H:%M:%S') $*" >> $LOG; }

# Notifications posted by uid 2000 (shell): the shell package is allowed to post, root is not.
warn() { su 2000 -c "cmd notification post -t Shutdown shutdown-warning '$1'" >/dev/null 2>&1; log "warn: $1"; }

do_shutdown() {
    if [ "$POWER_DRY" = 1 ]; then
        echo "DRY: svc power shutdown"; log "DRY: svc power shutdown"
    else
        log "shutdown"; svc power shutdown
    fi
}

# Runs detached. Ends when the target file is gone or replaced by a newer set.
watch() {
    me=$1; w60=0; w15=0
    while :; do
        [ "$(cat $TGT 2>/dev/null)" = "$me" ] || { log "watcher ends (cancelled or replaced)"; exit 0; }
        left=$(( ${me%%:*} - $(date +%s) ))
        if [ $left -le 0 ]; then
            rm -f $TGT; do_shutdown; exit 0
        fi
        if [ $left -le 15 ] && [ $w15 = 0 ]; then w15=1; w60=1; warn 'Shutting down in 15 s'
        elif [ $left -le 60 ] && [ $w60 = 0 ]; then w60=1; warn 'Shutting down in 60 s'; fi
        # Short steps near the end so the 15 s warning and the shutdown are not late.
        if [ $left -le 20 ]; then sleep 1; else sleep $STEP; fi
    done
}

timeoff_get() {
    m=$(getprop $PROP); [ -n "$m" ] && [ "$m" != 0 ] && echo "$m min" || echo Off
}

timeoff_set() {
    m=$1
    case $m in ''|*[!0-9]*) echo "error: minutes expected" >&2; exit 1;; esac
    rm -f $TGT
    setprop $PROP $m
    [ $m = 0 ] && { log "off"; return 0; }
    me=$(( $(date +%s) + m * 60 )):$$
    echo "$me" > $TGT
    log "armed $m min -> $me"
    # All three fds redirected: the caller waits for EOF on its pipe.
    ( sh "$0" timeoff watch "$me" ) >/dev/null 2>&1 </dev/null &
}

timeoff_step() {
    cur=$(getprop $PROP); [ -n "$cur" ] || cur=0
    case $cur in 0) i=0;; 5) i=1;; 10) i=2;; 20) i=3;; 60) i=4;; *) i=0;; esac
    i=$(( (i + $1 + 5) % 5 ))
    set -- 0 5 10 20 60
    shift $i
    timeoff_set $1
}

timeoff_status() {
    if [ -f $TGT ]; then
        t=$(cat $TGT); left=$(( ${t%%:*} - $(date +%s) ))
        [ $left -lt 0 ] && left=0
        echo "armed, ${left} s left"
    else
        echo "not armed"
    fi
}

# Run the radio command, or print it when POWER_DRY=1.
run() { if [ "$POWER_DRY" = 1 ]; then echo "DRY: $*"; else "$@" >/dev/null 2>&1; fi; }

bt_get() { [ "$(getprop persist.bluetooth.a2dp.sink)" = true ] && echo On || echo Off; }

# Speaker mode is the property flip done by system_server's receiver plus WLAN off, which the
# vendor screen does for radio coexistence. No lamp or fan handling here on purpose.
bt_toggle() {
    if [ "$(getprop persist.bluetooth.a2dp.sink)" = true ]; then
        run am broadcast -a android.intent.switch_bt_speaker --ez changetosink false
        run svc wifi enable
    else
        run am broadcast -a android.intent.switch_bt_speaker --ez changetosink true
        run svc wifi disable
    fi
}

case "$1 $2" in
    "timeoff get") timeoff_get;;
    "timeoff set") timeoff_set "$3";;
    "timeoff step") timeoff_step "$3";;
    "timeoff cancel") timeoff_set 0;;
    "timeoff status") timeoff_status;;
    "timeoff watch") watch "$3";;
    "btspeaker get") bt_get;;
    "btspeaker toggle") bt_toggle;;
    *) echo "usage: power.sh timeoff get|set MIN|step DIR|cancel|status | btspeaker get|toggle" >&2; exit 1;;
esac
