# CleanShotXIsDead

Free, open-source CleanShot X alternative. Part of the [IsDead series](https://yourappisdead.com). Served at `https://yourappisdead.com/cleanshotxisdead`.

**Status: open source, not deployed yet**. Surfaces follow `templates/marketing-site.md` in `@isdead/design`: one marketing page (`/`, price comparison at `#pricing`), `/login`, and the app at `/app`.

## What works
Browser capture (screen share picker), open/paste/drop images, 10 annotation tools (select, arrow, rectangle, ellipse, line, text, highlight, blur/pixelate, counter steps), undo/redo, crop, beautify backgrounds with padding/corners/shadow, PNG download, copy to clipboard, public share links with view counter, screen recording to WebM, library in IndexedDB, shared login

## Known gaps
No native OS capture (scrolling capture, window capture, all-in-one hotkeys), no GIF export, no OCR, no video trimming, share links stored on a file store (needs Firestore/Storage before hosting), no cloud sync of the local library

## Auth
Shared Firebase project `yourappisdead` (email/password + Google), helpers in `lib/isdead-auth` (vendored from `isdead-design/auth`). The session cookie `isdead_session` has path `/`, so one sign-in covers every IsDead app. Env: `NEXT_PUBLIC_FIREBASE_*`, `FIREBASE_SERVICE_ACCOUNT_JSON`. Without them, `/login` shows "Sign-in not configured". The single demo account ("Use the demo account") is available outside production or with `DEMO_MODE=1`.

## Develop
```
npm install
npm run dev        # http://localhost:3000/cleanshotxisdead
npm test           # unit tests
npm run typecheck
npm run build && npm run shots   # product screenshots + end-to-end smoke test (Playwright)
```
Theme and font: `vendor/isdead-design` (OFL fonts, see `fonts/*/OFL-*.txt`). Not affiliated with CleanShot X; all trademarks belong to their owners. Apache-2.0.
