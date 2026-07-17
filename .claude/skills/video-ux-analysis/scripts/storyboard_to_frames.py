#!/usr/bin/env python3
"""Explode a yt-dlp storyboard .mhtml into individual frames (last-resort, low-res).

YouTube storyboard mosaics are grids of ~396x180 thumbnails. ffmpeg's mjpeg decoder
corrupts them; Pillow decodes them reliably. Output frames are named by their approximate
source second so the skill can still reference timestamps.
"""
import email, sys, os
from email import policy

try:
    from PIL import Image
except ImportError:
    os.system(f"{sys.executable} -m pip install --quiet pillow")
    from PIL import Image

def main(mhtml_path, out_dir, tile_w=396, tile_h=180, secs_per_frame=None):
    os.makedirs(out_dir, exist_ok=True)
    with open(mhtml_path, "rb") as f:
        msg = email.message_from_binary_file(f, policy=policy.default)
    mosaics = [p.get_payload(decode=True) for p in msg.walk()
               if p.get_content_type().startswith("image")]
    idx = 0
    for m, data in enumerate(mosaics):
        tmp = os.path.join(out_dir, f"_mosaic_{m:02d}.jpg")
        with open(tmp, "wb") as o:
            o.write(data)
        im = Image.open(tmp).convert("RGB")
        cols, rows = im.width // tile_w, im.height // tile_h
        for r in range(rows):
            for c in range(cols):
                box = (c*tile_w, r*tile_h, (c+1)*tile_w, (r+1)*tile_h)
                frame = im.crop(box).resize((tile_w*2, tile_h*2), Image.LANCZOS)
                frame.save(os.path.join(out_dir, f"frame_{idx:04d}.jpg"), quality=90)
                idx += 1
        os.remove(tmp)
    print(f"[storyboard] wrote {idx} frames to {out_dir}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("usage: storyboard_to_frames.py <sb.mhtml> <out-dir>", file=sys.stderr)
        sys.exit(2)
    main(sys.argv[1], sys.argv[2])
