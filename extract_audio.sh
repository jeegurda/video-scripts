#!/usr/bin/env bash
# Extract the audio track from a media file without re-encoding.
# Usage: ./extract_audio.sh input.mp4 [output_dir]
#        ./extract_audio.sh input.mp4 --mp3   (re-encode to MP3)
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <input_file> [output_dir | --mp3]" >&2
  exit 1
fi

input="$1"
second="${2:-}"

if [ ! -f "$input" ]; then
  echo "Error: file not found: $input" >&2
  exit 1
fi

command -v ffmpeg >/dev/null || { echo "Error: ffmpeg not installed" >&2; exit 1; }
command -v ffprobe >/dev/null || { echo "Error: ffprobe not installed" >&2; exit 1; }

base="$(basename "${input%.*}")"

if [ "$second" = "--mp3" ]; then
  outdir="$(dirname "$input")"
  ffmpeg -hide_banner -i "$input" -vn -c:a libmp3lame -q:a 2 "$outdir/$base.mp3"
  echo "Saved: $outdir/$base.mp3"
  exit 0
fi

outdir="${second:-$(dirname "$input")}"
mkdir -p "$outdir"

# Detect the audio codec to pick a matching container for a lossless copy
codec="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name \
  -of default=noprint_wrappers=1:nokey=1 "$input")"

if [ -z "$codec" ]; then
  echo "Error: no audio stream found in $input" >&2
  exit 1
fi

case "$codec" in
  aac)    ext="m4a" ;;
  mp3)    ext="mp3" ;;
  opus)   ext="opus" ;;
  vorbis) ext="ogg" ;;
  flac)   ext="flac" ;;
  ac3)    ext="ac3" ;;
  eac3)   ext="eac3" ;;
  pcm_*)  ext="wav" ;;
  *)      ext="mka" ;;
esac

out="$outdir/$base.$ext"
ffmpeg -hide_banner -i "$input" -map 0:a:0 -vn -c:a copy "$out"
echo "Saved: $out (codec: $codec, no re-encode)"
