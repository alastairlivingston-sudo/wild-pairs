#!/usr/bin/env bash
# Turn a video into timestamped contact sheets for token-efficient visual review.
# One sheet = one image read = 4-16 frames of evidence.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  extract_frames.sh scan   <video> <out-dir> [--frames N] [--tiles CxR] [--tile-width W]
  extract_frames.sh zoom   <video> <out-dir> --start T --end T [--fps F] [--tiles CxR] [--tile-width W]
  extract_frames.sh scenes <video> <out-dir> [--threshold T] [--max-frames N] [--tiles CxR] [--tile-width W]

  scan    Uniform sampling across the whole video (default 54 frames -> 6 sheets of 3x3 @480px)
  zoom    Dense sampling of one segment (default 2 fps, 2x2 @800px) to observe behaviour
  scenes  Scene-change frames only (default threshold 0.25) - good for menu-heavy videos

Times are seconds or [HH:]MM:SS. Every tile carries a burned-in source timestamp.
EOF
  exit 2
}

to_seconds() {
  local t="$1" IFS=':' parts s=0
  read -ra parts <<< "$t"
  for p in "${parts[@]}"; do s=$(awk -v s="$s" -v p="$p" 'BEGIN{printf "%.3f", s*60+p}'); done
  echo "$s"
}

find_font() {
  local f
  for f in /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf \
           /System/Library/Fonts/Supplemental/Arial\ Bold.ttf \
           /System/Library/Fonts/Helvetica.ttc; do
    [[ -e "$f" ]] && { echo "$f"; return; }
  done
}

[[ $# -ge 3 ]] || usage
MODE="$1"; VIDEO="$2"; OUT="$3"; shift 3
[[ -f "$VIDEO" ]] || { echo "no such video: $VIDEO" >&2; exit 1; }
mkdir -p "$OUT"

FRAMES=54 TILES="" TILE_W="" FPS=2 START="" END="" THRESHOLD=0.25 MAX_FRAMES=36
while [[ $# -gt 0 ]]; do
  case "$1" in
    --frames)     FRAMES="$2"; shift 2 ;;
    --tiles)      TILES="$2"; shift 2 ;;
    --tile-width) TILE_W="$2"; shift 2 ;;
    --fps)        FPS="$2"; shift 2 ;;
    --start)      START=$(to_seconds "$2"); shift 2 ;;
    --end)        END=$(to_seconds "$2"); shift 2 ;;
    --threshold)  THRESHOLD="$2"; shift 2 ;;
    --max-frames) MAX_FRAMES="$2"; shift 2 ;;
    *) usage ;;
  esac
done

FONT=$(find_font)
ts_filter() { # $1 = offset seconds added to displayed pts (for seeked input)
  if [[ -n "$FONT" ]]; then
    echo "drawtext=fontfile=$FONT:text='%{pts\\:hms\\:${1:-0}}':x=8:y=8:fontsize=28:fontcolor=yellow:box=1:boxcolor=black@0.6,"
  fi
}

case "$MODE" in
  scan)
    TILES=${TILES:-3x3} TILE_W=${TILE_W:-480}
    DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VIDEO")
    INTERVAL=$(awk -v d="$DUR" -v n="$FRAMES" 'BEGIN{i=d/n; if(i<1)i=1; printf "%.3f", i}')
    ffmpeg -hide_banner -loglevel error -y -i "$VIDEO" \
      -vf "fps=1/$INTERVAL,$(ts_filter 0)scale=$TILE_W:-1,tile=$TILES" \
      -fps_mode passthrough "$OUT/scan-%02d.jpg"
    ;;
  zoom)
    [[ -n "$START" && -n "$END" ]] || usage
    TILES=${TILES:-2x2} TILE_W=${TILE_W:-800}
    DUR=$(awk -v a="$START" -v b="$END" 'BEGIN{printf "%.3f", b-a}')
    OFFSET=${START%.*}
    ffmpeg -hide_banner -loglevel error -y -ss "$START" -t "$DUR" -i "$VIDEO" \
      -vf "fps=$FPS,$(ts_filter "$OFFSET")scale=$TILE_W:-1,tile=$TILES" \
      -fps_mode passthrough "$OUT/zoom-${OFFSET}s-%02d.jpg"
    ;;
  scenes)
    TILES=${TILES:-3x3} TILE_W=${TILE_W:-480}
    ffmpeg -hide_banner -loglevel error -y -i "$VIDEO" \
      -vf "select='gt(scene,$THRESHOLD)',$(ts_filter 0)scale=$TILE_W:-1,tile=$TILES" \
      -fps_mode vfr -frames:v $(( (MAX_FRAMES + 8) / 9 )) "$OUT/scene-%02d.jpg"
    ;;
  *) usage ;;
esac

ls "$OUT"/*.jpg
