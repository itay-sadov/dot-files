#!/usr/bin/env bash
# Drift checker for this dotfiles repo.
#
# Guards the failure mode that hit `wob` and `yazi`: a config directory added to
# or removed from the repo without updating install.sh's symlink lists and
# CLAUDE.md. Run by the git pre-commit hook (hard gate) and the Claude Code Stop
# hook (feeds a report back to the agent so it self-corrects before finishing).
#
# Exit 0 = clean. Exit 1 = hard drift (must fix). Warnings never fail on their own.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

INSTALL="bootstrap/install.sh"
CLAUDE="CLAUDE.md"
APT_SNAPSHOT="packages/apt-manual.txt"

# Top-level entries that are NOT ~/.config config directories.
# (bootstrap=scripts, packages=apt list, session/etc=system files, themes=~/.themes,
#  zsh=~/.zshrc, .claude/.git=tooling.)
NON_CONFIG="bootstrap packages session etc themes zsh .claude .git"

errors=0
warns=0
err()  { errors=$((errors+1)); printf 'DRIFT: %s\n' "$1"; }
warn() { warns=$((warns+1));  printf 'warn:  %s\n' "$1"; }

# Directories install.sh actually symlinks (union of its two `for d in ...` lists).
linked_dirs="$(grep -hoE 'for d in [^;]*' "$INSTALL" | sed 's/for d in //' | tr '\n' ' ')"
is_linked() { case " $linked_dirs " in *" $1 "*) return 0;; *) return 1;; esac; }

for d in */; do
    d="${d%/}"
    case " $NON_CONFIG " in *" $d "*) continue;; esac
    is_linked "$d"       || err "config dir '$d/' is not symlinked by $INSTALL (add it to a 'for d in ...' list)"
    grep -qF "$d" "$CLAUDE" || err "config dir '$d/' is not documented in $CLAUDE"
done

# Reverse: a name listed in install.sh but no longer present in the repo.
for d in $linked_dirs; do
    [ -d "$d" ] || err "$INSTALL links '$d' but that directory no longer exists in the repo"
done

# apt snapshot freshness (warning only — other machines legitimately differ).
if command -v apt-mark >/dev/null 2>&1; then
    if ! diff -q <(apt-mark showmanual 2>/dev/null | sort) "$APT_SNAPSHOT" >/dev/null 2>&1; then
        warn "$APT_SNAPSHOT differs from 'apt-mark showmanual' — regenerate with: apt-mark showmanual | sort > $APT_SNAPSHOT"
    fi
fi

if [ "$errors" -gt 0 ]; then
    printf '\n%d drift issue(s), %d warning(s).\n' "$errors" "$warns"
    exit 1
fi
[ "$warns" -gt 0 ] && printf '\n%d warning(s), no hard drift.\n' "$warns"
exit 0
