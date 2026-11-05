# Leviathan Firmware

Custom FriendlyWrt (OpenWrt 25.12) firmware for the **P01yg107 Labs Leviathan** —
a dual-radio routing + auditing platform on the **FriendlyELEC NanoPi R28S** (RK3528A).

> Authorized security testing and education only.

Built from [friendlyarm/Actions-FriendlyWrt](https://github.com/friendlyarm/Actions-FriendlyWrt),
trimmed to the R28S (`rk3528`) target and layered with a Leviathan overlay.

---

## What this produces

A single flashable image: `Leviathan-<version>-R28S.img.gz`, plus a `.sha256`.

It is stock FriendlyWrt 25.12 for the R28S, with:

- **Auditing tools baked in** — `aircrack-ng`, `hcxdumptool`, `hcxtools`, `reaver`,
  `tcpdump`, `nmap`, `iw-full`, `usbutils`, `pciutils`.
- **AR9271 (`ath9k_htc`) support** — the firmware package (`ath9k-htc-firmware`) is
  included and the module auto-loads. The driver itself is already in FriendlyELEC's
  kernel (`CONFIG_ATH9K_HTC=m`); `scripts/custome_kernel_config.sh` re-asserts it.
- **First-boot identity** (`/etc/uci-defaults/zz-leviathan`, runs once):
  - hostname `leviathan`, timezone America/New_York
  - LAN moved to **192.168.42.1** (avoids colliding with a typical 192.168.x upstream)
  - onboard Wi-Fi 6 → AP `LEVIATHAN-<mac>`, WPA2, key `leviathan`
  - root password `leviathan`
  - Argon LuCI theme
- **Two helper commands**:
  - `leviathan-uplink <ssid> <key> [psk2|sae|sae-mixed]` — join an upstream Wi-Fi
    network as a client on the onboard radio while the AP keeps serving. `status`
    and `off` subcommands too.
  - `leviathan-mon up [channel]` — bring the AR9271 up as `mon0` (monitor mode) for
    auditing, without touching the onboard AP. `down` / `status` too.
- **Leviathan login banner.**

> **Change the root and AP passwords before field use.** The baked-in defaults exist
> so a freshly flashed board is reachable; they are not secrets.

---

## Build it (GitHub Actions — recommended)

1. Push this repo to `github.com/p0lygl07/leviathan-firmware`.
2. **Actions** tab → **Build Leviathan** → **Run workflow** → enter a version
   (e.g. `v0.1.0`).
3. Wait for the build (~1.5–2.5 h on a free runner).
4. Download `Leviathan-v0.1.0-R28S.img.gz` from the **Releases** page.

The workflow builds **only** rk3528 / 25.12 / non-docker — one image, not the full
upstream matrix — to keep runner time down.

### Flash

Verify, then write with balenaEtcher (takes the `.img.gz` directly) or `dd`:

```bash
sha256sum -c Leviathan-v0.1.0-R28S.img.gz.sha256
# dd (double-check the device!):
gunzip -c Leviathan-v0.1.0-R28S.img.gz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

First boot takes ~90 s (filesystem expand). Then join `LEVIATHAN-xxxx` (key
`leviathan`) and browse to **http://192.168.42.1** or `ssh root@192.168.42.1`.

---

## Repo layout

```
.github/workflows/build-leviathan.yml   CI build (rk3528 / 25.12 only)
scripts/
  custome_config.sh                      adds leviathan/config/99-leviathan to .config
  custome_kernel_config.sh               re-asserts ATH9K_HTC=m (+ upstream CT options)
leviathan/
  config/99-leviathan                    package selection (appended to .config)
  overlay/
    install.sh                           FRIENDLYWRT_FILES installer (runs at image assembly)
    files/
      etc/banner                         Leviathan login banner
      etc/modules.d/11-ath9k-htc         autoload ath9k_htc
      etc/uci-defaults/zz-leviathan      first-boot identity (hostname/LAN/AP/pw)
      usr/sbin/leviathan-uplink          AP+STA concurrent uplink helper
      usr/sbin/leviathan-mon             AR9271 monitor-mode helper
UPSTREAM_README.md                       original FriendlyELEC readme
```

### How the overlay hooks in

- `custome_config.sh` runs in the package-build job and drops `99-leviathan` into
  `configs/rockchip/`, which FriendlyWrt concatenates into `.config`, pulling the
  auditing packages into the build.
- The image job appends `FRIENDLYWRT_FILES+=(leviathan/overlay)` to
  `.current_config.mk`. FriendlyELEC's `mk-friendlywrt.sh` then runs
  `leviathan/overlay/install.sh` against the rootfs during `build.sh sd-img`, which
  rsyncs `files/` in and stamps the version into the banner.

---

## Roadmap

- **v0.1** (this): tools + AR9271 support + branding, stock dual-GbE routing.
- **v0.2**: ship the AR9271 hardware-mod guide (U.FL on J2, external antenna,
  internal USB wiring) alongside the firmware; add a `leviathan-mon` channel-hop mode.
- **v0.3**: PETG-CF enclosure released with the firmware as the product bundle.
