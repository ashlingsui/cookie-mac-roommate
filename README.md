# cookie-mac-roommate

Mac desktop roommate that puts my cat on your screen while you work — cat-honest presence, muteable sounds, muteable bratty bubbles. Not a chatbot.

Cookie (grey/black classic tabby, white chest/muzzle/paws) is a photo-cutout overlay. v1.1 she lives in the **lower-right corner of the main screen** and roams / pose-swaps there. Click makes her dash to another spot in that corner and talk. **Hide in box** is the hide: she dashes into the habitat and stays as the photo suitcase until you click the box or **Come out**. Panic-hide is the boring offscreen backup. Menu bar has **Size**, **Quit for today**, and **Mute**. The app registers itself to launch at login.

Mac only. Native Swift + AppKit. One job.

## Open / build / run on macOS

This repo is a complete Xcode project. The Linux cloud VM cannot run the overlay; build it on a Mac.

1. Clone this branch (or the merged `main`) to the Mac.
2. Optional but recommended — replace the repo sprites with the originals on disk:

   ```bash
   ./scripts/import-sprites.sh
   ```

   That copies the Weixin 5-pack from `/Users/ashling/Desktop/Grok Local/Cookie Soul/sprites/`. Override with `COOKIE_SPRITES=/path ./scripts/import-sprites.sh` if the folder moved. This VM does not invent PNG pixels; run the import on the Mac so `Assets/Sprites/` matches the signed sizes in `Pose.swift`.
3. Open `Cookie.xcodeproj` in Xcode 15+ (macOS 13 Ventura or later).
4. Select the **Cookie** scheme, destination **My Mac**.
5. Press Run (⌘R). Cookie has no Dock icon (`LSUIElement`). The menu bar item always reads **Cookie** (optional paw icon).
6. To keep her after you quit Xcode: Product → Archive, or drag the built `Cookie.app` from Products into `/Applications`, then launch it once so login registration sticks.

Ad-hoc signing (`CODE_SIGN_IDENTITY = "-"`) is enough to run locally. Set your Development Team in the Cookie target if you want a stable notarized build.

### Menu

| Item | What it does |
| --- | --- |
| Hide in box | Dash into the lower-right habitat, then stay as the photo suitcase. No auto-return timer |
| Come out | Leave the suitcase, dash to another habitat spot, optional speech (`mine` / `busy`) |
| Panic hide | Boring backup: vanishes for ~22s, then comes back in the right-corner habitat |
| Mute / Muted | Toggle. Soft rare stub sound **and** click speech bubbles |
| Size | Small (0.4) / Medium (0.5, default) / Large (0.75). Persists as `cookie.spriteScale`. Changing size reapplies the current pose immediately |
| Quit for today | Quits. She returns at the next login |

### Motion and click (v1.1)

- Habitat is the lower-right of `NSScreen.main.visibleFrame` only. No whole-desktop roam.
- Idle: pace / pose-swap among sit-eyes-closed, loaf, sleep, alert. Suitcase is hide/box only.
- Click Cookie (out): dash to another point **inside** that corner. Does not hide.
- Click the suitcase (in box): come out (dash + optional `mine` / `busy`). No roam or drag while in box.
- Short speech bubble (cooldown). Mute hides bubbles too.
- Default display scale is **0.5** (half the PNG pixel size in points). Roam / dash / clamp use that scaled size.

### Accessibility

Not required for v1.1 habitat roam or click-dash.

## Layout

```
Assets/Sprites/          approved PNG cutouts, _meta.json, ENGINEER_HANDOFF.md
Assets/Sounds/           quiet stub wav (muteable)
Cookie/                  AppKit sources (`main.swift` assigns `NSApp.delegate` — required)
Cookie.xcodeproj/        Xcode project + shared scheme
scripts/import-sprites.sh
```

Sprite table and feet anchors: [`Assets/Sprites/ENGINEER_HANDOFF.md`](Assets/Sprites/ENGINEER_HANDOFF.md).

Canonical Mac source for the five PNGs:

`/Users/ashling/Desktop/Grok Local/Cookie Soul/sprites/`

Signed pack: `cookie_sit_eyes_closed.png`, `cookie_loaf.png`, `cookie_sleep.png`, `cookie_alert.png`, `cookie_suitcase.png`. Live pose starts on `cookie_sit_eyes_closed` or `cookie_alert`. Clamp the full overlay into the main-screen lower-right habitat.

## Out of scope

No chat companion. No Windows/Linux. No pixelate / pixel-art / illustrated Cookie. No sprite redesign. No cartoon box.
