#!/bin/bash

# Parse command line options
while getopts ":f" opt; do
  case ${opt} in
  f)
    force=true
    ;;
  \?)
    echo "Invalid option: $OPTARG" 1>&2
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

parent_dir_path="$1"

if [[ ! -d "$parent_dir_path" ]]; then
  echo "Directory does not exist: $parent_dir_path"
  exit 1
fi

# Iterate over the directories in the parent directory
for dir_path in "$parent_dir_path"*/; do
  # Get the directory name
  dir_name=$(basename "$dir_path")

  # Iterate over the files in the directory
  for file_path in "$dir_path"*; do
    # Skip if it's not a file
    if [[ ! -f "$file_path" ]]; then
      continue
    fi

    # Get the file name
    file_name=$(basename "$file_path")

    # Construct the new file name
    new_file_name="$dir_name - $file_name"
    new_file_path="$dir_path$new_file_name"

    # Check if a file with the new name already exists
    if [[ -e "$new_file_path" ]]; then
      echo "File already exists: $new_file_path"
    else
      # If the -f flag is provided, rename the file
      # Otherwise, just print the old and new filenames
      if [[ $force ]]; then
        mv -n "$file_path" "$new_file_path"
      else
        printf "Would rename: \e[35m\"%s\"\e[0m to \e[34m\"%s\"\e[0m\n" "$file_path" "$new_file_path"
      fi
    fi
  done
done
