# Sleep and the screen saver timeout can take the whole unit down

**Symptom:** the projector becomes unreachable over network adb (`no route to host`) and, when checked after
power-cycling it back on, sometimes shows a fresh boot (`uptime` near zero, boot reason `shutdown`) with no
warning and no pattern tied to anything we were doing to it.

**Likely cause, not yet proven end to end:** `Settings.System.screen_off_timeout` (the "Screen saver" row in
[../projection](../projection/)) is the normal Android inactivity timer. When it expires, the system calls
`PowerManager.goToSleep()` through the same code path as pressing the remote's power key. We tested that path
directly on this firmware: sending `KEYCODE_SLEEP` put the display to sleep and **the whole unit left the
network within seconds**, even while holding a kernel wake lock meant to keep the CPU and WLAN running.
A plain screen-off is not supposed to do that; on this hardware it behaves like a full suspend attempt instead
of just turning off the backlight.

This also fits what the [mainline Linux porting project](related-work.md) for this chip reports independently:
their known-issues list names **no working standby** as an open hardware/firmware problem, with the device
drawing full power while "off" or otherwise misbehaving around the sleep/suspend path. We have not confirmed
that a reboot (not just a dropped network link) follows every expired timeout, or that this is the same
mechanism as every earlier unexplained restart in this project, but the match in symptoms, the timing (the
stock default of 20 minutes lined up with several earlier unexplained gaps before the cause was known), and an
independent report of the same class of bug on the same hardware make it the leading explanation.

## What to do now

Set the screen saver timeout to **Never** (the last option in the Projection app's "Screen saver" row,
`screen_off_timeout` = `2147483647`) until the suspend path on this firmware is understood or fixed. This does
not fix the underlying bug, it just avoids triggering it automatically. The projector will stay lit
indefinitely; there is currently no known-safe way on this firmware to turn the picture off while keeping the
system (network, apps) running. A plain `goToSleep()` call does not do it safely (see above), and the fan,
backlight and status LED share one hardware switch on this chip (see
[../.claude/skills/h713-projection-controls/SKILL.md](../.claude/skills/h713-projection-controls/SKILL.md)), so
nothing in this project touches that switch from software.

## What would make this conclusive

- Set the timeout to a short value (for example 1-2 minutes if reachable, or use the existing 5 or 10 minute
  option), let it expire deliberately, and capture a kernel log (`dmesg`, persisted if possible) across the
  event to see whether it is a clean suspend/resume that hangs, a watchdog reset, or something else.
- Check whether `adb shell dumpsys power` right before the timeout confirms `goToSleep` fires, and whether
  `/sys/power/wakeup_count` or similar changes meaningfully.
- Compare behavior with the timeout left at the default versus set to Never over a multi-hour idle period, to
  rule out an unrelated cause for the earlier restarts.

None of this has been done yet; this page records the hypothesis and the avoidance so it is not lost.
