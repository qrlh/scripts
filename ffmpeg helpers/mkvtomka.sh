#!/bin/bash
pids=()
files=()

for i in "$@"; do
    base="${i%.mkv}"
    ffmpeg -loglevel error -i "$i" \
        -map 0:a \
        -map 0:t? \
        -map_metadata 0 \
        -f matroska \
        -c copy "$base.mka" &
    pids+=($!)
    files+=("$base.mka")
done

for idx in "${!pids[@]}"; do
    if wait "${pids[$idx]}"; then
        echo "Done: ${files[$idx]}"
    else
        echo "Failed: ${files[$idx]}" >&2
    fi
done
