# cookie-mac-roommate

Mac desktop roommate that puts my cat on your screen while you work — cat-honest presence, muteable sounds, muteable bratty bubbles. Not a chatbot.

Cookie (grey/black classic tabby, white chest/muzzle/paws) is a photo-cutout overlay. v1.1 she lives in the **lower-right corner of the main screen** and roams / pose-swaps there. Click makes her dash to another spot in that corner and talk. Panic-hide is the menu backup. Menu bar has **Quit for today** and **Mute**. The app registers itself to launch at login.

Mac only. Native Swift + AppKit. One job.

## Open / build / run on macOS

This repo is a complete Xcode project. The Linux cloud VM cannot run the overlay; build it on a Mac.

1. Clone this branch (or the merged `main`) to the Mac.
2. Optional but recommended — replace the repo sprites with the originals on disk:

   ```bash
   ./scripts/import-sprites.sh
   ```

   That copies from `/Users/ashling/Desktop/Grok Local/Cookie Soul/sprites/`. Override with `COOKIE_SPRITES=/path ./scripts/import-sprites.sh` if the folder moved.
3. Open `Cookie.xcodeproj` in Xcode 15+ (macOS 13 Ventura or later).
4. Select the **Cookie** scheme, destination **My Mac**.
5. Press Run (⌘R). Cookie has no Dock icon (`LSUIElement`). The menu bar item always reads **Cookie** (optional paw icon).
6. To keep her after you quit Xcode: Product → Archive, or drag the built `Cookie.app` from Products into `/Applications`, then launch it once so login registration sticks.

Ad-hoc signing (`CODE_SIGN_IDENTITY = "-"`) is enough to run locally. Set your Development Team in the Cookie target if you want a stable notarized build.

### Menu

| Item | What it does |
| --- | --- |
| Panic hide | Cookie vanishes for ~20s, then comes back in the right-corner habitat |
| Mute / Muted | Toggle. Soft rare stub sound **and** click speech bubbles |
| Quit for today | Quits. She returns at the next login |

### Motion and click (v1.1)

- Habitat is the lower-right of `NSScreen.main.visibleFrame` only. No whole-desktop roam.
- Idle: pace / pose-swap among the six signed photo cutouts.
- Click Cookie: dash to another point **inside** that corner. Does not hide.
- Short speech bubble (cooldown). Mute hides bubbles too.
- Panic hide stays on the menu only.

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

Canonical Mac source for the six PNGs:

`/Users/ashling/Desktop/Grok Local/Cookie Soul/sprites/`

Live pose starts on `cookie_sit` or `cookie_alert`. Clamp the full overlay into the main-screen lower-right habitat.

## Out of scope

No chat companion. No Windows/Linux. No pixelate / pixel-art / illustrated Cookie. No sprite redesign.
