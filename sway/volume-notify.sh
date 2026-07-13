#!/usr/bin/env bash
# Adjusts volume via wpctl and reports the new level to the wob overlay bar.
set -euo pipefail

WOB_SOCK="${XDG_RUNTIME_DIR}/wob.sock"

case "$1" in
    up)
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    mic-mute)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        ;;
    *)
        echo "usage: $0 {up|down|mute|mic-mute}" >&2
        exit 1
        ;;
esac

target="@DEFAULT_AUDIO_SINK@"
if [ "$1" = "mic-mute" ]; then
    target="@DEFAULT_AUDIO_SOURCE@"
fi

status="$(wpctl get-volume "$target")"
volume="$(awk '{print int($2 * 100)}' <<< "$status")"

if grep -q MUTED <<< "$status"; then
    echo 0 > "$WOB_SOCK"
else
    echo "$volume" > "$WOB_SOCK"
fi
