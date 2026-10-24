#!/system/bin/sh
# Plain system settings of the vendor launcher (OtherSettings, audio mode, lamp level, factory reset).
# Usage: system.sh ROW get|step DIR   (DIR = 1 or -1; toggles ignore it)
# Env:   P  app files directory (confirmation stamps live there)
#        APK  app APK path (audio mode needs the Helper)
#        SYS_DRY=1  print the dangerous commands instead of running them

[ -n "$P" ] || { echo "error: P not set" >&2; exit 1; }

run() { if [ "$SYS_DRY" = 1 ]; then echo "DRY: $*" >&2; else "$@" >/dev/null; fi; }

# index of $1 in the remaining words, 0 when absent
index_of() { _v=$1; shift; _i=0; for _w in "$@"; do [ "$_w" = "$_v" ] && { echo $_i; return; }; _i=$((_i + 1)); done; echo 0; }

# wrap-around pick: next_of DIR CURRENT VALUES...
next_of() {
    _d=$1; _c=$2; shift 2
    _n=$#; _i=$(index_of "$_c" "$@")
    _i=$(( (_i + _d + _n) % _n ))
    shift $_i
    echo "$1"
}

# A second call within 5 s confirms; the first call only arms. Returns 0 when confirmed.
confirm() {
    _f=$P/.confirm_$1
    _now=$(date +%s)
    _then=$(cat "$_f" 2>/dev/null)
    rm -f "$_f"
    if [ -n "$_then" ] && [ $((_now - _then)) -le 5 ] && [ $((_now - _then)) -ge 0 ]; then return 0; fi
    echo "$_now" > "$_f"
    return 1
}

armed() {
    _then=$(cat "$P/.confirm_$1" 2>/dev/null)
    [ -n "$_then" ] && [ $(( $(date +%s) - _then )) -le 5 ]
}

audio_names="Standard Music Movie News"

# The vendor reads the mode back from the audio HAL, which answers unreliably, so the last value we set is kept here.
audio_get() {
    v=$(getprop persist.hy310.audio_mode)
    case $v in 0) echo Standard;; 1) echo Music;; 2) echo Movie;; 3) echo News;; *) echo Unknown;; esac
}
audio_step() {
    cur=$(getprop persist.hy310.audio_mode)
    case $cur in 0|1|2|3) ;; *) cur=0;; esac
    new=$(( (cur + $1 + 4) % 4 ))
    # Android 11 has no shell command for this: AudioManager.setParameters("audio_mode=N") needs the Helper
    CLASSPATH=$APK app_process /system/bin io.github.probonopd.hy310projection.Helper set-audio-mode $new >/dev/null || { echo "error: Helper set-audio-mode failed" >&2; exit 1; }
    setprop persist.hy310.audio_mode $new
}

bootsrc_get() {
    case $(getprop persist.sys.default_source) in HDMI1) echo HDMI1;; *) echo Nothing;; esac
}
bootsrc_step() {
    case $(getprop persist.sys.default_source) in HDMI1) n=LOCAL;; *) n=HDMI1;; esac
    setprop persist.sys.default_source $n
}

saver_vals="300000 600000 1200000 3600000 2147483647"
saver_get() {
    case $(settings get system screen_off_timeout) in
        300000) echo 5 min;; 600000) echo 10 min;; 1200000) echo 20 min;; 3600000) echo 1 hour;;
        2147483647) echo Never;; *) echo 5 min;;
    esac
}
saver_step() {
    cur=$(settings get system screen_off_timeout)
    new=$(next_of "$1" "$cur" $saver_vals)
    settings put system screen_off_timeout "$new"
}

btnsound_get() { [ "$(settings get system sound_effects_enabled)" = 1 ] && echo On || echo Off; }
btnsound_step() {
    n=1; [ "$(settings get system sound_effects_enabled)" = 1 ] && n=0
    settings put system sound_effects_enabled $n
}

# The vendor also writes persist.sys.usb0device here; nothing was found that consumes it, so it is not set.
adb_get() {
    if [ "$(settings get global adb_enabled)" = 1 ]; then
        armed adb_off && echo "On - press again to switch off (ends this adb session)" || echo On
    else
        echo Off
    fi
}
adb_step() {
    if [ "$(settings get global adb_enabled)" = 1 ]; then
        # switching adb off kills the session that sent this command, so it needs a second press within 5 s
        confirm adb_off || { echo "armed: press again within 5 s to switch adb off" >&2; exit 1; }
        run settings put global adb_enabled 0
    else
        settings put global adb_enabled 1
    fi
}

# Only the two values the vendor default configuration ever writes (raw level 2 = 90, 3 = 100, the factory default and maximum).
lamp_get() { cat /sys/class/backlight/tv/brightness; }
lamp_step() {
    if [ "$(cat /sys/class/backlight/tv/brightness)" = 100 ]; then v=90; raw=2; else v=100; raw=3; fi
    printf '%s' $v > /sys/class/backlight/tv/brightness || exit 1
    setprop persist.sys.prj.brightness $raw
}

reset_get() { armed factory_reset && echo "press again to erase everything" || echo "Erase all data"; }
reset_step() {
    confirm factory_reset || { echo "armed: press again within 5 s to erase everything" >&2; exit 0; }
    run am broadcast -a android.intent.action.FACTORY_RESET -p android -f 0x10000000 --es android.intent.extra.REASON ResetConfirmFragment
}

row=$1; op=$2; dir=${3:-1}
case "$row" in audio|bootsrc|saver|btnsound|adb|lamp|reset) ;; *) echo "usage: system.sh audio|bootsrc|saver|btnsound|adb|lamp|reset get|step [1|-1]" >&2; exit 2;; esac
case "$op" in get) "${row}_get";; step) "${row}_step" "$dir";; *) echo "bad op" >&2; exit 2;; esac
