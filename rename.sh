#!/bin/bash

set -e

DIRECTORY_PATH=""
PREFIX=""
POSTFIX=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --prefix)
      PREFIX="$2"
      shift 2
      ;;
    --postfix)
      POSTFIX="$2"
      shift 2
      ;;
    *)
      if [ -z "$DIRECTORY_PATH" ]; then
        DIRECTORY_PATH="$1"
      fi
      shift
      ;;
  esac
done

if [ -z "$DIRECTORY_PATH" ]; then
  echo "Usage: $0 <directory_path> [--prefix PREFIX] [--postfix POSTFIX]"
  exit 1
fi

declare -A replacements
replacements=(
  ["____"]=""
)

cd "$DIRECTORY_PATH" || exit 1

name_changed=false

for file in *; do
  if [ -d "$file" ]; then
    continue
  fi

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
    if [ -d "$file" ]; then
      continue
    fi

    newfile="${PREFIX}${file}${POSTFIX}"

    for key in "${!replacements[@]}"; do
      newfile="${newfile/${key}/${replacements[$key]}}"
    done

    if [[ "$file" != "$newfile" ]]; then
      mv -i -- "$file" "$newfile" || echo "Skipped: $file"
    fi
  done
fi
