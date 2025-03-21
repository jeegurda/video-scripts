#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: two paths must be set."
  exit 1
fi

dir1="$1"
dir2="$2"

for file1 in "$dir1"/*; do
  file2name=$(printf "%q" "$(basename "$file1" .${file1##*.})")
  file2name+=".*"

  file2=$(find "$dir2" -name "$file2name" -print -quit)

  if [ -f "$file2" ]; then
    duration1=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file1")
    duration2=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file2")
    echo "Comparing $duration1 and $duration2..."

    base_file1=$(basename "$file1")
    base_file2=$(basename "$file2")

    if (($(printf "%.0f" $duration1) - $(printf "%.0f" $duration2) > 1)) || (($(printf "%.0f" $duration2) - $(printf "%.0f" $duration1) > 1)); then
      echo -e "\e[31mWarning: "$base_file1" and "$base_file2" have different durations\e[0m"
    else
      echo -e "\e[32mProcessed "$base_file1" and "$base_file2"\e[0m"
    fi
  else
    echo -e "\e[35mWarning: "$file1" does not exist in "$dir2" (searched for "$file2name")\e[0m"
  fi
done
