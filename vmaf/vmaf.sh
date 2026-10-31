#!/bin/bash

usage() {
  cat <<EOF
Usage: $0 -d FILE -r FILE [options]

Options:
  -d, --distorted FILE         Distorted video (the encode being judged)
  -r, --reference FILE         Reference video (the original)
  -s, --distorted-start TIME   Start offset in the distorted video (default: 1:00)
  -S, --reference-start TIME   Start offset in the reference video (default: 1:00)
  -t, --duration SECONDS       Length of the compared segment (default: 30)
  -n, --name NAME              Prefix for the output files (default: 1)
  -h, --help                   Show this help
EOF
}

distorted=""
reference=""
distorted_start="1:00"
reference_start="1:00"
duration="30"
name="1"

while [ $# -gt 0 ]; do
  case "$1" in
    -d | --distorted | -r | --reference | -s | --distorted-start | -S | --reference-start | -t | --duration | -n | --name)
      if [ $# -lt 2 ]; then
        echo "Error: $1 requires a value." >&2
        exit 1
      fi
      case "$1" in
        -d | --distorted) distorted="$2" ;;
        -r | --reference) reference="$2" ;;
        -s | --distorted-start) distorted_start="$2" ;;
        -S | --reference-start) reference_start="$2" ;;
        -t | --duration) duration="$2" ;;
        -n | --name) name="$2" ;;
      esac
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      echo "Error: unexpected argument: $1 (use --distorted and --reference)" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$distorted" ] || [ -z "$reference" ]; then
  echo "Error: both a distorted and a reference video must be set." >&2
  usage >&2
  exit 1
fi

required_commands=(ffmpeg-vmaf jq gnuplot)
missing_commands=()

for command_name in "${required_commands[@]}"; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    missing_commands+=("$command_name")
  fi
done

if [ "${#missing_commands[@]}" -gt 0 ]; then
  echo "Error: required command(s) not found: ${missing_commands[*]}" >&2
  exit 1
fi

out_json="${name}-vmaf-log.json"
out_txt="${name}-vmaf-data.txt"
out_png="${name}-plot.png"

ffmpeg-vmaf -ss "$distorted_start" -t "$duration" -i "$distorted" -ss "$reference_start" -t "$duration" -i "$reference" -lavfi libvmaf=model="path=vmaf_v0.6.1.json:log_path=${out_json}:log_fmt=json" -f null -

jq -r '.frames[] | "\(.frameNum) \(.metrics.vmaf)"' "$out_json" >"$out_txt"

echo "set terminal pngcairo size 1600,800; set key bottom left; plot '"$out_txt"' using 1:2 with lines" | gnuplot -p >"$out_png"
