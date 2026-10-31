#!/bin/bash

# set -e

dir=$1
suffix="-x265-params pools=20"

if [ -z "$1" ]; then
  echo "Error: no path set"
  exit 1
fi

interrupted=false
handle_signal() {
  interrupted=true
}

trap handle_signal SIGINT

mkdir -p "${dir}/converted"
mkdir -p "${dir}/source"

total_files=$(find "${dir}" -maxdepth 1 -type f ! -name ".*" ! -name "_*" | wc -l)
progress=0

while IFS= read -r -d '' file <&3; do
  base_file=$(basename "$file")

  out_file="${dir}/converted/${base_file%.*}.mp4"

  ((progress++))
  echo -e "\e[34mProcessing $progress/$total_files: $base_file\e[0m"

  ffmpeg -i "$file" -c:v libx265 -crf 25 -loglevel info $suffix "$out_file"
  ffmpeg_status=$?

  if $interrupted; then
    printf "\e[34mInterrupted by SIGINT\e[0m\n"
    rm -f "$out_file"
    break
  fi

  if [ $ffmpeg_status -eq 0 ]; then
    mv -i "$file" "${dir}/source/"
  fi

  echo -e "\e[34mCompleted $progress/$total_files\e[0m"
done 3< <(find "${dir}" -maxdepth 1 -type f ! -name ".*" ! -name "_*" -print0)

echo "All files have been processed."