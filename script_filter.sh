#!/bin/bash
# Script Filter for Alfred: grabs clipboard image + lists clipboard history
# Priority: live clipboard capture (for Lightshot etc), then Alfred DB history
#
# Part of alfred-clipboard-image workflow
# https://github.com/glassdimly/alfred-clipboard-image

DB="$HOME/Library/Application Support/Alfred/Databases/clipboard.alfdb"
DATA_DIR="$HOME/Library/Application Support/Alfred/Databases/clipboard.alfdb.data"
IMAGES_DIR="$HOME/.config/alfred/clipboard-image/images"

# Core Data epoch offset (Jan 1, 2001 00:00:00 UTC -> Unix epoch)
EPOCH_OFFSET=978307200
now=$(date +%s)
mkdir -p "$IMAGES_DIR"

# Non-blocking cleanup of images older than 7 days
find "$IMAGES_DIR" -name "*.png" -mtime +7 -delete &

items=""
first=true

# --- Live clipboard image (catches Lightshot and anything Alfred misses) ---
has_image=$(osascript -e 'try' -e 'the clipboard as «class PNGf»' -e 'return "yes"' -e 'on error' -e 'return "no"' -e 'end try' 2>/dev/null)

if [ "$has_image" = "yes" ]; then
  clip_file="clipboard-${now}.png"
  clip_path="${IMAGES_DIR}/${clip_file}"

  osascript \
    -e 'set png_data to the clipboard as «class PNGf»' \
    -e "set fp to open for access POSIX file \"${clip_path}\" with write permission" \
    -e 'write png_data to fp' \
    -e 'close access fp' 2>/dev/null

  if [ -f "$clip_path" ] && [ -s "$clip_path" ]; then
    dims=$(sips -g pixelWidth -g pixelHeight "$clip_path" 2>/dev/null \
      | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w"x"h}')
    sz=$(stat -f%z "$clip_path")
    if [ "$sz" -gt 1048576 ]; then
      sz_human="$(( sz / 1048576 )).$(( sz % 1048576 / 104858 )) MB"
    else
      sz_human="$(( sz / 1024 )) KB"
    fi
    first=false
    items="{\"title\":\"Current clipboard: ${dims} (${sz_human})\",\"subtitle\":\"Save and copy path\",\"arg\":\"${clip_path}\"}"
  fi
fi

# --- Alfred clipboard DB history ---
if [ -f "$DB" ]; then
  rows=$(sqlite3 -separator '|' "$DB" \
    "SELECT item, ts, app, dataHash FROM clipboard WHERE dataType=1 AND dataHash != '' ORDER BY ts DESC")

  while IFS='|' read -r item ts app hash; do
    [ -z "$hash" ] && continue
    tiff_path="$DATA_DIR/${hash}"
    [ -f "$tiff_path" ] || continue

    short_hash=$(echo "$hash" | cut -c1-8)
    png_path="${IMAGES_DIR}/${short_hash}.png"
    if [ ! -f "$png_path" ]; then
      sips -s format png "$tiff_path" --out "$png_path" >/dev/null 2>&1
      [ -f "$png_path" ] || continue
    fi

    unix_ts=$(echo "$ts" | awk -v off="$EPOCH_OFFSET" '{printf "%d", $1 + off}')
    diff=$(( now - unix_ts ))
    if [ "$diff" -lt 60 ]; then
      rel="just now"
    elif [ "$diff" -lt 3600 ]; then
      mins=$(( diff / 60 ))
      [ "$mins" -eq 1 ] && rel="1 min ago" || rel="${mins} min ago"
    elif [ "$diff" -lt 86400 ]; then
      hrs=$(( diff / 3600 ))
      [ "$hrs" -eq 1 ] && rel="1 hour ago" || rel="${hrs} hours ago"
    elif [ "$diff" -lt 172800 ]; then
      rel="yesterday"
    else
      days=$(( diff / 86400 ))
      rel="${days} days ago"
    fi

    title=$(echo "$item" | sed 's/^Image: //')
    if [ -n "$app" ]; then
      subtitle="from ${app} · ${rel}"
    else
      subtitle="${rel}"
    fi

    title=$(echo "$title" | sed 's/"/\\"/g')
    subtitle=$(echo "$subtitle" | sed 's/"/\\"/g')

    if [ "$first" = true ]; then
      first=false
    else
      items="${items},"
    fi

    items="${items}{\"title\":\"${title}\",\"subtitle\":\"${subtitle}\",\"arg\":\"${png_path}\"}"

  done <<< "$rows"
fi

if [ "$first" = true ]; then
  echo '{"items":[{"title":"No clipboard images found","subtitle":"Copy an image to the clipboard first","valid":false}]}'
  exit 0
fi

echo "{\"items\":[${items}]}"
