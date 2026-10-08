# nura-meizu-m2381 — Nura (postmarketOS) on Meizu 20

> One line: a complete port of **Nura (postmarketOS edge + mainline Linux)** to the
> **Meizu 20 (m2381 / SM8550 / kalama)** — where the sources live, which tool builds
> which image, which partition each image flashes to, and how to roll back.
>
> 中文版：[README.md](README.md) ｜ Detailed flashing guide (docs/) is currently Chinese-only.

## Disclaimer & rescue (read before flashing)

- **Disclaimer**: this project is provided as-is. Flashing system partitions carries a
  real risk of **bricking and total data loss**; unlocking the bootloader has security
  and warranty implications. The only validated baseline is **Flyme 12.6.0.0A + slot b**;
  any other firmware version is unverified. Read [docs/FLASHING.md](docs/FLASHING.md)
  (Chinese) end to end before touching anything — you flash at your own risk, and the
  authors are not liable for any damage or data loss.
- **Bring your own rescue images**: before flashing, download the three **anchor images**
  from the Release page (`t-b2-*.img` / `esp-recovery-v4d.img` / `mu-r57-*.img`, all
  previously verified-good builds). If a flash goes wrong, re-flashing the anchors via
  fastboot gets you home in 30 seconds (recipe: FLASHING §6). **Without anchors, the only
  remaining path is EDL flashing — high risk.**
- **The anchors are NOT stock images, and flashing them does NOT return you to Flyme**:
  all three are previously-known-good builds of this project's own chain (Mu-UEFI
  firmware + ESP) — they land you on an **older Nura/pmOS**, not on Android. The stock
  layers (XBL / ABL / Flyme inside super) are never touched by this project and are not
  restored by the anchors. Returning to stock Flyme requires the official full firmware
  package and is out of scope for this project.

## Quick start

The image = **Nura (postmarketOS edge) + the plasma-mobile desktop** (built in), a
complete system out of the box: the kernel and device packages are baked into the
rootfs. Log in as `user`, password `1234` (use `sudo` with the same password for root).

**Path A: download & flash (recommended, no build needed)** — grab the three images
(boot + recovery + rootfs) and `SHA256SUMS` from the GitHub Release, gunzip the two
`.gz` files, then four commands:

```bash
sha256sum -c SHA256SUMS                 # all OK before continuing
fastboot flash boot_b      mu-r69-97cdea20.img    # Mu-UEFI firmware (device tree baked in)
fastboot flash recovery_a  esp-recovery-v53.img   # ESP = kernel boot leg (rc6 + no_console_suspend)
fastboot flash userdata    meizu-meizu20-r72.img  # rootfs (⚠ wipes all data)
fastboot set_active b && fastboot reboot
```

