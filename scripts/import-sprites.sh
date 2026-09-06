#!/bin/bash
# Copy Ashling's approved Cookie cutouts over the copies in this repo.
set -euo pipefail

SRC="${COOKIE_SPRITES:-/Users/ashling/Desktop/Grok Local/Cookie Soul/sprites}"
DEST="$(cd "$(dirname "$0")/.." && pwd)/Assets/Sprites"

files=(
  cookie_sleep.png
  cookie_alert.png
  cookie_sit.png
  cookie_sit_eyes_closed.png
  cookie_loaf.png
  cookie_suitcase.png
)

if [[ ! -d "$SRC" ]]; then
  echo "Sprite folder not found: $SRC" >&2
  echo "Set COOKIE_SPRITES to the folder that holds the six PNGs." >&2
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

echo "Sprites imported into $DEST"
