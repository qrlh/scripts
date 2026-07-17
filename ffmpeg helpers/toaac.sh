#!/bin/bash
pids=()
files=()

for i in "$@"; do
    base="${i%.*}"
    ffmpeg -loglevel error -i "$i" \
        -map 0:a \
        -map_chapters 0 \
        -map_metadata 0 \
        -c:a aac -b:a 192k \
        "$base.m4a" &
    pids+=($!)
    files+=("$base.m4a")
done

for idx in "${!pids[@]}"; do
    if wait "${pids[$idx]}"; then
        echo "Done: ${files[$idx]}"
    else
        echo "Failed: ${files[$idx]}" >&2
    fi
done
