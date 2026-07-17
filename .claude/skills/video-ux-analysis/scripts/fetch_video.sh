#!/usr/bin/env bash
# Fetch a YouTube video + metadata for /video-ux-analysis.
# Proven in the Claude Code remote container (2026-07): HLS formats via yt-dlp's
# native downloader work through the session proxy; progressive https formats
# 403 from datacenter IPs (YouTube PO-token enforcement), so HLS is preferred.
set -euo pipefail

usage() {
  echo "Usage: $0 <youtube-url> <out-dir> [--max-height N] [--section \"*MM:SS-MM:SS\"]" >&2
  exit 2
}

[[ $# -ge 2 ]] || usage
URL="$1"; OUT="$2"; shift 2
MAXH=720
SECTION=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-height) MAXH="$2"; shift 2 ;;
    --section)    SECTION="$2"; shift 2 ;;
    *) usage ;;
  esac
done

mkdir -p "$OUT"

if ! python3 -c 'import yt_dlp' 2>/dev/null; then
  echo "[fetch_video] installing yt-dlp..." >&2
  pip3 install --quiet "yt-dlp[default]" 1>&2
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    echo "[fetch_video] installing ffmpeg..." >&2
    apt-get update -qq 1>&2 && apt-get install -y -qq ffmpeg 1>&2
  else
    echo "[fetch_video] ffmpeg not found and no apt-get; install ffmpeg or supply a local video file" >&2
    exit 1
  fi
fi

# YouTube stream extraction needs a JS runtime; node is present in the container.
NODE_ARGS=()
if NODE_BIN=$(command -v node); then NODE_ARGS=(--js-runtimes "node:$NODE_BIN"); fi
YTDLP=(python3 -m yt_dlp "${NODE_ARGS[@]}")

# Metadata first: validates the URL cheaply and gives duration/chapters for the sampling plan.
"${YTDLP[@]}" --skip-download \
  --print-to-file "%(.{id,title,duration,width,height,chapters})j" "$OUT/meta.json" \
  "$URL" 1>&2

SECTION_ARGS=()
if [[ -n "$SECTION" ]]; then SECTION_ARGS=(--download-sections "$SECTION"); fi
printf '%s\n' "${SECTION:-full}" > "$OUT/section.txt"

"${YTDLP[@]}" \
  --downloader "m3u8:native" \
  -f "b[protocol*=m3u8][height<=$MAXH]/bv*[protocol*=m3u8][height<=$MAXH]/b[height<=$MAXH]/b" \
  "${SECTION_ARGS[@]}" \
  -o "$OUT/video.%(ext)s" \
  "$URL" 1>&2

VIDEO=$(ls "$OUT"/video.* | head -1)
echo "$VIDEO"
