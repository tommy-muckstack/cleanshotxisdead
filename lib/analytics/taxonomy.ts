// Analytics taxonomy for the shared IsDead PostHog project 666931 (contract: yourappisdead/ANALYTICS.md, see docs/ANALYTICS.md).
// Super properties: product (this app's slug), surface ("landing" = logged-out marketing pages, "app" = the working product
// and anything it publishes), platform ("web"). Page views are PostHog's built-in $pageview.
// Events are `app_<object>_<action>` (or `landing_<object>_<action>` for marketing CTAs); the product name lives in
// `product`, never in an event name. Never send user content (titles, URLs, emails, text) as properties.
export const APP = "cleanshotxisdead" as const;
export type Surface = "landing" | "app";
export const EVENTS = {
  // The web side has no sign-in page any more (website CTAs download the Mac app); /app runs as a guest or an
  // existing session, so only sign-out is tracked here.
  app_signed_out: "app_signed_out",
  landing_download_clicked: "landing_download_clicked", // target ("mac"), placement (page region: "nav" | "footer" | section class)
  // web library/editor (/app)
  app_capture_taken: "app_capture_taken",               // kind ("screen" | "image" | "paste" | "drop" | "sample")
  app_recording_saved: "app_recording_saved",           // format ("webm"), mic (bool)
  app_editor_exported: "app_editor_exported",           // mode ("download" | "copy"), annotations (count)
  app_shared: "app_shared",                             // channel ("cloud"), annotations (count)
  // shared image page /s/<id>
  app_shot_viewed: "app_shot_viewed",
  landing_cta_clicked: "landing_cta_clicked", // target ("pricing" | "app" | "github" | "releases" | "issues" | "license" | "hub"), placement
} as const;
export type EventName = (typeof EVENTS)[keyof typeof EVENTS];
export const EVENT_PREFIXES = ["app_", "landing_"] as const;
/** Super properties every event carries (yourappisdead/ANALYTICS.md §1). */
export const superProps = (surface: Surface) => ({ product: APP, surface, platform: "web" as const });
/** Super properties older IsDead taxonomies persisted in the shared yourappisdead.com cookie. Unregistered at boot. */
export const LEGACY_PROPS = ["app", "app_family", "base_path", "suite_id", "app_id", "schema_version", "source", "site_id", "environment", "ads_blocked", "account_type"] as const;
