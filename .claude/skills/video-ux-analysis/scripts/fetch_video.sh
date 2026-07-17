#!/usr/bin/env bash
# Get a game video ready for /video-ux-analysis and print the path to the usable video/frames.
#
# Acquisition ladder (learned the hard way, 2026-07, in the remote container):
#   0. LOCAL FILE  — if arg1 is a path to an existing file, use it directly. Most reliable
#      route by far: YouTube now gates real streams behind a PO token that a datacenter IP
#      cannot mint (BotGuard challenge fails here), so many videos will NOT download.
#   1. HLS (m3u8)  — when the video exposes it, yt-dlp's native HLS downloader works through
#      the session proxy. Not all videos expose HLS.
#   2. DASH/progressive https — usually 403 Forbidden from this IP. Tried, not relied on.
#   3. STORYBOARD  — last resort. Always downloads (plain images on a thumbnail CDN) but is
#      very low-res (~396x180/frame) and only ~1 fps: good for gross structure, useless for
#      reading HUD text. Decode with Pillow, NOT ffmpeg (ffmpeg's mjpeg decoder corrupts them).
#
# If only the storyboard is reachable, this script says so on stderr and the skill should ask
# the user to download the video locally and re-run with the file path.
set -euo pipefail

usage() {
  echo "Usage: $0 <youtube-url|local-file> <out-dir> [--max-height N] [--section \"*MM:SS-MM:SS\"]" >&2
  exit 2
}

[[ $# -ge 2 ]] || usage
SRC="$1"; OUT="$2"; shift 2
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

# --- Route 0: local file --------------------------------------------------------------
if [[ -f "$SRC" ]]; then
  ext="${SRC##*.}"
  cp "$SRC" "$OUT/video.$ext"
  echo "[fetch_video] using local file (no download needed)" >&2
  echo "$OUT/video.$ext"
  exit 0
fi

URL="$SRC"

if ! python3 -c 'import yt_dlp' 2>/dev/null; then
  echo "[fetch_video] installing yt-dlp..." >&2
  pip3 install --quiet "yt-dlp[default]" 1>&2
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    echo "[fetch_video] installing ffmpeg..." >&2
    apt-get update -qq 1>&2 && apt-get install -y -qq ffmpeg 1>&2
  else
    echo "[fetch_video] ffmpeg not found and no apt-get; supply a local video file instead" >&2
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

# --- Routes 1+2: HLS preferred, DASH/progressive as fallback --------------------------
if "${YTDLP[@]}" \
     --downloader "m3u8:native" \
     -f "b[protocol*=m3u8][height<=$MAXH]/bv*[protocol*=m3u8][height<=$MAXH]/b[height<=$MAXH]/b" \
     "${SECTION_ARGS[@]}" \
     -o "$OUT/video.%(ext)s" \
     "$URL" 1>&2; then
  echo "$(ls "$OUT"/video.* | head -1)"
  exit 0
fi

# --- Route 3: storyboard last resort --------------------------------------------------
echo "[fetch_video] stream download failed (likely PO-token/IP wall). Trying storyboard..." >&2
if "${YTDLP[@]}" -f sb0 -o "$OUT/sb.%(ext)s" "$URL" 1>&2 && [[ -f "$OUT/sb.mhtml" ]]; then
  python3 "$(dirname "$0")/storyboard_to_frames.py" "$OUT/sb.mhtml" "$OUT/storyboard" 1>&2
  echo "[fetch_video] WARNING: only low-res storyboard frames available (~396x180, ~1fps)." >&2
  echo "[fetch_video] HUD text will NOT be readable. For a real UX analysis, download the" >&2
  echo "[fetch_video] video on your machine and re-run this script with the local file path." >&2
  echo "$OUT/storyboard"   # a directory of frames, not a single video
  exit 0
fi

echo "[fetch_video] could not acquire this video from here. Please download it locally" >&2
echo "[fetch_video] and re-run: fetch_video.sh /path/to/video.mp4 $OUT" >&2
exit 1
