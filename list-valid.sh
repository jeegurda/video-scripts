#!/bin/bash

# Trap SIGINT
trap "echo -e '\n\033[0;31mScript interrupted by user\033[0m'; exit 1" SIGINT

if [ -z "$1" ]; then
  echo "Error: no path set"
  exit 1
fi

dir=$1

count=0
total=$(find "$dir" -type f | wc -l)

for file in "$dir"/*; do
  if [ -d "$file" ]; then
    continue
  fi

  file_normalized=$(realpath "$file")

  ((count++))
  echo -e "\033[0;34mProcessing file $count/$total: $file_normalized\033[0m"

  if ! ffmpeg -v error -i "$file_normalized" -f null -; then
    echo -e "\033[0;31mError in file: $file_normalized\033[0m"
  fi
done

echo "All files processed successfully"
