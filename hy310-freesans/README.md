# Default font: FreeSans Bold

Replaces the device's default UI font (Roboto) with GNU FreeSans **Bold** everywhere,
system-wide - every weight, not just Roboto's own Bold/Black. This Magisk module overlays
`/system/fonts/Roboto-*.ttf` (the 12 weight/style files `fonts.xml`'s `sans-serif` family -
"first font is default", also aliased to arial/helvetica/tahoma/verdana - already names) with
FreeSans Bold/BoldOblique, renamed to match. `fonts.xml` itself is never touched: everything
that already points at `Roboto-Regular.ttf` etc. just gets different glyphs. `RobotoCondensed-*`
and the per-script Noto/SourceSansPro fallback fonts are left alone.

```sh
./install.sh
adb reboot
```

`./install.sh --build-only DIR` writes the module tree without touching the device. Needs the
`fonts-freefont-ttf` package (Debian/Ubuntu) for the source files; override the source
directory with `FREEFONT_DIR` if they live elsewhere.

Remove: `adb shell su -c "touch /data/adb/modules/hy310_freesans/disable"` and reboot (or
`rm -rf /data/adb/modules/hy310_freesans` to remove it outright).

A separate module, [`assistant-fonts`](../assistant-fonts/README.md) (id `hy310_fonts`),
defines the `google-sans*` family names the Google app needs when Play services is disabled -
unrelated and compatible with this one (it edits `fonts.xml`, this one doesn't).

## Tested

Installed and rebooted on `yellow` (the H713/sun50iw12p1 unit, serial `HYTY32509090328`),
2026-11-12: system UI, Settings and minitv all render in FreeSans.
