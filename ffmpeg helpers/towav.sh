#!/bin/bash

# Default directories
output_dir="$PWD"
input_dir="$PWD"

# Display usage
show_usage() {
  echo "Usage: towav [-a|--all [input_dir]] [-o|--out <output_dir>] [file1 file2 ...]"
  echo
  echo "Options:"
  echo "  -a, --all [dir] Convert all supported video files in this directory (default: current directory)"
  echo "  -o, --out       Specify output directory (current working directory otherwise)"
  echo "  -h, --help      Show this help message"
  exit 0
}

# Convert single files
convert_file() {
  local input_file="$1"
  if [ ! -f "$input_file" ]; then
    echo "File not found: $input_file"
    return
  fi
  local base_name=$(basename "$input_file")
  local name="${base_name%.*}"
  local output_file="${output_dir}/${name}.wav"
  echo "Converting '$input_file' -> '$output_file'..."
  ffmpeg -i "$input_file" -acodec pcm_s16le -vn -hide_banner -stats "$output_file"
}

# Parse arguments
files=()
all_files=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_usage
      ;;
    -a|--all)
      all_files=true
      # Check if next argument exists and is not an option
        if [[ -n "$2" && "$2" != -* ]]; then
          input_dir="$2"
          shift
        fi
        shift
        ;;
    -o|--out)
        if [ -z "$2" ]; then
          echo "Error: --out requires a directory argument."
          exit 1
        fi
        output_dir="$2"
        shift 2
        ;;
    *)
        files+=("$1")
        shift
        ;;
  esac
done

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# If -a/--all is specified, get all supported video files in input_dir
if [[ "$all_files" == true ]]; then
  shopt -s nullglob nocaseglob
  files=("$input_dir"/*.mp4 "$input_dir"/*.mov "$input_dir"/*.mkv "$input_dir"/*.webm \
    "$input_dir"/*.avi "$input_dir"/*.flv "$input_dir"/*.wmv "$input_dir"/*.mpeg \
    "$input_dir"/*.mpg "$input_dir"/*.m4v "$input_dir"/*.3gp "$input_dir"/*.ts "$input_dir"/*.ogv)
  if [ ${#files[@]} -eq 0 ]; then
    echo "No supported video files found in '$input_dir'."
    exit 0
  fi
fi

# Show usage if no files were provided and --all was not specified
if [ ${#files[@]} -eq 0 ]; then
  show_usage
fi

# Convert each file
for f in "${files[@]}"; do
  convert_file "$f"
done
