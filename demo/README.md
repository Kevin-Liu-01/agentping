# Agent-Notify demo video

46-second HyperFrames composition: glassmorphic macOS notifications, Cursor-style glass IDE, bezier camera zooms, and live pointer interactions.

Built with [HyperFrames](https://hyperframes.heygen.com) (HTML/CSS + GSAP → MP4).

## Preview

```bash
cd demo
npm run dev
```

Scrub the timeline in the HyperFrames studio.

## Render

```bash
cd demo
npm run check    # lint, validate, inspect
npm run render   # writes demo/renders/demo_<timestamp>.mp4
```

Requires Node 22+ and FFmpeg.

## What it shows

| Time | Scene |
|------|-------|
| 0–4s | Intro |
| 4–46s | Cursor glass IDE with agent chat + terminal |
| ~8–12s | **notify**: terminal types command → banner slides in → camera zooms |
| ~12–22s | **ask**: zoom → cursor types `dev` in field → clicks Reply |
| ~22–31s | **choose**: zoom → cursor hovers options → clicks ship |
| ~31–40s | **confirm**: zoom → cursor clicks Approve |
| 41–46s | Outro: four verb cards |

## Motion

- **Camera rig** (`#camera`): `power4.inOut` / `expo.inOut` bezier zooms into each notification
- **Pointer**: macOS arrow with click ripple, moves on `sine.inOut` curves
- **Terminal**: commands type character-by-character with blinking caret
- **Notifications**: slide + scale entrance, focused input field, button press states

## Skills

- **HyperFrames** — seekable GSAP timeline, deterministic render
- **diagram-to-html** — fixed 1920×1080 canvas, system fonts
