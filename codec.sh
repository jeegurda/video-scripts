BASE_PATH="${1:-.}"
HIGHLIGHT_CODECS=("hevc")
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

for f in "$BASE_PATH"/*.mp4 "$BASE_PATH"/*.mkv "$BASE_PATH"/*.avi "$BASE_PATH"/*.wmv; do
  [ -f "$f" ] || continue
  codec=$(ffprobe -v error \
    -select_streams v:0 \
    -show_entries stream=codec_name \
    -of default=nw=1:nk=1 "$f")

  is_highlighted=false
  for highlighted_codec in "${HIGHLIGHT_CODECS[@]}"; do
    if [[ "$codec" == "$highlighted_codec" ]]; then
      is_highlighted=true
      break
    fi
  done

  if "$is_highlighted"; then
    codec="${GREEN}${codec}${RESET}"
  else
    codec="${RED}${codec}${RESET}"
  fi

  printf '%s: %b\n' "$f" "$codec"
done

