# AGENTS.md

## Repo Overview

GNU Stow-based dotfiles repo for macOS (silicon Mac) and [Omarchy](https://omarchy.org/) (Arch Linux) on an Intel Mac. Two orthogonal axes organize everything: **shared ↔ OS** is a directory (repo root vs `macos/`/`omarchy/`), and **tracked ↔ machine-local** is the repo vs `~/.dotfiles_private`. `main.zsh` is a thin orchestrator — the only platform branch is selecting `OS_DIR` (`macos`|`omarchy`) — that sources `lib/*.zsh` helpers plus `$OS_DIR/setup.zsh`, then runs a fixed pipeline: `_os_install_apps`, `_stow_shared`, `_os_stow_packages`, `_os_configure`, `_setup_agents`, `_link_zshrc`, `_setup_ssh`, `_setup_private`, `_os_finalize`. Platform behavior is behind four hooks (`_os_install_apps` / `_os_stow_packages` / `_os_configure` / `_os_finalize`) implemented in `macos/setup.zsh` and `omarchy/setup.zsh`; each self-gates on the flag it owns. Stow helpers: `_stow <pkg>` (root) and `_stow_platform <pkg>` (current `$OS_DIR`).

### Key Files
- `main.zsh` — thin orchestrator (paths + pipeline only); shell-layer counterpart is `zsh/os/<os>.zsh`
  - `--apps` — install OS packages: `Brewfile` + bun (macOS hook), or `omarchy/Pkgfile` via yay (Omarchy hook; pacman only bootstraps `yay` itself if missing)
  - `--osx` — apply macOS defaults from `macos/system/defaults.zsh` (macOS hook)
- `lib/common.zsh` — colors, `_have`, `_parse_flags`
- `lib/stow.zsh` — `_stow` (root) / `_stow_platform` (`$OS_DIR`) helpers
- `lib/shared.zsh` — OS-agnostic phases: `_stow_shared`, `_link_zshrc`, `_setup_agents` (+ `_install_skills`), `_setup_ssh`, `_setup_private`
- `macos/setup.zsh` / `omarchy/setup.zsh` — the four `_os_*` hooks per platform (`omarchy/setup.zsh` also holds `_install_omarchy_plugins`)
- `.stowrc` — global stow ignore rules (`\.DS_Store`, `^\.stow-local-ignore$`); stow reads it because `main.zsh` cd's into `$DOTS_DIR` and every call passes `-d`
- `Brewfile` — Homebrew brews and casks
- `omarchy/Pkgfile` — package list (Linux Brewfile equivalent) consumed by `main.zsh --apps`; official-repo and AUR packages can be mixed (yay resolves each name, repo packages go through pacman's backend); dev toolchains stay in mise. `tiny-dfr` (Touch Bar renderer) comes from the `arch-mact2` repo (configured in `/etc/pacman.conf`; depends on `linux-t2`, the running T2 kernel)
- `omarchy/plugins.yml` — Omarchy shell plugin manifest consumed by `omarchy/setup.zsh`'s `_install_omarchy_plugins`; each entry is a git clone into `~/.config/omarchy/plugins/<id>/` (real checkout, not stowed), with `enable: true` passing `--enable`; skipped when the plugin dir already exists. Cloning doesn't run a plugin's own `install.sh` — e.g. the `touch-bar` plugin needs `tiny-dfr` installed (`--apps`) and then its installer run once from the bar widget (installs `~/.local/bin` helpers + a user service, and needs sudo for `/etc/tiny-dfr` + the backlight udev rule). `_os_configure` covers the two things that installer omits: it adds `$USER` to the `input` group (the digitizer and backlight are group `input`; takes effect next login) and enables `tiny-dfr.service`
- `Taskfile.yml` — backup/restore tasks for Antigravity (VS Code fork), Zen browser, the 1Password allowed-browsers list (`omarchy/backups/1password/custom_allowed_browsers`), the keyd hyper-key config (`keyd:restore`), and skill updates (`task skills:update` runs `npx skills update -g`)
- `global-agent-rules.md` — shared AI agent rules, symlinked to `~/.claude/CLAUDE.md`, `~/.config/opencode/AGENTS.md`, `~/.gemini/AGENTS.md`; contains the marker-fenced `CODEGRAPH_START`/`CODEGRAPH_END` block written by `codegraph install`

### Stow Packages (managed by `main.zsh`)
Packages at repo **root** are stowed on both OSes; platform packages live under `macos/` (Darwin) or `omarchy/` (Linux) and are stowed via `_stow_platform <pkg>` (`stow -d $OS_DIR -t ~`).

**Root / common (all OSes):**
| Package | Target pattern | Notes |
|---------|---------------|-------|
| `ghostty` | `~/.config/ghostty/config` | Shared Ghostty **base** (cursor, shell-integration, CSI-u Enter binds); ends with `config-file = ~/.config/ghostty/local.conf` — platform pkgs supply `local.conf`. Includes must be `~`-absolute: ghostty resolves relative paths against the including file, and keys in a file always lose to keys from files it includes |
| `git` | `~/.config/git/config`, `~/.config/git/scripts/tidy` | Git global config; `tidy` alias runs `scripts/tidy` |
| `nvim` | `~/.config/nvim/lua/plugins/theme.lua` | Only the colorscheme is tracked; everything else is omarchy's nvim baseline (`omarchy-nvim` skel on Linux, a materialized copy on macOS) |
| `herdr` | `~/.config/herdr/config.toml` | Terminal multiplexer (kept unfolded by pre-creating `~/.config/herdr` — herdr writes logs/sockets/`session.json` beside the config); shared keymap — mac `ctrl+hjkl` pane focus + alt-chord fast path (Hyprland passes ALT through to terminals) |
| `tmux` | `~/.tmux.conf` | Tmux config |
| `zed` | `~/.config/zed/settings.json`, `~/.local/bin/zed-tmux` | Zed editor; `zed-tmux` wrapper is a package file (no separate copy step) |
| `television` | `~/.config/television/` | TUI fuzzy finder (not installed on Omarchy yet — mac-only in practice) |
| `opencode` | `~/.config/opencode/` | `opencode.jsonc` + `tui.jsonc` + `opencode-quota/quota-toast.jsonc` + on-demand `opencode-bedrock.json`; `share` disabled, codegraph MCP wired. herdr's opencode integration files (`plugins/herdr-agent-state.js`, `herdr-tui-session.js`) are NOT tracked — `lib/shared.zsh` (`_setup_agents`) runs `herdr integration install opencode` to provision them |
| `cliamp` | `~/.config/cliamp/config.toml` | Spotify TUI (cross-platform; stowed on Darwin and Linux) |
| `starship` | `~/.config/starship/starship.toml` | Shared look on both OSes: **stock preset** + suppressed python module, `command_timeout = 200`. `omarchy/setup.zsh` removes the legacy `~/.config/starship.toml` (which starship prefers over the stowed path and where omarchy's cyan preset used to live) when it matches the stowed file or omarchy's pristine |

**`macos/` (Darwin only):**
| Package | Target pattern | Notes |
|---------|---------------|-------|
| `aerospace` | `~/.aerospace.toml`, `~/.local/bin/aerospace-launch-or-focus` | Tiling window manager; launch-or-focus helper for TUI bindings (stowed from `macos/aerospace/.local/bin/aerospace-launch-or-focus`) |
| `borders` | `~/.config/borders/bordersrc` | Window border highlight (vendored binary copied to `~/.local/bin`) |
| `ghostty` | `~/.config/ghostty/local.conf`, `~/.config/ghostty/ghostty-tmux.sh` | macOS Ghostty overrides (TokyoNight Moon, font-size 14, `macos-option-as-alt`, cmd unbinds) on top of the shared base |
| `ssh` | `~/.ssh/config.d/personal.conf` | SSH config, macOS 1Password socket |
| `mise` | `~/.config/mise/config.toml` | Disables mise's python (`[settings] disable_tools = ["python"]`) to avoid shim conflicts with pyenv — the old `python = "@system"` pin is deprecated (Linux uses `omarchy/mise` for tool manifest) |

**`omarchy/` (Linux only):**
| Package | Target pattern | Notes |
|---------|---------------|-------|
| `ssh` | `~/.ssh/config.d/personal.conf`, `~/.ssh/config.d/githubs.conf` | SSH config, Linux 1Password socket; `githubs.conf` defines the `ghjlai`/`ghstellar` (github.com) and `forgejo` (git.ts.jlai.ca) host aliases for the agent |
| `uwsm` | `~/.config/uwsm/env.d/dotfiles` | Desktop-session env for Omarchy (sets `TERMINAL=ghostty`, 1Password `SSH_AUTH_SOCK`) |
| `ghostty` | `~/.config/ghostty/local.conf`, `~/.config/ghostty/overrides.conf` | `local.conf` includes omarchy's packaged default (read-only `/usr/share/omarchy/config/ghostty/config`) then `overrides.conf`; only the deviation (`font-size = 8`) is tracked — omarchy updates keep flowing |
| `hypr` | `~/.config/hypr/` | Hyprland **user overrides** (`bindings.lua`, `input.lua`, `monitors.lua`) + `~/.local/bin/omarchy-hyprland-window-quit-app`. `bindings.lua` is the mac-keyboard parity layer: a **catch-all Cmd shim** forwards every plain `SUPER+key` (letters minus Q/O, `code:10..19` digits, TAB + common symbols) as CTRL via `mac_shortcut` — global interception, silent in `terminal`-tagged windows, so web apps that check `e.ctrlKey` (Google Sheets) work; keys with compositor jobs are excluded from the loop (Q quit-app, O pop-out, C/V/X clipboard trio keeping omarchy's smart copy/paste/cut — Cmd+V→Shift+Insert in terminals, Ctrl equivalents in apps — RETURN terminal, SPACE menu, ESC system menu, BACKSPACE transparency, comma notifications, Home width-restore, PRINT picker) and Cmd+W is terminal-aware (closes the focused window when a terminal, otherwise forwards Ctrl+W tab-close, replacing omarchy's always-close-window) while Cmd+arrows are special-cased to HOME/END/PAGE keys; Cmd+Shift stays a curated list; Cmd+click (`SUPER + mouse:272`) re-emits a CTRL+click via `send_key_state` (`mouse:272`) so Zen opens the link in a new tab (plain click in terminals), replacing omarchy's SUPER+left move-window drag. New plain-SUPER compositor binds must be added to the `cmd_keys` exclusion (or keep-list), not just bound; workspace nav on ALT+digits, swap on ALT+SHIFT+hjkl; launcher re-homes live on SUPER+CTRL(+SHIFT) — releasing a chord there requires also unbinding omarchy's hidden `SUPER+CTRL` toggles (utilities.lua); window state on HYPER (`SUPER + CONTROL + ALT`, AeroSpace-style no-Shift CapsLock chord — workspace moves a/e/w/c/n/d + 1-5, L/F/S re-homes, MINUS/EQUAL resize, RETURN terminal / SHIFT+RETURN browser (omarchy's `SUPER+RETURN` / `SUPER+SHIFT+RETURN` defaults released), move-drag via `mouse:272`) with omarchy's weather/calendar/battery/time/reminders/zoom panel toggles re-homed to `SUPER+ALT` (calendar on C) and the `code:20/21` expand/shrink defaults dropped to keep Cmd+=/- shims. The entry point and templates (`hyprland.lua`, `looknfeel.lua`, `autostart.lua`, `hyprsunset.conf`, `xdph.conf`) are omarchy-owned real files on disk — NOT tracked; `hyprland.lua` requires `hypr.looknfeel`/`hypr.autostart`, so those two templates must exist. Cmd+A is flagged `{ locked = true }` so it also fires on the session-lock screen (Hyprland drops binds while locked unless they opt in) → select-all in the lock password field; and the `switch:off:Lid Switch` bind is overridden to skip `omarchy-hyprland-monitor-clamshell` while `omarchy-shell lock isLocked`, because reconciling monitors under an active lock drops the lock surface's input focus (omarchy#7811) — unlocking runs `omarchy-system-wake`, which reconciles clamshell anyway |
| `omarchy-shell` | `~/.config/omarchy/` | Omarchy shell config (`shell.json`, `hooks/post-update.d/*.hook`, `defaults/agent`, `branding/screensaver.txt`). `shell.json` `idle` is a tracked delta: screensaver 600s / lock 900s (omarchy defaults 150/300). `branding/screensaver.txt` is the custom braille screensaver art (generated from `~/Downloads/hyps0wvf4q021.png` via `omarchy transcode ascii … --mode braille --invert`); it's a stow symlink, so `omarchy branding screensaver {text,image,reset}` writes through it into the repo — commit or `git checkout` after. `omarchy branding screensaver reset` restores the stock `/usr/share/omarchy/logo.txt`. `omarchy bar …` commands (position/transparent/move/set) rewrite `shell.json` via atomic replace, which turns the stow symlink into a real file and silently diverges it from the repo — after using them, reconcile (copy the live file back, `rm` it, `stow -d omarchy -t ~ omarchy-shell`) |

| `stats` | `~/.config/omarchy/plugins/jlai.menu-stats-bar/` | A **third-party bar-widget plugin** (id `jlai.menu-stats-bar`, authored — not a clone; self-contained and marketplace-shaped: `manifest.json` carries `license`, `barWidget.defaultSection`, and a `barWidget.schema` for `intervalSec`/`historySamples`/`cpuAlertPct`/`ramAlertPct`/`diskAlertPct`/`tempAlertC`, read via `Panel.setting()`; threshold `0` disables). CPU / RAM / temp in the bar show `icon · value · micro-sparkline`; disk shows `icon · usage% · dual read/write activity bars` (read top / write bottom, one shared scale). Nerd glyphs: CPU `fa-microchip U+F2DB`, RAM `mdi-memory U+F035B`, disk `mdi-harddisk U+F02CA`, temp `fa-thermometer-three-quarters U+F2C8` (note `mdi-temperature-celsius U+F0504` renders as a bare "C" and MDI's `mdi-thermometer U+F050F` is too faint at caption size — neither is used). Each metric is tinted `bar.urgent` independently above its own threshold (defaults CPU/RAM > 80%, disk > 90%, temp > 90 °C). Left-click opens a `KeyboardPanel` popup (iStat-style, Flickable) built from `Panel`/`PanelSectionHeader`/`PanelKeyCatcher` with `Sparkline.qml` (Canvas area/bars) graphs: CPU (hero + graph + load avg + uptime + 16 per-core vertical bars with hover tooltip + top CPU procs), Memory (hero + graph + used/total + swap + cached + top RAM procs), Disk (hero + meter + used/free/mount + I/O-throughput graph + peak), Temperature (hero + graph + min/max). The popup is sized/trimmed to fit a 960-logical-tall screen without scrolling (graphs 44px, disk I/O 36px, 4 top procs). `Sampler.qml` primes an in-memory ring from the sampler's cache once (`--history`), then appends each poll; top procs refresh every 3s while open (`--top`). The sampler `bin/omarchy-bar-stats` ships **inside the plugin dir** and is resolved relatively (`Qt.resolvedUrl` → path; `Process` runs `["bash", path, …]`, no login shell, nothing in `~/.local/bin`) — it does the `/proc` math + diskstats I/O deltas and persists `~/.cache/jlai.menu-stats-bar/history.ndjson` (~10 min @ 2s, trimmed to 300); modes: default sample+append, `--history N`, `--top`. Same bash pitfalls as before (`set -e` + `read … < <(…)`, missing-file `$(<file)`). Enabled by the `{ "id": "jlai.menu-stats-bar" }` entry in `shell.json`'s center layout, right of `omarchy.weather`. Stowed with `_stow_platform stats` |
| `idle` | `~/.config/omarchy/plugins/jlai.idle/` | A `omarchy plugin clone omarchy.idle` clone (id `jlai.idle`, `clonedFrom: omarchy.idle`) that **replaces the built-in idle service**, with one change: a 1s timer polls `hyprctl cursorpos` while the screensaver window is up and dismisses it on pointer motion (`omarchy-screensaver` only exits on keyboard, so trackpad motion otherwise does nothing). Clone freezes upstream idle-service updates — re-clone/merge on significant omarchy changes (`rm -rf` the clone + `omarchy restart shell` reverts to the built-in). Stowed with `_stow_platform idle` |
| `lock` | `~/.config/omarchy/plugins/jlai.lock/` | An `omarchy plugin clone omarchy.lock` clone (id `jlai.lock`, `clonedFrom: omarchy.lock`) that **replaces the built-in lock service**, with three changes in `LockView.qml`: (1) Cmd+A / Ctrl+A → `selectAll()` in the password field — the Cmd shim can't run on the lock screen (Hyprland suppresses keybinds while a session lock is active), so the raw Meta modifier is handled in the lock's `Keys.onPressed`; (2) character-key auto-repeat is ignored (except Backspace/Delete) so a wake keypress can't flood the buffer (omarchy#7805 — the display-wake modeset stall repeats the key dozens of times); (3) mac-style Cmd+Delete/Option+Delete (delete to line start/end, delete word back/forward) — matched on **Backspace** since the Apple delete key is Backspace, forward `Delete` covers Fn+Delete. Cloning an auth service is safe: the plugin registry makes a clone inherit its source's `__hostCapabilities` (PAM config name `omarchy-lock-password` is unchanged). Freezes upstream lock updates — re-clone/merge on omarchy changes (`rm -rf` the clone + `omarchy restart shell` reverts). Stowed with `_stow_platform lock` |
| `workspaces` | `~/.config/omarchy/plugins/jlai.workspaces/` | An `omarchy plugin clone omarchy.workspaces` clone (id `jlai.workspaces`, `clonedFrom: omarchy.workspaces`) that **replaces the built-in workspaces bar widget**. Instead of the stock hardcoded `1..5` list it shows only the numbered workspaces that currently hold windows (ascending) plus the focused workspace, so empty numbered slots disappear; a named/lettered workspace (Hyprland gives them non-positive ids, e.g. `-1337`) is shown as its letter **only while focused**. Every slot renders a plain character at `Style.font.body` (uniform size); the focused slot is highlighted with a sharp-cornered filled square in `Color.accent` (theme accent, e.g. Tokyo Night `#7aa2f7`) with the character drawn in `bar.background`, plus a 2px bottom border in a `background`→`accent` blend (a tiny `colorMix` JS helper lerps the two hex values, default `Color.muted` is too faint). The character is anchored to the accent square *above* the border (button `anchors.bottomMargin: border.height`, so centering in the full slot would read ~1 logical px low) plus a calibrated optical nudge `dx: -0.5` logical px: WidgetButton centers by the font's advance metrics, but the native renderer's hinting shifts the ink ~1.5 physical px right (measured live; `TextMetrics`/`boundingRect` do NOT model it), so the label is translated so the **ink box**, not the advance box, lands on the accent square's center — residual ≤ 0.5 physical px (subpixel noise; finer values just soften the glyph). Both colors come from `Color.*` (theme-loaded) — note the widget-facing `bar` is a `PluginBarApi` facade (`injectProps` in `omarchy/plugins/bar/Bar.qml:2002`), so only the bound properties exist; theme tokens like `accent`/`muted` must come from `Color`, not `bar`. The stock widget only ever listed hardcoded `1..5`, which left the lettered case invisible. Clicking dispatches `hl.dsp.focus` by `ws.name` (works for numbered and named). Enabling the clone swaps the bar layout id in `shell.json` from `omarchy.workspaces` to `jlai.workspaces` (the shell also routes the built-in id via `clonedFrom`). Freezes upstream widget updates — re-clone/merge on omarchy changes (`rm -rf` the clone + `omarchy restart shell` reverts). Stowed with `_stow_platform workspaces` |

**Omarchy plugins** are not stowed — declared in `omarchy/plugins.yml`, `_install_omarchy_plugins` in `omarchy/setup.zsh` clones each URL into `~/.config/omarchy/plugins/<id>/` on every Linux bootstrap (skipping present dirs).
| `mise` | `~/.config/mise/config.toml` | mise tool manifest (codex/gh/node/opencode); `omarchy/setup.zsh` runs `mise install` on Linux |
| `keyd` | `/etc/keyd/default.conf` | Hyper key: hold CapsLock = Hyper (C-M-A chord, AeroSpace-style — no Shift), tap = Esc. Stowed with `sudo stow -d omarchy -t / keyd` (only package targeting `/`); `omarchy/setup.zsh` enables the unit, or run `task keyd:restore`. Hyprland bindings address the chord as `SUPER + CONTROL + ALT + <key>` |
| `fcitx5` | `~/.config/fcitx5/config` | XCompose IME (compose sequences via fcitx5); trigger keys cleared so `ctrl+space` reaches herdr's prefix instead of toggling the IME |
| `libinput` | `/etc/libinput/local-overrides.quirks` | Palm-rejection override for the built-in Apple trackpad (T2): lowers the shipped `AttrPalmSizeThreshold` (1600→1200) and sets `ModelTouchpadPhantomClicks`. **Copied** (`sudo install -Dm644`) rather than stowed — sandboxed services (`tiny-dfr.service` sets `ProtectHome=true`) can't follow a symlink into `~/.dotfiles`. CAUTION: libinput quirks are internal API — a parse error disables ALL quirks system-wide; validate with `libinput quirks list /dev/input/event6` after edits. Takes effect on next session start (libinput reads quirks at device open) |
| `t2-suspend` | `/etc/systemd/sleep.conf.d/t2-suspend.conf` | Forces **s2idle** (`[Sleep] SuspendState=freeze`) on T2 Macs, because the platform's deep (S3) resume is broken for long sleeps: the T2 rejects the stateful payload (`t2bce_core: remote rejected stateful suspend payload` / `no_state_resume`), xHCI fails to reinit (`xHC error in resume`), the Apple internal keyboard/trackpad (`05ac:0340`) are removed, and every watchdogged systemd service is killed (`Watchdog timeout (limit 3min)`) — leaving the lock screen input-dead and often forcing a reboot. `SuspendState=freeze` overrides the kernel's `mem_sleep_default=deep` (upstream Omarchy's deliberate choice, from `/etc/limine-entry-tool.d/t2-mac.conf`) at suspend time, so **no Limine/UKI edit** is needed and the setting survives Omarchy reinstalls. Root package targeting `/` via `sudo stow` (same pattern as `keyd`), gated to the T2 PCI IDs (`106b:1801/1802`) so non-T2 Linux and the Mac are unaffected; `omarchy/setup.zsh` pre-creates `/etc/systemd/sleep.conf.d` (stow folding) and runs `daemon-reload`. Verify with `systemd-analyze cat-config systemd/sleep.conf`. Trade-off: s2idle draws more battery while asleep than `deep`. Revert: `sudo rm /etc/systemd/sleep.conf.d/t2-suspend.conf && sudo systemctl daemon-reload`. Stage 2 (disable d3cold on `106b:2005`/`106b:1801` + unload/reload `brcmfmac` and `t2bce_vhci`, not `apple-bce`) only if freeze alone still fails |
| `rclone` | `~/.config/systemd/user/rclone-gdrive.service` | Google Drive FUSE mount at `~/Google Drive` via systemd user unit; `omarchy/setup.zsh` enables it when the `gdrive:` remote exists (`--poll-interval 15m`, vfs cache full 20G). The OAuth token in `~/.config/rclone/rclone.conf` is a secret — never commit it. rclone's **shared** Google client_id is being retired in 2026 — set up a private client_id (`rclone config create gdrive drive client_id=... client_secret=...`) before it stops working |
| `wayvnc` | `~/.config/wayvnc/config`, `~/.config/systemd/user/wayvnc.service` | VNC server for the Hyprland session (`wayvnc`, Arch `extra`). Binds **only the Tailscale IP** (`address=100.89.42.8:5900`) with **PAM auth** (`enable_pam=true`; the package ships `/etc/pam.d/wayvnc`) — so there is no stored secret and no TLS cert (WireGuard encrypts the transport). The user unit runs `wayvnc -r` (`-r` overlays the cursor; Hyprland's screencopy omits it), `After`/`PartOf=graphical-session.target`, inheriting `WAYLAND_DISPLAY` from the systemd user env (omarchy imports it at `hyprland.start`). `omarchy/setup.zsh` pre-creates `~/.config/wayvnc` (prevents stow folding) and enables the unit. **Requires** `sudo ufw allow in on tailscale0 to any port 5900 proto tcp` (ufw is active; the tailnet bind bypasses LAN but ufw's default policy still applies). Connect from the tailnet, e.g. TigerVNC viewer → `100.89.42.8::5900`, auth = Linux password. If the Tailscale node IP changes, update `address`. Serves the first output (`eDP-1`); switch with `wayvncctl output-set` |

### Platform gating
`main.zsh` sets `OS="$(uname -s)"` and derives `OS_DIR` (`macos`|`omarchy`) — the only OS branch in the file. Root packages (common) are stowed on both OSes via `_stow`. macOS content (`macos/aerospace`, `macos/borders` + vendored binary, `macos/ghostty`, `macos/mise`, `macos/ssh`, `macos/system/` desktoppr + `--osx`, `--apps`/brew) lives in `macos/setup.zsh`; Linux content (`omarchy/uwsm`, `omarchy/hypr`, `omarchy/omarchy-shell`, `omarchy/idle`, `omarchy/lock`, `omarchy/workspaces`, `omarchy/stats`, `omarchy/fcitx5`, `omarchy/rclone`, `omarchy/wayvnc`, plus `omarchy/keyd` / `omarchy/libinput` (the keyd config is stowed to `/`, the libinput quirk is copied to `/etc`), and `--apps`) lives in `omarchy/setup.zsh`. Packages present on both platforms (`ghostty`, `mise`, `ssh`) are stowed from each `$OS_DIR/setup.zsh` via `_stow_platform` — no `_stow_platform` call lives in `lib/`. The `macos/ssh` and `omarchy/ssh` packages differ by the 1Password agent socket path (and `omarchy/ssh` adds the `githubs.conf` host aliases). The shell layer mirrors this: shared `zsh/*.zsh` plus **one OS file per OS** (`zsh/os/darwin.zsh` / `zsh/os/linux.zsh`) that each shared module sources when present — no platform `case`/`if` remains in the shared shell files. `lib/shared.zsh` pre-creates `~/.config/ghostty`, `~/.config/cliamp`, `~/.config/herdr`, `~/.local/bin`, and `~/.ssh` so stow never folds those dirs into the repo.

### Maintenance philosophy — track deviations only
Files identical to (or pure comment-templates of) upstream defaults are NOT tracked. Pristine references on Omarchy:
- `/usr/share/omarchy/config/<app>/` — user-config templates omarchy installs to `~/.config/` (e.g. `hypr/`, `ghostty/`)
- `/usr/share/omarchy/default/hypr/` — the hypr lua module library loaded via `require("default.hypr.*")`
- `/etc/skel/.config/nvim/` — omarchy-nvim's nvim baseline
Before editing a config that omarchy owns, diff against the pristine copy; only keep the delta in this repo. Watch out when comparing: `diff | head` hides diff's exit code, and stow-created symlinks make "the same file" mean "the repo file" — check `readlink` before `rm`.

### SSH host aliases (git `insteadOf` shortcuts)
`git/.config/git/config` defines `gh:`/`ghjlai:`/`ghstellar:`/`forgejo:` URL rewrites. `omarchy/ssh/.ssh/config.d/githubs.conf` provides the matching host aliases on Linux (1Password agent socket); the macOS side's aliases come from `~/.dotfiles_private/ssh/.ssh/config.privated/jlai.conf`. On Linux, `config.d/*.conf` is included before `config.privated/*.conf`, so the agent socket here overrides the macOS socket in the private config.

### Omarchy / zsh
On Omarchy (Arch Linux), zsh is the user shell (not bash). `omarchy/setup.zsh:_os_configure` makes it so: `_ensure_login_shell` sets the login shell (`sudo chsh -s /usr/bin/zsh`, idempotent via `getent passwd`), and `_ensure_omarchy_zshrc` prepends the omarchy-zsh base (`shell/zoptions` → compinit + `HISTFILE`/`HISTSIZE`; `shell/all` → envs/aliases/functions/inits) to `~/.zshrc` behind a `# omarchy-zsh base (managed by dotfiles)` marker. It's done here rather than via `omarchy-setup-zsh` because that also clobbers `~/.inputrc` (a stow symlink) and `~/.bashrc`. `--apps` installs `omarchy-zsh` plus zsh plugins and shared tools. The canonical source chain: Omarchy's shared config (`omarchy-zsh`) → our `zsh/*.zsh` modules → tool inits. Platform values for the shell live in `zsh/os/linux.zsh` (macOS: `zsh/os/darwin.zsh`); each shared module sources its OS file if present, and a `DOTFILES_OS` guard makes the body run once per shell. `typeset -U PATH` keeps prepends deduped across re-sources and nested shells. `zsh/overrides.zsh` re-runs Omarchy's `tsl`/`hsl` swarm functions under `emulate -L bash` so their 0-based array indexing survives zsh's 1-based arrays; no-op on macOS. Desktop env for the Hyprland session lives in `omarchy/uwsm/.config/uwsm/env.d/dotfiles` (sourced by uwsm, not the shell rc).

### Non-stowed Configs (backup/restore via `Taskfile.yml` or manual)
- `macos/backups/antigravity/` — VS Code fork settings, keybindings, extensions
- `macos/backups/zen/` + `omarchy/backups/zen/` — Zen browser themes, keyboard shortcuts, containers (per-OS copies; `zen:backup`/`zen:restore` pick the dir via `uname`)
- `omarchy/backups/1password/` — 1Password allowed-browsers list (`custom_allowed_browsers`); restored to `/etc/1password/` via `task 1password:restore` (Zen desktop integration)
- `macos/system/` — macOS system defaults (Dock, trackpad, keyboard, login items) + `wallpaper/tokyo-night.jpg`
- `macos/backups/raycast/` — Raycast scripts
- `macos/backups/stats-menu/` — Stats.app menu bar plist

### Skills
Defined in `skills/skills.yml` — single source of truth for install + linking.
`lib/shared.zsh` (`_install_skills`) nukes all installed skills and reinstalls from config (idempotent).
Only `skills/personal/` (code-like-joey) lives in-repo — symlinked to agent dirs.

**Zsh array note**: The `npx skills add` call in `main.zsh` uses zsh arrays (`agent_flags=()`, `skill_flags=()`) with `"${arr[@]}"` expansion — never string concatenation. Zsh does not word-split unquoted variables, so `$skill_flags $agent_flags` would pass everything as a single arg. Related pitfall: an **unquoted** `$(...)` nested inside `${(...)}` (e.g. `${(f)$(grep ...)}`) has its lines joined with the first IFS char *before* the flag applies, collapsing everything into one element — always quote the substitution: `${(f)"$(...)"}`. (This silently broke `omarchy/Pkgfile` package parsing; `omarchy/setup.zsh:_os_install_apps` now uses the quoted form.)

### CodeGraph
- CLI installed via standalone bundle (`~/.codegraph/` + `~/.local/bin/codegraph`); `lib/shared.zsh` (`_setup_agents`) installs it if missing and runs `codegraph install --target=opencode --location=global --yes` to wire the MCP server
- opencode MCP entry (`mcp.codegraph`) is committed in `opencode/.config/opencode/opencode.jsonc` (codegraph is jsonc-aware); `lib/shared.zsh` (`_setup_agents`) does `rm -f ~/.config/opencode/opencode.json{,c}` before `_stow opencode` because `codegraph install` replaces the stow symlink with a real file
- The `CODEGRAPH_START`/`CODEGRAPH_END` block in `global-agent-rules.md` is maintained by `codegraph install` — keep it in sync if rerunning the installer
- Index projects with `codegraph init` (creates `.codegraph/`); upgrade CLI with `codegraph upgrade`
- Only opencode is wired (not Claude/Gemini MCP)

### Private Dotfiles (`~/.dotfiles_private`)
Optional companion repo at `../.dotfiles_private` (sibling directory). If present, `main.zsh` (`_setup_private`) will:
- Stow its `ssh/` package (additional SSH configs)
- Run its `main.zsh` if it exists

`zsh/sources.zsh` also conditionally sources `~/.dotfiles_private/zsh/private.zsh`.

The private `main.zsh` also runs `_ensure_home_route` (macOS, home LAN only): a static
`192.168.20.0/24 → 192.168.10.1` route so NordLayer's default route (utun5) can't swallow the
`*.ts.jlai.ca` service subnet. Idempotent; self-gates via `en0`'s IP prefix.

Never commit private dotfiles content to this repo.

## Build/Test Commands
- Run setup: `./main.zsh` (base), `./main.zsh --apps` (install OS packages), `./main.zsh --osx` (macOS defaults), `./main.zsh --skills` (reinstall skills from `skills.yml` only — nukes and reinstalls all installed skills, no other bootstrap steps)
- Verify symlinks: `ls -la ~ | grep -E '\.dotfiles'`
- Dry-run stow (no changes): `stow -nv -t /tmp/stowtest <pkg>` for root packages, or `stow -nv -d macos -t /tmp/stowtest <pkg>` / `stow -nv -d omarchy -t /tmp/stowtest <pkg>` for platform packages
- Verify skills: `npx skills list -g`
- Update skills: `npx skills update -g` or `task skills:update`
- Verify codegraph: `codegraph --version` and `codegraph install --print-config opencode`
- Check a config against omarchy's pristine default: `diff /usr/share/omarchy/config/<app>/<file> <repo copy>` (full file, never `| head` — it swallows diff's exit code)
- Backup before testing: `cp ~/.zshrc ~/.zshrc.backup`
- Backup Antigravity: `task antigravity:backup`
- Backup Zen: `task zen:backup`

## Code Style Guidelines

### Shell Scripts (Zsh) — Modular Structure
**Bootstrap scripts** (run by `main.zsh`):
- `lib/common.zsh`: colors, `_have`, `_parse_flags`
- `lib/stow.zsh`: `_stow` (root) / `_stow_platform` (`$OS_DIR`)
- `lib/shared.zsh`: OS-agnostic phases (`_stow_shared`, `_link_zshrc`, `_setup_agents`, `_setup_ssh`, `_setup_private`)
- `macos/setup.zsh` / `omarchy/setup.zsh`: the four `_os_*` hooks — OS-specific bootstrap behavior goes here, never in `main.zsh` or `lib/`

**Shell modules** (sourced by `~/.zshrc`):
- `zsh/os/darwin.zsh` / `zsh/os/linux.zsh`: the only OS-aware shell files — platform `PATH`, `SSH_AUTH_SOCK`, `HOMEBREW_PREFIX`, `NVM_SH`/`NVM_COMPLETION`, `ZSH_PLUGIN_DIRS`, and mac-only aliases; sourced-if-present by `aliases/exports/sources` (guarded by `DOTFILES_OS`, so it runs once per shell)
- `zsh/exports.zsh`: Environment variables, PATH, tool initialization
- `zsh/aliases.zsh`: Command aliases and utility functions
- `zsh/sources.zsh`: Plugin sourcing (zsh-autosuggestions, syntax-highlighting)
- `zsh/hooks.zsh`: Zsh hooks (auto-ls, git auto-pull, lazy mise activation)
- `zsh/keys.zsh`: Key bindings (alt-arrow word motion, etc.)
- `zsh/overrides.zsh`: zsh-compat wrappers for Omarchy's bash-indexed `tsl`/`hsl` (via `emulate -L bash`)
- `zsh/op.zsh`: 1Password-backed secrets. `_op_env <VAR> <op://ref> [ttl] [account]` reads from the macOS Keychain (silent, encrypted) and bootstraps from 1Password when absent, storing under service name `dotfiles/cache/op_env/<VAR>`; `op-env-reset <VAR>` (or `--all`) deletes cached entries to force a re-read. `account` (sign-in address/ID) selects the 1Password account — required when multiple are signed in, or op uses its default and prompts each call; `op read` errors are no longer swallowed so a misconfigured account is visible. Uses `command grep` to bypass the `grep='rg'` alias. Consumers resolve lazily, not at shell startup: `zsh/aliases.zsh` defines a `cliamp()` wrapper that calls `_op_env SPOTIFY_CLIENT_ID 'op://Private/spotify keys/client_id' 86400 my.1password.ca` on launch (the item lives in the personal account, while op would otherwise default to the work account).
- Use snake_case for function names
- Define color constants at file top (RED, GREEN, etc.)
- Check file existence before modifications
- Use echo with color codes for user feedback
- Create backups before overwriting files
- Use lazy loading for heavy tools (NVM, pyenv): keep the cheap shim PATH prepend eager, defer the expensive init (`load-nvm` / `load-pyenv` + `nvm()` / `pyenv()` wrappers) to first use
- Maintain alphabetical ordering within sections
- Shared `zsh/*.zsh` modules must not branch on OS — platform-specific shell config belongs in `zsh/os/<os>.zsh`; platform-specific bootstrap behavior belongs in `$OS_DIR/setup.zsh`

### Lua (Neovim configs)
- Use local variable declarations
- Follow LazyVim plugin specification format
- Use table.extend for config merging
- Minimal comments, only when necessary
- Maintain lazy-lock.json for plugin versions

### General
- No trailing whitespace
- Consistent indentation (2 spaces for Lua, tabs for shell)
- Test in isolated environment before committing

