# CleanShotXIsDead

Free, open-source CleanShot X alternative. Part of the [IsDead series](https://yourappisdead.com). Served at `https://yourappisdead.com/cleanshotxisdead`.

Free. No account, no license, no subscription.

## Mac app (the real thing)

`mac/` is a native macOS menu-bar app (Swift, macOS 14.2+) that looks and feels like CleanShot X: All-In-One / Area / Fullscreen / Window / Self-Timer / OCR capture, screen recording to MP4, the Quick Access Overlay, an annotation editor (arrows, shapes, text, counter, pixelate, highlight, crop, backgrounds, background removal), pin-to-screen, Capture History, Settings panes mirroring CleanShot X's, global shortcuts, and cloud links (uploads go to this web app as a guest; nothing to sign up for).

- **Download:** <https://yourappisdead.com/cleanshotxisdead/download> (latest signed + notarized DMG from GitHub Releases). Drag to Applications, grant Screen Recording when asked.
- **Run from source:** `cd mac && ./scripts/run-dev.sh` (builds, assembles a signed .app, launches). `swift build` / `swift test` for plain builds.
- **Release:** `cd mac && RELEASE_VERSION=x.y.z RELEASE_BUILD=n ./scripts/build-direct.sh` — universal build, Developer ID + hardened runtime, notarize + staple, DMG, Sparkle EdDSA signature + appcast, upload, GitHub release.
- Capture engine, selection overlay and editor are ported from [My Man](https://github.com/tommy-muckstack/myman) (Apache-2.0). All UI art is original.

## Web app

Surfaces follow `templates/marketing-site.md` in `@isdead/design`: one marketing page (`/`, price comparison at `#pricing`), `/download` (redirects to the latest Mac build), and the browser app at `/app` (guest sessions, no login; it also serves the share links the Mac app creates).

## What works
Browser capture (screen share picker), open/paste/drop images, 10 annotation tools (select, arrow, rectangle, ellipse, line, text, highlight, blur/pixelate, counter steps), undo/redo, crop, beautify backgrounds with padding/corners/shadow, PNG download, copy to clipboard, public share links with view counter, screen recording to WebM, library in IndexedDB, shared login

## Known gaps
No native OS capture (scrolling capture, window capture, all-in-one hotkeys), no GIF export, no OCR, no video trimming, share links stored on a file store (needs Firestore/Storage before hosting), no cloud sync of the local library

## Sessions
No login. `/app` hands every visitor a guest session (`lib/isdead-auth`, cookie `isdead_session`, path `/`); captures are keyed by the guest id. Env: `AUTH_SECRET` (guest cookie signing). `DEMO_MODE=1` enables the demo account outside production for tests.

## Develop
```
npm install
npm run dev        # http://localhost:3000/cleanshotxisdead
npm test           # unit tests
npm run typecheck
npm run build && npm run shots   # product screenshots + end-to-end smoke test (Playwright)
```
Theme and font: `vendor/isdead-design` (OFL fonts, see `fonts/*/OFL-*.txt`). Not affiliated with CleanShot X; all trademarks belong to their owners. Apache-2.0.
