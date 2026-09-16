#!/bin/bash
# Copy Ashling's approved Cookie cutouts (Weixin 5-pack) into this repo.
# Run on the Mac. Pixel files live at the Desktop path below — this VM does not invent sprites.
set -euo pipefail

SRC="${COOKIE_SPRITES:-/Users/ashling/Desktop/Grok Local/Cookie Soul/sprites}"
DEST="$(cd "$(dirname "$0")/.." && pwd)/Assets/Sprites"

files=(
  cookie_sit_eyes_closed.png
  cookie_loaf.png
  cookie_sleep.png
  cookie_alert.png
  cookie_suitcase.png
)

optional=(
  _meta.json
  ENGINEER_HANDOFF.md
)

dropped=(
  cookie_sit.png
)

if [[ ! -d "$SRC" ]]; then
  echo "Sprite folder not found: $SRC" >&2
  echo "Set COOKIE_SPRITES to the folder that holds the five Weixin PNGs." >&2
  exit 1
fi

mkdir -p "$DEST"
for f in "${files[@]}"; do
  if [[ ! -f "$SRC/$f" ]]; then
    echo "Missing $SRC/$f" >&2
    exit 1
  fi
  cp -f "$SRC/$f" "$DEST/$f"
  echo "copied $f"
done

for f in "${optional[@]}"; do
  if [[ -f "$SRC/$f" ]]; then
    cp -f "$SRC/$f" "$DEST/$f"
    echo "copied $f"
  fi
done

for f in "${dropped[@]}"; do
  if [[ -e "$DEST/$f" ]]; then
    rm -f "$DEST/$f"
    echo "removed $f"
  fi
done

echo "Sprites imported into $DEST"
