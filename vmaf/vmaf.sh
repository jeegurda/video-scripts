#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: two paths must be set."
  exit 1
fi

file1="$1"
file2="$2"

name="lgf"

start1="1:00"
start2="1:00"
duration="30"

out_json="vmaf-log-${name}.json"
out_txt="vmaf-data-${name}.txt"
out_png="plot-${name}.png"

win_file1=$(cygpath -w "$file1")
win_file2=$(cygpath -w "$file2")

ffmpeg -i "$win_file1" -i "$win_file2" -ss $start1 -t $duration -lavfi libvmaf=model="path=vmaf_v0.6.1.json:log_path=${out_json}:log_fmt=json" -f null -

jq -r '.frames[] | "\(.frameNum) \(.metrics.vmaf)"' "$out_json" >"$out_txt"

echo "set terminal pngcairo size 1600,800; set key bottom left; plot '"$out_txt"' using 1:2 with lines" | gnuplot -p >"$out_png"
