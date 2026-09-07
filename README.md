# cookie-mac-roommate

Mac desktop roommate that puts my cat on your screen while you work — cat-honest presence, nudge-to-shoo, soft rare sounds. Not a chatbot.

Cookie (grey/black classic tabby, white chest/muzzle/paws) sits on or near the frontmost window as a photo-cutout overlay. She is sometimes in the way on purpose. Drag her or keep typing and she slides off. Panic-hide is the backup. Menu bar has **Quit for today** and **Mute**. The app registers itself to launch at login.

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
| Panic hide | Cookie vanishes for ~20s, then comes back on a new perch |
| Mute / Muted | Toggle. Soft rare stub sound (`Assets/Sounds/cookie_soft.wav`) |
| Quit for today | Quits. She returns at the next login |

### Shoo

- Drag the fur (transparent pixels click through).
- Type while she is sitting on the window you are using — a few keys and she slides off.
- Panic hide from the menu if she will not move.

### Accessibility (optional)

Type-through also uses a global key monitor when macOS allows it. Drag + panic hide work without that permission. Window sitting uses `CGWindowList` (no Accessibility prompt).

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

Live pose starts on `cookie_sit` or `cookie_alert`. Placement is by **feet anchor** on a dock or window edge — never centered on the display. About a quarter of perches overlap the content you are looking at.

## Out of scope (v1)

No chat companion. No Windows/Linux. No new behaviors. No sprite redesign.
