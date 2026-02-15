# dot-files

Personal dotfiles for a SwayFX + zsh desktop setup. Live configs are symlinked to this repo — edit here, not `~/.config/` directly.

## Structure
- `sway/` — SwayFX compositor config
- `waybar/` — status bar (top, Tokyo Night theme)
- `foot/` — terminal emulator
- `fuzzel/` — application launcher
- `zsh/` — zsh config (`.zshrc`)
- `gtk-3.0/`, `gtk-4.0/` — GTK theme (Tokyonight-Dark) + libadwaita
- `mako/` — notification daemon
- `satty/` — screenshot annotation tool
- `yazi/` — terminal file manager (Tokyo Night flavor)
- `xdg-desktop-portal/` — portal routing (termfilechooser for file picker)
- `xdg-desktop-portal-termfilechooser/` — yazi-based file picker wrapper

## Workflow
- All live configs in `~/.config/` are symlinked to this repo
- Exception: `zsh/.zshrc` is symlinked from `~/.zshrc`
- System tools built from source live in `~/builds/` (swayfx, libinput, yazi, xdg-desktop-portal-termfilechooser)
