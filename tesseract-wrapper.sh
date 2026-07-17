#!/bin/bash

use_parallel=false

while [[ $# -gt 0 ]]; do
    case "$1" in
    -p | --parallel)
        use_parallel=true
        shift
        ;;
    -*)
        echo "Usage: $(basename "$0") [-p|--parallel] [files...]"
        exit 1
        ;;
    *)
        break
        ;;
    esac
done

if [[ $# -eq 0 ]]; then
    echo "No files were specified" >&2
    exit 1
fi

process_image() {
    mime=$(file -b --mime-type "$1")
    case "$mime" in
    image/jpeg | image/png | image/tiff | image/bmp | image/webp | image/gif)
        echo "=== $1 ==="
        tesseract "$1" stdout 2>/dev/null
        echo ""
        ;;
    esac
}

if "$use_parallel"; then
    if ! command -v parallel &>/dev/null; then
        echo "GNU parallel was not found, processing sequentially" >&2
        use_parallel=false
    fi
fi

if "$use_parallel"; then
    export -f process_image
    parallel -k --bar --eta process_image ::: "$@"
else
    for img in "$@"; do
        process_image "$img"
    done
fi
