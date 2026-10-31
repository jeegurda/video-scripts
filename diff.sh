#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: two paths must be set."
  exit 1
fi

dir1="$1"
dir2="$2"

diff <(ls "$dir1" | sed -r 's/\.([^.]*)$//') <(ls "$dir2" | sed -r 's/\.([^.]*)$//')
