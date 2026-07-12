#!/usr/bin/env bash
# Disable the laptop touchpad while an external mouse is connected.
# Subscribes to Sway input add/remove events and re-evaluates on each one.
set -euo pipefail

# Single-instance guard: if a daemon is already running (e.g. after a config
# reload), keep it and exit quietly instead of stacking subscribers.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/touchpad-auto.lock"
flock -n 9 || exit 0

TOUCHPAD="1739:0:Synaptics_TM3471-020"
TRACKPOINT="2:10:TPPS/2_Elan_TrackPoint"

apply() {
    # External mouse present = any pointer device that isn't the built-in trackpoint.
    if swaymsg -t get_inputs -r \
        | python3 -c "import sys,json;d=json.load(sys.stdin);\
print(any(x.get('type')=='pointer' and x.get('identifier')!='$TRACKPOINT' for x in d))" \
        | grep -q True; then
        swaymsg input "$TOUCHPAD" events disabled >/dev/null
    else
        swaymsg input "$TOUCHPAD" events enabled >/dev/null
    fi
}

apply
swaymsg -t subscribe -m '["input"]' | while read -r _; do
    apply
done
