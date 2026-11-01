#!/usr/bin/env bash
# Make H.265 (HEVC) videos previewable on macOS (Finder, Quick Look, QuickTime)
# without re-encoding the video.
#
# macOS only plays HEVC in an MP4/MOV container tagged "hvc1". Files tagged "hev1"
# (the ffmpeg default) or stored in MKV show no preview. This remuxes the video
# stream as-is with the right tag. Audio is copied when macOS supports it and
# re-encoded to AAC otherwise. Subtitles are dropped.
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 -i PATH [options]

Options:
  -i, --input PATH         Video file, or a directory (non-recursive) of .mkv/.mp4/.m4v/.mov files
  -o, --output-dir DIR     Where to write results (default: next to each input)
  -f, --force              Overwrite existing output files
  -h, --help               Show this help

Output files are named <name>-hvc1.mp4.
EOF
}

input=""
output_dir=""
force=false

while [ $# -gt 0 ]; do
  case "$1" in
    -i | --input | -o | --output-dir)
      if [ $# -lt 2 ]; then
        echo "Error: $1 requires a value." >&2
        exit 1
      fi
      case "$1" in
        -i | --input) input="$2" ;;
        -o | --output-dir) output_dir="$2" ;;
      esac
      shift 2
      ;;
    -f | --force)
      force=true
      shift
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
      echo "Error: unexpected argument: $1 (use --input)" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$input" ]; then
  echo "Error: --input is required." >&2
  usage >&2
  exit 1
fi

if [ ! -e "$input" ]; then
  echo "Error: not found: $input" >&2
  exit 1
fi

for command_name in ffmpeg ffprobe; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "Error: $command_name is not installed" >&2
    exit 1
  }
done

[ -n "$output_dir" ] && mkdir -p "$output_dir"

converted=0
skipped=0
failed=0

process_file() {
  local file="$1"
  local base ext dir out tmp video_info vcodec vtag audio_codecs audio_codec index

  base="$(basename "${file%.*}")"
  ext="$(printf '%s' "${file##*.}" | tr '[:upper:]' '[:lower:]')"
  dir="${output_dir:-$(dirname "$file")}"
  out="$dir/$base-hvc1.mp4"

  video_info="$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name,codec_tag_string -of csv=p=0 "$file" || true)"
  IFS=, read -r vcodec vtag <<<"$video_info"

  if [ "$vcodec" != "hevc" ]; then
    echo "Skip (not H.265, codec: ${vcodec:-none}): $file"
    skipped=$((skipped + 1))
    return
  fi

  case "$ext" in
    mp4 | m4v | mov)
      if [ "$vtag" = "hvc1" ]; then
        echo "Skip (already previewable on macOS): $file"
        skipped=$((skipped + 1))
        return
      fi
      ;;
  esac

  if [ -e "$out" ] && [ "$force" = false ]; then
    echo "Skip (output exists, use --force): $out"
    skipped=$((skipped + 1))
    return
  fi

  # Per-stream audio handling: keep what macOS can play, convert the rest to AAC
  audio_args=()
  index=0
  audio_codecs="$(ffprobe -v error -select_streams a \
    -show_entries stream=codec_name -of csv=p=0 "$file" || true)"
  while IFS= read -r audio_codec; do
    [ -n "$audio_codec" ] || continue
    case "$audio_codec" in
      aac | ac3 | eac3 | alac | mp3)
        audio_args+=("-c:a:$index" copy)
        ;;
      *)
        echo "Note: audio track $index is $audio_codec, converting to AAC"
        audio_args+=("-c:a:$index" aac "-b:a:$index" 256k)
        ;;
    esac
    index=$((index + 1))
  done <<<"$audio_codecs"

  echo "Remuxing: $file"
  # -nostdin: ffmpeg must not consume the file list piped into the loop below.
  # Write to a temp file so an interrupted run never leaves a partial output.
  tmp="$dir/.$base-hvc1.partial.mp4"
  if ffmpeg -nostdin -hide_banner -loglevel error -stats -y -i "$file" \
    -map 0:v:0 -map "0:a?" -sn \
    -c:v copy -tag:v hvc1 \
    ${audio_args[@]+"${audio_args[@]}"} \
    -movflags +faststart "$tmp" && mv -f "$tmp" "$out"; then
    echo "Saved: $out"
    converted=$((converted + 1))
  else
    echo "Failed: $file" >&2
    rm -f "$tmp"
    failed=$((failed + 1))
  fi
}

if [ -d "$input" ]; then
  while IFS= read -r -d '' file; do
    case "$file" in
      *-hvc1.mp4) continue ;;
    esac
    process_file "$file"
  done < <(find "$input" -maxdepth 1 -type f \
    \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.m4v' -o -iname '*.mov' \) -print0)
else
  process_file "$input"
fi

echo "Done: $converted converted, $skipped skipped, $failed failed."
[ "$failed" -eq 0 ]