The plasma desktop comes up in about a minute. **From this release (r72 / rc6 kernel) sleep works
and automatic suspend is ON by default**: the device sleeps on idle at the desktop power-management
threshold and wakes on the **power button** (RTC alarm also works) — no manual setup needed.
(The culprit was an in-tree printk console-suspend regression, `console_suspend_all()`, fixed by
adding `no_console_suspend` to the kernel cmdline. Residual: ath12k resume takes ~20 s — the screen
lights up late and WiFi needs a module reload after wake; proper fix pending. **Older r66-and-earlier
kernels still need automatic suspend switched off on first boot**, see that release's notes.)

Pre-flight checklist (unlocked bootloader / Flyme baseline / anchors), step-by-step
verification, and brick recovery → **[docs/FLASHING.md](docs/FLASHING.md)** (Chinese).

**Path B: build it yourself** (to modify sources / cut a new release):

```bash
script/setup.sh                       # environment check (pins / toolchain / anchors)
script/build-kernel.sh --bump         # kernel rN+1 (tarball → checksum → build)
script/verify.sh                      # delivery-chain cross-check (dtb↔FdtBlob, etc.)
script/flash-batch.sh --i-am-present  # flash both legs (requires a human at the device)
```

Replicating the workspace elsewhere: `export NURA_WORK=/<your work root>` →
`script/setup.sh --clone` (pulls the four repos + official pmbootstrap per
`config.sh`).

> Common prerequisites for both paths: an **unlocked bootloader** (this project does not
> provide unlock methods — research that yourself) and a device on **Flyme 12.6.0.0A
> with slot b active** — the only validated baseline (exact version / official download /
> MD5 in FLASHING §1). Other Flyme versions are unverified; do not OTA blindly.

Full flashing tutorial (incl. brick recovery) → **[docs/FLASHING.md](docs/FLASHING.md)**
(Chinese). Build pipeline → [docs/PIPELINE.md](docs/PIPELINE.md) (Chinese). Boot-chain
design & image anatomy → [docs/DESIGN.md](docs/DESIGN.md) (Chinese). Current releases &
anchors → [MANIFEST.md](MANIFEST.md) (Chinese).

## Boot chain in 30 seconds

```
XBL → ABL → boot_b: Mu-UEFI (m2381Pkg) ──launches──→ mainline kernel (EFI stub/zboot)
                 ↘ recovery_a: ESP (BOOTAA64.EFI = kernel, U-Boot-style fallback)    root = /dev/sda22 (userdata, ext4)
Four independently updatable legs: boot_b = Mu image | recovery_a = ESP | apk = kernel modules | userdata = rootfs
```

- **boot_b (Mu image)**: chainloaded UEFI firmware with our device tree (FdtBlob) baked
  in. Only reflashed when the DT changes.
- **recovery_a (ESP)**: 100MiB FAT32, `\EFI\BOOT\BOOTAA64.EFI` = the kernel itself.
  Reflashed on every kernel change.
- **apk (module leg)**: kernel package = vmlinuz + /usr/lib/modules. **Flashing the ESP
  is NOT a kernel upgrade — the two legs must move in the same round.**
- **userdata (rootfs)**: the pmOS root filesystem; untouched in daily use.

Why it looks this way, and what each image contains → **[docs/DESIGN.md](docs/DESIGN.md)**
(Chinese).

## Hardware status (2026-10-07 @ r66; current state only, history in the private experiment log)

**✅ Working**
Display (120Hz OLED + backlight/auto-brightness) | touch | GPU acceleration | WiFi
dual-band incl. 5G | Bluetooth (incl. audio output) | charging (PD) + fuel gauge |
speaker playback (direct-drive path, clean audio; earpiece reserved for calls) | video
hard-decode (H.264) | four sensor classes + rotation | vibration (AW8697) | zram |
Docker containers | NCM USB network (debug channel).

**◐ Suspended (frozen battles with documented verdicts and revival paths)**
Cellular data/SMS/voice (control plane lit = world's first SM8550 pmOS cellular; stuck
at S3 RF init, **userspace removed by default**) | NFC (chip ACKs, NCI init never
completes; **userspace removed by default**) | USB-C host/docks (typec stack lit,
plug-test pending) | Waydroid.

**✗ Not working**
Recording/microphone (SWR domain bring-up, late-stage) | camera (platform open, sensor
driver not written) | fingerprint | GNSS (follows cellular) | DP alt-mode video out
(fsa4480 not populated on board — judged dead after final review) | deep sleep / MPM-AOSS
(late-stage; **plain sleep is fixed and automatic suspend enabled in the rc6/r72 working state** —
the r66 kernel of this release still needs the first-boot must-do above) | IR/UWB (identity
unconfirmed). Hardware absent: 3.5mm jack, SD slot.

> Cellular/NFC removal by default is a deliberate power/stability decision (masked by
> the device package), not a missing feature.

## Three red lines (read before touching anything)

1. **Flashing requires a human present**: all partition writes go through
   `flash-batch.sh --i-am-present` / `rollback.sh --i-am-present`.
2. **Never touch**: xbl/abl/tz/modem, dtbo_b, super, modemst1/2, persist, misc (except
   per-recipe zeroing).
3. **Two-leg rule**: a kernel change = apk (modules) + ESP (boot image) in the same
   round; flashing only one leg = a half-dead device.

## How to read the version numbers (Release filename cheat sheet)

| Mark | Example | Meaning |
|---|---|---|
| `r72` | `mu-r69-*.img`, `meizu-meizu20-r72.img.gz` | **Release round** = kernel package pkgrel, +1 per round. The three images of one round (boot / recovery / rootfs) **must be used together** — never mix rounds |
| `v53` | `esp-recovery-v53.img.gz` | **ESP version**, independent counter, +1 per kernel-leg change (no arithmetic link to r; v53 happens to pair with r72) |
| `#67` | `uname -v` on device | Kernel build number = **r + 1** (pkgrel+1 baked into the kernel). First verification point on device: seeing #67 proves the r66 kernel is really running |
| `97cdea20` | `mu-r69-97cdea20.img` | First 8 hex of the image's sha256 — anti-tamper + dd read-back comparison |

Design details and the #N law → [docs/DESIGN.md](docs/DESIGN.md) (Chinese); which
version is current → [MANIFEST.md](MANIFEST.md) (Chinese).

## Layout principles & source repositories

This repo holds only the **control plane** (scripts + docs + anchor manifest). Source
trees stay where they are, pinned by `config.sh`; the vendor blob archive
(meizu20_linux, ~29G) never enters git.

| Repo | URL | Contents | Branch |
|---|---|---|---|
| This project (control plane) | <https://github.com/RiverKawa271828/nura-meizu-m2381> | build/verify/flash scripts + version pins + docs + Release | master |
| Kernel fork | <https://github.com/RiverKawa271828/linux-mobile-ports> | fork of torvalds/linux, Meizu 20 incremental commits | meizu20-t4b |
| Mu-UEFI firmware | <https://github.com/RiverKawa271828/Mu-Silicium> | fork of Project-Silicium/Mu-Silicium, m2381Pkg | meizu20-mars-port |
| Mu Binaries | <https://github.com/RiverKawa271828/Device-Binaries> | Mu device-binaries submodule (pinned `036ba9f7`) | main |
| pmaports | <https://github.com/RiverKawa271828/pmaports> | kernel/device/firmware packages + hexagonrpcd patches | phoenix |

The toolchain is the official pmbootstrap (gitlab.postmarketos.org, pulled automatically
by `setup.sh --clone`). Replication: clone this repo → `export NURA_WORK=/<work root>` →
`script/setup.sh --clone` (pulls the four repos + pmbootstrap per `PIN_*_GIT`; anchors
via `--fetch-release`).

## Governance

- Versioning: `#N = pkgrel + 1` (check directly via `uname -v` on device); package state
  committed with every change; checksum before every build.
- Hard laws and operational discipline live in a private workspace repo's AGENTS.md
  (not public); referenced here, never duplicated.
- Project name: `nura-meizu-m2381` (lowercase kebab; machine references always use it).
