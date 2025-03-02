#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "Error: no path set"
  exit 1
fi

DIRECTORY_PATH=$1
PREFIX="___ - "
POSTFIX=""

declare -A replacements
replacements=(
  ["___"]=""
)

cd "$DIRECTORY_PATH" || exit 1

name_changed=false

for file in *; do
  newfile="${PREFIX}${file}${POSTFIX}"

  for key in "${!replacements[@]}"; do
    newfile="${newfile/${key}/${replacements[$key]}}"
  done

  if [[ "$file" != "$newfile" ]]; then
    echo -e "Would rename \033[35m\"$file\"\033[0m to \033[34m\"$newfile\"\033[0m"
    name_changed=true
  fi
done

if [[ $name_changed == false ]]; then
  echo "No files will be renamed"
  exit 1
fi

read -p "Do you want to apply these changes? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  for file in *; do
    newfile="${PREFIX}${file}${POSTFIX}"

    for key in "${!replacements[@]}"; do
      newfile="${newfile/${key}/${replacements[$key]}}"
    done

    if [[ "$file" != "$newfile" ]]; then
      mv -i -- "$file" "$newfile"
    fi
  done
fi
