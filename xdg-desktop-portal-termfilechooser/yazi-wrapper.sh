#!/bin/sh
# Yazi wrapper for xdg-desktop-portal-termfilechooser
#
# Arguments:
# 1. "1" if multiple files can be chosen, "0" otherwise.
# 2. "1" if a directory should be chosen, "0" otherwise.
# 3. "0" if opening files, "1" if saving a file.
# 4. If saving, the recommended path from the caller.
# 5. The output path to write selected paths to.

multiple="$1"
directory="$2"
save="$3"
path="$4"
out="$5"

yazi="$HOME/.cargo/bin/yazi"

if [ "$save" = "1" ]; then
    save_dir="$(dirname "$path")"
    /usr/bin/foot --app-id=yazi-picker -- "$yazi" --chooser-file="$out" "$save_dir"
    if [ ! -s "$out" ]; then
        rm -f "$path"
    fi
elif [ "$directory" = "1" ]; then
    /usr/bin/foot --app-id=yazi-picker -- "$yazi" --chooser-file="$out" --cwd-file="$out"
else
    /usr/bin/foot --app-id=yazi-picker -- "$yazi" --chooser-file="$out"
fi
