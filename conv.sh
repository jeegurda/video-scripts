#!/bin/bash

# set -e

dir=$1
suffix="-x265-params pools=12"

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

total_files=$(find "${dir}" -maxdepth 1 -type f ! -name ".*" | wc -l)

progress=0

for file in "${dir}"/*; do
  if [ -d "$file" ]; then
    continue
  fi

  base_file=$(basename "$file")

  if [[ $base_file == .* ]]; then
    continue
  fi

  out_file="${dir}/converted/${base_file%.*}.mp4"

  ffmpeg -i "$file" -c:v libx265 -crf 25 -loglevel info $suffix "$out_file"

  if $interrupted; then
    printf "\e[34mInterrupted by SIGINT\e[0m\n"
    rm "$out_file"
    break
  fi

  mv "$file" "${dir}/source/"

  ((progress++))

  echo -e "\e[34mProcessed $progress/$total_files\e[0m"
done

echo "All files have been processed."
