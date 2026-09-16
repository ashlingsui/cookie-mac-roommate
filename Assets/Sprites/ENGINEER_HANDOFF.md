# Cookie sprite handoff

Photo-cutout sprites of Cookie (grey/black classic tabby, white chest/muzzle/paws). Not stock-cat art. Not a chatbot companion.

Canonical Mac source:

`/Users/ashling/Desktop/Grok Local/Cookie Soul/sprites/`

Ship these exact **five** files in `Assets/Sprites/` (Weixin 5-pack). `cookie_sit.png` is retired. `cookie_suitcase.png` is hide/box only — not an idle pose. v1.1 clamps the full overlay into the **lower-right habitat** of `NSScreen.main.visibleFrame`. Feet anchors still decide how the bitmap sits inside that frame. Do not pixelate or redraw these cutouts. Photo suitcase only; no cartoon box.

If this checkout was produced on a non-Mac builder, the PNGs in git may not match the pixel sizes below. Overwrite them from the Desktop folder with `./scripts/import-sprites.sh` before shipping. Do not invent replacement pixels.

## Table

| File | Pixels | Feet anchor (frac) | Role |
| --- | ---: | ---: | --- |
| `cookie_sit_eyes_closed.png` | 182×320 | (0.525, 0.997) | Sit, eyes closed — good default idle |
| `cookie_loaf.png` | 256×320 | (0.752, 0.997) | Loaf / curled rest |
| `cookie_sleep.png` | 320×316 | (0.522, 0.997) | Sleeping curl |
| `cookie_alert.png` | 161×320 | (0.627, 0.997) | Good default idle |
| `cookie_suitcase.png` | 320×268 | (0.383, 0.981) | Hide/box only. Not in idle random pool |

Anchor fractions are image-space with origin at the **top-left** of the PNG (`x` right, `y` down). Convert to AppKit (origin bottom-left) as:

```
feet.x = anchor.x * width
feet.y = (1 - anchor.y) * height
```

Then place the overlay window so that screen point `perch` equals `window.origin + feet`.

## Live pose

Start with `cookie_sit_eyes_closed` or `cookie_alert`. Other roam poses may appear after a dash / relocate. Suitcase appears only in box mode (Hide in box). Do not add new poses or redraw these cutouts.

## Import from the Mac folder

```bash
./scripts/import-sprites.sh
```

Copies the five PNGs. Also copies `_meta.json` / `ENGINEER_HANDOFF.md` when those files exist next to the PNGs. Removes leftover `cookie_sit.png` from `Assets/Sprites/`. Never deletes `cookie_suitcase.png`.
