# dot-files

Personal dotfiles for a SwayFX + zsh desktop setup on Ubuntu 24.04. Live configs are symlinked to this repo — edit here, not `~/.config/` directly.

## Structure
- `sway/` — SwayFX compositor config
- `waybar/` — status bar (top, Tokyo Night theme)
- `foot/` — terminal emulator
- `fuzzel/` — application launcher
- `zsh/` — zsh config (`.zshrc`)
- `gtk-3.0/`, `gtk-4.0/` — GTK user CSS overrides (Tokyonight-Dark) + libadwaita
- `themes/Tokyonight-Dark/` — full GTK/Cinnamon/etc. theme; symlinked to `~/.themes/Tokyonight-Dark`
- `mako/` — notification daemon
- `wob/` — Wayland overlay bar (`wob.ini`); on-screen volume level bar. Fed by `sway/volume-notify.sh` through a fifo that a `wob` process (started via `exec_always` in `sway/config`) tails. Volume media keys call the script instead of `wpctl` directly. `wob` is an apt package.
- `satty/` — screenshot annotation tool
- `swaylock/` — lock screen config
- `xdg-desktop-portal/` — portal routing (`portals.conf`, currently routes FileChooser to `xdg-desktop-portal-gtk`)
- `session/` — SwayFX login-session desktop entry (see System-level files below)
- `etc/sway-config.d/` — tracked copy of `/etc/sway/config.d/50-systemd-user.conf` (see System-level files below)
- `packages/apt-manual.txt` — `apt-mark showmanual` snapshot for rebuilding package selection on a new machine

## Maintenance contract (keep the repo rebuildable)
Every change to this repo must leave it self-consistent, so `bootstrap/install.sh` on a fresh machine reproduces the current setup. After **any** change, before finishing:
1. **Add/remove a config dir** → wire it into `bootstrap/install.sh` (whole-dir list or per-file list) *and* document it in this file's Structure/Workflow sections. Removing one → drop it from both, and `git rm` the tracked dir + remove the stale `~/.config` symlink.
2. **Add a script under `sway/`** → also add its per-file symlink to `install.sh` (see the `sway/` note below).
3. **Install/remove an apt package you rely on** → regenerate the snapshot: `apt-mark showmanual | sort > packages/apt-manual.txt`.
4. **New system-level file** (needs sudo / lives outside `~/.config`) → track its content in-repo and add a `sudo install` step to `install.sh`.

This is enforced, not just documented:
- `bootstrap/check-drift.sh` — verifies every config dir is both symlinked by `install.sh` and mentioned here, flags dirs `install.sh` links but that no longer exist, and warns if the apt snapshot is stale. Run it anytime.
- **Stop hook** (`bootstrap/stop-hook.sh`, wired in `.claude/settings.json`) — runs the checker at the end of a Claude Code turn; on drift it blocks and feeds the report back so it gets fixed before finishing. It only fires for turns that actually wrote to this repo (a `Write`/`Edit` under the repo root, per the transcript) — a read-only or purely conversational turn is never hijacked into fixing pre-existing drift. Writes made only through `Bash` heredocs slip past that gate; the pre-commit hook is the hard backstop.
- **pre-commit hook** (`bootstrap/git-hooks/pre-commit`, enabled via `core.hooksPath` by `install.sh`) — hard-fails a commit that leaves the repo inconsistent.

## Workflow
- Live configs in `~/.config/` are symlinked to this repo, but **per-file, not always per-directory**: most tools (`waybar`, `mako`, `fuzzel`, `wob`) have their whole `~/.config/<tool>` directory symlinked to the repo. `foot` and `gtk-3.0` symlink only the individual config file (`foot.ini`, `settings.ini`) because the live directory also holds local-only files that must NOT be tracked (`~/.config/gtk-3.0/bookmarks` — GTK file-chooser bookmarks; `~/.config/foot/foot.bak_*` — disposable local backups). Don't "fix" these into whole-directory symlinks — it would pull machine-local state into the repo.
- `sway/` is symlinked **per-file** (`~/.config/sway/config`, `touchpad-auto.sh`, `volume-notify.sh`), not whole-directory. Adding a new script under `sway/` means it also needs its own symlink into `~/.config/sway/` — a `bindsym`/`exec` referencing `~/.config/sway/<script>` silently no-ops if that symlink is missing.
- Exception: `zsh/.zshrc` is symlinked from `~/.zshrc`
- Exception: `themes/Tokyonight-Dark/` is symlinked from `~/.themes/Tokyonight-Dark`
- Portal file picker: the repo used to route through a hand-built `xdg-desktop-portal-termfilechooser` (yazi-in-a-terminal picker). It was replaced by the stock `xdg-desktop-portal-gtk` apt package (see git history of `xdg-desktop-portal/`). The termfilechooser source is still in `~/builds/` but its systemd service is inactive/unused — don't reactivate config for it without re-checking whether that migration should be reverted.

