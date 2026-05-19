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
    # Save flow: user picks a target directory in yazi; we append the
    # caller-suggested filename so the original name (e.g. FB_IMG_1234.jpg)
    # is preserved automatically — no manual typing.
    save_dir="$(dirname "$path")"
    filename="$(basename "$path")"

    # Remove the placeholder that termfilechooser pre-creates; we'll write
    # the real target path to $out ourselves.
    [ -f "$path" ] && [ ! -s "$path" ] && rm -f "$path"

    picked="$(mktemp)"
    /usr/bin/foot --app-id=yazi-picker -- \
        "$yazi" --chooser-file="$picked" --cwd-file="$picked" "$save_dir"

    if [ -s "$picked" ]; then
        chosen="$(head -n1 "$picked")"
        # If the user selected a file, use its parent directory.
        if [ -f "$chosen" ]; then
            chosen="$(dirname "$chosen")"
        fi
        printf '%s/%s\n' "$chosen" "$filename" > "$out"
    fi
    rm -f "$picked"
elif [ "$directory" = "1" ]; then
    /usr/bin/foot --app-id=yazi-picker -- "$yazi" --chooser-file="$out" --cwd-file="$out"
else
    /usr/bin/foot --app-id=yazi-picker -- "$yazi" --chooser-file="$out"
fi
