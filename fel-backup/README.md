# Full eMMC backup over USB (FEL)

Do this before anything else. Reads only, writes nothing to the projector.

## Needs

- USB A-to-A cable to the projector's USB port.
- Better: the same cable with the red (VBUS, pin 1) wire cut, and the projector on its own
  power supply. Without that, the PC's USB port powers the projector and FEL drops out
  mid-transfer. With it, every session worked on the first try.
- `sunxi-fel` and `u-boot-installer.bin` from
  [well0nez/allwinner-h713-linux releases](https://github.com/well0nez/allwinner-h713-linux/releases)
  (tested: v0.95-beta). Mainline `sunxi-tools` is not enough for the H713.

```sh
BASE=https://github.com/well0nez/allwinner-h713-linux/releases/download/v0.95-beta
curl -LO "$BASE/sunxi-fel" -LO "$BASE/u-boot-installer.bin"
chmod +x sunxi-fel
```

## Steps

1. Stop any automounter first (udisks, devmon, ...). It may mount the ext4 partitions
   read-write while you copy them.
2. FEL mode: unplug power, hold the reset button, plug power in, keep holding ~2 s,
   release. The projector stays dark. `lsusb` shows `1f3a:efe8`.
3. Load U-Boot into RAM. It exposes the eMMC as a USB drive:
   ```sh
   sudo ./sunxi-fel uboot u-boot-installer.bin
   ```
4. Wait until a ~7.3 GiB disk with 26 partitions appears (`lsblk`). It can take more than
   20 s. Then:
   ```sh
   ./backup.sh /dev/sdX emmc-1.img
   ```
5. Power cycle. Repeat steps 2-4 into `emmc-2.img`, then compare:
   ```sh
   cmp emmc-1.img emmc-2.img && echo identical
   ```
   Only trust the backup if the two passes are identical.

A plain power cycle always gets the projector out of FEL. Nothing is written unless you
write it.

## Keep the dump private

It contains your serial number and HDCP keys. Never publish it. Make it immutable so even
`sudo` cannot overwrite it by accident:

```sh
sudo chattr +i emmc-1.img emmc-2.img
```

## Never overwrite

| Region | Where | Contains |
|---|---|---|
| Secure storage | LBA 12288, 2048 sectors, outside the GPT | serial number, HDCP keys |
| `Reserve0_a` | GPT partition 24 | per-unit panel and color calibration |
| `frp` | GPT partition 17 | factory reset protection state |

These exist only on your unit and cannot be recreated. Losing the HDCP keys permanently
breaks HDCP-protected HDMI input.
