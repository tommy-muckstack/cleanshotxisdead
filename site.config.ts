import type { Site } from "@/lib/site-types";
const GH = "https://github.com/tommy-muckstack/cleanshotxisdead";
export const site: Site = {
  slug: "cleanshotxisdead", name: "CleanShotXIsDead", replaces: "CleanShot X", theme: "cleanshotx",
  glyph: "M7 9 V7 H9 M15 7 H17 V9 M17 15 V17 H15 M9 17 H7 V15 M12 10 V14 M10 12 H14",
  nav: [{ label: "Features", id: "product" }, { label: "Use cases", id: "solutions" }, { label: "Resources", id: "resources" }, { label: "Pricing", id: "pricing" }],
  cta: "Open the app, it's free",
  hero: { variant: "center", eyebrow: "Free · Open source · Runs in your browser", title: ["Capture. Annotate.", "Share. All free."], subtitle: "Grab your screen, mark it up with arrows, text, blur and step numbers, crop it, put it on a beautiful background and share a link. Captures stay on your device until you choose to share one.",
    primary: { label: "Open the app", href: "/login" }, secondary: { label: "See pricing", href: "/#pricing" }, shot: "editor.png", shotAlt: "The annotation editor with arrows, a blurred email address and numbered steps on a screenshot" },
  audience: "Used for bug reports, tutorials, docs, support replies, design feedback and every time a screenshot says it faster",
  stepsTitle: "From capture to link in four steps",
  steps: [{ t: "Capture", d: "Grab a screen, window or tab, record a video, drop in an image, or paste one." }, { t: "Annotate", d: "Arrows, shapes, text, highlights, numbered steps, and blur for anything private." }, { t: "Polish", d: "Crop, then add a gradient background with padding, rounded corners and a soft shadow." }, { t: "Share", d: "Download a PNG, copy it to the clipboard, or upload it and send a link." }] ,
  rows: [
    { id: "product", k: "Annotate", h: "Point at exactly what matters", p: "Ten tools with one-key shortcuts: arrow, rectangle, ellipse, line, text, highlighter, blur, numbered steps, crop and select. Move, recolor and delete any mark, with unlimited undo.", img: "editor.png", alt: "A screenshot with red arrows, a rectangle, a blurred email and numbered step badges", cta: "Open the editor" },
    { id: "beautify", k: "Beautify", h: "Make a plain screenshot look designed", p: "Pick a gradient, set padding and corner radius, and add a shadow. The export is a clean PNG you can drop straight into a doc, post or pull request.", img: "background.png", alt: "A screenshot on an aurora gradient background with rounded corners and a drop shadow", cta: "Try backgrounds" },
    { id: "privacy", k: "Blur", h: "Hide what shouldn't leave your screen", p: "Drag the blur tool over emails, names or tokens. It pixelates the underlying image in the export, so the original pixels are never in the file you share.", img: "blur.png", alt: "A table where the email column has been pixelated", cta: "Blur something" },
    { id: "share", k: "Share", h: "A link in one click", p: "Upload the finished image and get a public link with a view counter. Delete it any time. The rest of your library never leaves the browser.", img: "share.png", alt: "The share link bar and a shared image page", cta: "Share a capture" },
  ],
  statsTitle: "Real numbers, no fine print",
  stats: [{ b: "$0", s: "for every plan we replace" }, { b: "10 tools", s: "annotation, blur, crop and more" }, { b: "On-device", s: "library, nothing uploaded unless you share" }, { b: "Apache-2.0", s: "self-host it, fork it, change it" }],
  integrations: { title: "Drops into your workflow", text: "Copy to the clipboard and paste into Slack, Notion or an email, download a PNG, or share a link. Recordings export as WebM. A browser extension and scrolling capture are on the roadmap." },
  pricing: { title: "What you'd pay for a capture tool", vendor: "CleanShot X", asOf: "October 2026", plans: [{ name: "Basic", perSeatMonth: 0, oneTime: 35, note: "Mac only, one year of updates, 1 GB cloud" }, { name: "Cloud Pro", perSeatMonth: 10, note: "per user, billed yearly, unlimited cloud" }], seats: 5,
    footnote: "CleanShot X Basic is a one-time $35 purchase with a year of updates (further updates are $19 a year). Cloud Pro is $10 per user per month billed yearly. It is a Mac app; this one runs in any modern browser. Self-hosting has your own hosting costs; a small instance fits in free tiers.", featuresTitle: "Every feature, no plan gates",
    features: [{ name: "Annotation tools and blur", plan: "Basic" }, { name: "Backgrounds and padding", plan: "Basic" }, { name: "Screen recording", plan: "Basic" }, { name: "Shareable links", plan: "Basic (1 GB)" }, { name: "Unlimited cloud storage", plan: "Cloud Pro" }, { name: "Custom branding and team features", plan: "Cloud Pro" }] },
  finalCta: { title: "Your next screenshot can look this good.", sub: "Capture, mark up, share. No install, no license key." },
  footer: [
    { title: "Product", links: [{ label: "Annotate", href: "/#product" }, { label: "Beautify", href: "/#beautify" }, { label: "Blur", href: "/#privacy" }, { label: "Pricing", href: "/#pricing" }] },
    { title: "Get started", links: [{ label: "Log in", href: "/login" }, { label: "Try the demo account", href: "/login" }, { label: "Price comparison", href: "/#pricing" }] },
    { title: "Open source", links: [{ label: "GitHub", href: GH }, { label: "Apache-2.0 license", href: GH + "/blob/main/LICENSE" }] },
    { title: "More IsDead apps", links: [{ label: "CalendlyIsDead", href: "/calendlyisdead" }, { label: "GrammarlyIsDead", href: "/grammarlyisdead" }, { label: "GranolaIsDead", href: "/granolaisdead" }, { label: "DocuSignIsDead", href: "/docusignisdead" }] },
  ],
  trademark: "CleanShotXIsDead is an independent open-source project. It is not affiliated with, endorsed by or sponsored by the makers of CleanShot X. CleanShot X is a trademark of its owner.",
  repo: GH,
};
