# dot-files

Personal dotfiles for a SwayFX + zsh desktop setup. Live configs are symlinked to this repo — edit here, not `~/.config/` directly.

## Structure
- `sway/` — SwayFX compositor config
- `waybar/` — status bar (top, Tokyo Night theme)
- `foot/` — terminal emulator
- `fuzzel/` — application launcher
- `zsh/` — zsh config (`.zshrc`)
- `gtk-3.0/`, `gtk-4.0/` — GTK theme settings + libadwaita dark fix
- `mako/` — notification daemon
- `zathura/` — PDF viewer
- `starship.toml` — prompt (unused, replaced by custom agnoster in zsh)
- `discocss/` — Discord CSS customization

## Workflow
- All live configs in `~/.config/` are symlinked to this repo
- Exception: `zsh/.zshrc` is symlinked from `~/.zshrc`
