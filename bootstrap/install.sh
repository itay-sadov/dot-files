#!/usr/bin/env bash
# Bootstrap this dotfiles repo on a fresh Ubuntu 24.04 install.
# Safe to re-run: every step is idempotent.
#
# What this does NOT do (see CLAUDE.md "Not tracked" / "Hand-built tools" sections):
#   - build swayfx/libinput/etc. from source in ~/builds/
#   - set up SSH/GPG keys or git identity
#   - download bluetuith's release binary
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

link() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
        return
    fi
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        echo "backing up existing $dst -> $dst.bak"
        mv "$dst" "$dst.bak"
    fi
    ln -s "$src" "$dst"
    echo "linked $dst -> $src"
}

echo "==> Enabling tracked git hooks (pre-commit drift check)"
git -C "$REPO_DIR" config --local core.hooksPath bootstrap/git-hooks

echo "==> Installing apt packages from packages/apt-manual.txt"
sudo apt update
xargs -a packages/apt-manual.txt sudo apt install -y

echo "==> Linking whole config directories"
for d in waybar mako fuzzel wob; do
    link "$REPO_DIR/$d" "$HOME/.config/$d"
done

echo "==> Linking individual config files (dirs that also hold local-only state)"
for d in sway gtk-3.0 gtk-4.0 foot satty swaylock xdg-desktop-portal; do
    [ -d "$REPO_DIR/$d" ] || continue
    for entry in "$REPO_DIR/$d"/*; do
        [ -e "$entry" ] || continue
        link "$entry" "$HOME/.config/$d/$(basename "$entry")"
    done
done

echo "==> Linking zsh and theme"
link "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"
mkdir -p "$HOME/.themes"
link "$REPO_DIR/themes/Tokyonight-Dark" "$HOME/.themes/Tokyonight-Dark"

echo "==> Installing SwayFX login session entry (needs sudo)"
sudo install -Dm644 "$REPO_DIR/session/sway.desktop" /usr/local/share/wayland-sessions/sway.desktop

echo "==> Installing systemd-user env export for sway (needs sudo)"
sudo install -Dm644 "$REPO_DIR/etc/sway-config.d/50-systemd-user.conf" /etc/sway/config.d/50-systemd-user.conf

echo "==> Installing JetBrainsMono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
if [ -d "$FONT_DIR" ] && [ -n "$(ls -A "$FONT_DIR" 2>/dev/null)" ]; then
    echo "font already installed, skipping"
else
    mkdir -p "$FONT_DIR"
    tmp_zip="$(mktemp --suffix=.zip)"
    curl -fL -o "$tmp_zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -q -o "$tmp_zip" -d "$FONT_DIR"
    rm -f "$tmp_zip"
    fc-cache -f "$FONT_DIR"
fi

cat <<'EOF'

==> Bootstrap done. Remaining manual steps:
  1. Set up SSH keys, GPG keys, git identity/signing.
  2. Build the hand-built tools listed in CLAUDE.md under "Hand-built tools (~/builds/)"
     (swayfx needs the xwayland meson patch documented there — it is NOT applied automatically).
  3. Download the bluetuith release binary (v0.2.6) from
     https://github.com/darkhz/bluetuith/releases and place it at ~/.local/bin/bluetuith.
  4. Reboot / re-login and select "Sway" as the session in the login manager.
EOF
