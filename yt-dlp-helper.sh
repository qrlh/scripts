#!/usr/bin/env bash

# Here document metadata format variable.
# We add this as a comment to be viewed with mediainfo or Windows properties and so on.
# For archival purposes.
meta_format=$(
    cat <<EOF
%(uploader)s - %(title)s

Upload UTC\: %(upload_date)s
Download UTC\: %(epoch>%Y%m%d)s

Uploader URL\: %(uploader_url)s
Channel URL\: %(channel_url)s
Video URL\: %(webpage_url)s

Original description\:
%(description)s:(?s)(?P<meta_comment>.+)
EOF
)

show_usage() {
    echo "Usage: $(basename "$0") [-o|--output <output_dir>] [-ni|--noninteractive <URLs>]"
    echo
    echo "Options:"
    echo "  -o,  --output [dir]     Set the directory to write files to, current working directory by default"
    echo "  -ni, --noninteractive   Provide URLs via the CLI instead of being prompted for them"
    echo "  -h,  --help             Show this help message"

    exit 0
}

download() {
    yt-dlp \
        --format "bv+ba/b" \
        --merge-output-format mkv \
        --remux-video mkv \
        --embed-thumbnail \
        --embed-subs \
        --embed-chapters \
        --embed-info-json \
        --embed-metadata \
        --parse-metadata "$meta_format" \
        --cookies-from-browser "Firefox" \
        --download-archive "$path/links.txt" \
        --paths "$path" \
        "$url"
}

interactive() {
    while true; do
        read -rp "Please enter a URL: " url
        clear
        echo "Downloading: \"$url\""
        download
        echo ""
        # Move cursor back to start of line and clear it to overwrite prompt
        printf "\r\033[K"
    done
}

noninteractive() {
    for url in "$@"; do
        echo "Downloading: \"$url\""
        download
        echo ""
    done
}

main() {
    #Set default path
    path="$PWD"
    urls=()

    # While arguments remain, parse them
    while [[ "$#" -gt 0 ]]; do
        case $1 in
        -o | --out)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --out requires a directory" >&2
                show_usage
            fi
            path="$2"
            shift 2
            ;;
        -ni | --noninteractive)
            shift
            if [[ "$#" -eq 0 ]]; then
                echo "Error: --noninteractive requires at least one URL" >&2
                show_usage
            fi
            urls=("$@")
            break
            ;;
        -h | --help | *)
            show_usage
            ;;
        esac
    done
    
    # If the number of urls is greater than 0
    if [[ "${#urls[@]}" -gt 0 ]]; then
        noninteractive "${urls[@]}"
    else
        interactive
    fi
}

main "$@"
exit 0
