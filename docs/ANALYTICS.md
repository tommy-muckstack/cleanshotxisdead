# Analytics (PostHog)

One PostHog project (US cloud, project **666931**) collects the hub and every IsDead app. The contract is the hub's
`yourappisdead/ANALYTICS.md`; this file is how CleanShotXIsDead follows it.
The web side is the marketing site + Mac download, plus the browser library/editor at `/app` and shared images `/s/<id>`. The Mac app in `mac/` has its own Swift analytics (`platform: mac`, see the hub contract) and is not covered here.

## Setup
- `NEXT_PUBLIC_POSTHOG_KEY` (the project's publishable token) and `NEXT_PUBLIC_POSTHOG_HOST=https://us.posthog.com` are set on the Vercel project. No key → analytics is a no-op.
- Requests go through this app's own origin: `<basePath>/ingest/*` → `us.i.posthog.com` (rewrites in `next.config.mjs`, with `skipTrailingSlashRedirect: true`).
- `<Analytics />` and `<LinkTracking />` are mounted once in `app/layout.tsx`. `Analytics` sends PostHog's `$pageview` per route change. Autocapture, session replay, heatmaps and web-vitals capture are off.
- Privacy: `scrub` (before_send) keeps only origin + path in URL properties, drops `title`, and masks private path segments (`/s/<id>` shared-image links become `/s/:id`; the page title, which is the image name, is dropped).
- posthog-js drops automated browsers. In dev, `localStorage.isdead_ph_debug = "1"` turns on verbose logs and lets Playwright capture (used by the kit's `ph-check.mjs`); production keeps the bot filter.

## Super properties (registered on every event)
| property | value | meaning |
| --- | --- | --- |
| `product` | `cleanshotxisdead` | the one property to filter by |
| `surface` | `landing` \| `app` | `landing` = marketing pages and pricing; `app` = `/app` (library/editor) and shared images `/s/<id>` |
| `platform` | `web` | |
| `env` | `production` \| `development` | |
| `account_type` | `firebase` \| `guest` \| `demo` | registered in the app header; only `firebase` users are identified |

## Identity
There is no web sign-in page any more. `/app` runs with a guest or existing session; `IdentifyUser` in `components/AppHeader.tsx` identifies Firebase users by uid and only tags guests/demo. Sign-out sends `app_signed_out` and calls `reset()` before the logout form posts.

## Events
| event | properties | where |
| --- | --- | --- |
| `landing_download_clicked` | `target` (`mac`), `placement` | any link to `/download` |
| `landing_cta_clicked` | `target` (`pricing`, `app`, `github`, `releases`, `issues`, `license`, `hub`), `placement` | other marketing links |
| `app_signed_out` | | `components/AppHeader.tsx` |
| `app_capture_taken` | `kind` (`screen`, `image`, `paste`, `drop`, `sample`) | `components/shot/Library.tsx` (same name as the Mac app's event) |
| `app_recording_saved` | `format` (`webm`), `mic` | `Library.tsx` |
| `app_editor_exported` | `mode` (`download`, `copy`), `annotations` | `components/shot/Editor.tsx` |
| `app_shared` | `channel` (`cloud`), `annotations` | `Editor.tsx` (share link created) |
| `app_shot_viewed` | | `app/s/[id]/page.tsx` |

## Rules
- Event names are `app_<object>_<action>` / `landing_<object>_<action>`, snake_case, past tense, never containing the product name. They are defined only in `lib/analytics/taxonomy.ts`; the unit test enforces the prefixes.
- Properties are kinds, counts, ids and booleans only. Never titles, file names, messages, comment text, emails or URLs. Don't use the legacy super-property names (`source`, `app`, `app_id`, `site_id`, `environment`) as event properties.
- `landing_cta_clicked` / `landing_download_clicked` come from one delegated click listener (`LinkTracking` in `lib/analytics/posthog.tsx`) that classifies `<a>` destinations, so new marketing links are tracked without code. `placement` is the page region (`nav`, `footer`, or the enclosing section's id/class).

## Where the calls live
`lib/analytics/` (client, taxonomy, link tracking, scrub). Tests: `tests/unit/analytics.test.ts`.