## System-level files (outside `~/.config`, not auto-symlinked)
These require root/sudo to install and can't be symlinked in place the normal way, so their content is tracked in-repo and must be manually (re)installed on a new machine — `bootstrap/install.sh` does this:
- `session/sway.desktop` → install to `/usr/local/share/wayland-sessions/sway.desktop`. Registers "Sway" as a login-manager session; without it GDM only offers GNOME. Installed by the swayfx build process originally, but not reproduced by a plain `ninja install` on a rebuild unless this file is placed manually.
- `etc/sway-config.d/50-systemd-user.conf` → install to `/etc/sway/config.d/50-systemd-user.conf`. Exports `DISPLAY`/`WAYLAND_DISPLAY`/`SWAYSOCK` into the systemd user session. The apt `sway` package used to ship this; SwayFX built from source does not. **Without it, `xdg-desktop-portal-gtk` can't reach the compositor and waybar hangs ~25s on startup then never renders** (see swayfx notes below). `sway/config` has a commented-out `dbus-update-activation-environment` fallback for the case where this file is missing — prefer installing the real file over uncommenting that line.

## Fonts
`JetBrainsMono Nerd Font` (used by `foot`, `fuzzel`, `waybar`) is **not** apt-installed — it's manually unpacked under `~/.local/share/fonts/JetBrainsMonoNerd/`. On a new machine: download the `JetBrainsMono` archive from the [Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases), unzip into `~/.local/share/fonts/JetBrainsMonoNerd/`, then run `fc-cache -f`. `bootstrap/install.sh` automates this.

## Package list
`packages/apt-manual.txt` is a snapshot of `apt-mark showmanual` (Ubuntu 24.04). Regenerate with:
```bash
apt-mark showmanual | sort > packages/apt-manual.txt
```
`bootstrap/install.sh` installs from this list on a fresh machine. It does not capture PPAs/third-party apt sources if any are added later — check `/etc/apt/sources.list.d/` separately if package installs start failing.

## Hand-built tools (`~/builds/`)
Each is a real git clone pinned to a specific ref — `cd ~/builds/<tool> && git log -1` to confirm the exact commit if these drift.

- **swayfx** — https://github.com/WillPower3309/swayfx, tag `0.5.3`. Build: `meson setup build --prefix=/usr/local && ninja -C build && sudo ninja -C build install`. **Local patch required beyond upstream:** in `meson.build`, `wlroots_features['xwayland']` must be flipped from `false` to `true`, and `subprojects/wlroots` rebuilt standalone first (`cd subprojects/wlroots && meson setup build --prefix=/usr/local && ninja -C build && sudo ninja -C build install`) before rebuilding swayfx — otherwise XWayland apps (e.g. Chrome) fail to launch. This patch is not committed anywhere (working tree only) — reapply it after a fresh clone. Also needs `sudo apt install libxcb-icccm4-dev libxcb-composite0-dev libxcb-res0-dev libxcb-render-util0-dev libxcb-ewmh-dev` for the xwayland build, and `sudo apt install swaybg` separately (the apt `sway` package used to pull it in as a dependency; building from source doesn't). See "System-level files" above for the two other post-install fixes this build needs (session file, systemd-user.conf).
- **libinput** — https://gitlab.freedesktop.org/libinput/libinput.git, tag `1.26.0`. Standard meson build.
- **xdg-desktop-portal-termfilechooser** — https://github.com/GermainZ/xdg-desktop-portal-termfilechooser.git. **Currently unused/dormant** (see Workflow section) — kept around in case the yazi-based file picker is revived. Meson build if needed.
- **Tokyonight-GTK-Theme** — https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme.git. Source of the vendored `themes/Tokyonight-Dark/` theme (already committed to this repo — this build dir is only needed if regenerating from the theme's install script).
- **zsh-claudecode-completion** — https://github.com/wbingli/zsh-claudecode-completion. Zsh completions for the Claude Code CLI, sourced from `.zshrc`.
- **bluetuith** — https://github.com/darkhz/bluetuith. **Not built from source** — `~/builds/bluetuith/bluetuith` is a prebuilt release binary (v0.2.6), copied/symlinked to `~/.local/bin/bluetuith`. On a new machine, just download the matching release binary instead of cloning+building.

## Not tracked (deliberately manual)
- SSH keys, GPG keys, git commit identity/signing config — set these up by hand on a new machine, never commit them here.
