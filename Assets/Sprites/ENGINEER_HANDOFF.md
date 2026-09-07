# Cookie sprite handoff

Photo-cutout sprites of Cookie (grey/black classic tabby, white chest/muzzle/paws). Not stock-cat art. Not a chatbot companion.

Canonical Mac source:

`/Users/ashling/Desktop/Grok Local/Cookie Soul/sprites/`

Ship these exact files in `Assets/Sprites/`. v1.1 clamps the full overlay into the **lower-right habitat** of `NSScreen.main.visibleFrame`. Feet anchors still decide how the bitmap sits inside that frame. Do not pixelate or redraw these cutouts.

## Table

| File | Pixels | Feet anchor (frac) | Role |
| --- | ---: | ---: | --- |
| `cookie_sleep.png` | 252×312 | (0.679, 0.978) | Sleeping curl; hind paw / toe beans near the anchor |
| `cookie_alert.png` | 248×310 | (0.5, 0.987) | Good default idle |
| `cookie_sit.png` | 209×330 | (0.431, 0.997) | Approved sit — good default idle |
| `cookie_sit_eyes_closed.png` | 184×310 | (0.418, 0.977) | Sit, eyes closed |
| `cookie_loaf.png` | 309×310 | (0.573, 0.974) | Loaf / curled rest |
| `cookie_suitcase.png` | 303×281 | (0.139, 0.975) | Cookie + case + bandana as one unit; anchor is the suitcase base, bottom-left |

Anchor fractions are image-space with origin at the **top-left** of the PNG (`x` right, `y` down). Convert to AppKit (origin bottom-left) as:

```
feet.x = anchor.x * width
feet.y = (1 - anchor.y) * height
```

Then place the overlay window so that screen point `perch` equals `window.origin + feet`.

## Live pose

Start with `cookie_sit` or `cookie_alert`. Other approved poses may appear after a shoo / relocate. Do not add new poses or redraw these cutouts.

If the repo PNGs were produced on a non-Mac builder, overwrite them from the Desktop folder above before shipping. The filenames, pixel sizes, and anchors in this table are the contract.

## Import from the Mac folder

```bash
./scripts/import-sprites.sh
```
