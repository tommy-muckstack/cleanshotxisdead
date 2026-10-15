import type { Ann, Background, Crop, Doc } from "./types";
export const rid = () => Array.from(crypto.getRandomValues(new Uint8Array(8)), b => "abcdefghijkmnpqrstuvwxyz23456789"[b % 32]).join("");
export const clamp = (n: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, n));
export const normRect = (x1: number, y1: number, x2: number, y2: number) => ({ x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.abs(x2 - x1), h: Math.abs(y2 - y1) });
/** The two barbs of an arrowhead at (x2,y2) pointing away from (x1,y1). */
export function arrowHead(x1: number, y1: number, x2: number, y2: number, size: number): [[number, number], [number, number]] {
  const a = Math.atan2(y2 - y1, x2 - x1), spread = Math.PI / 7; return [[x2 - size * Math.cos(a - spread), y2 - size * Math.sin(a - spread)], [x2 - size * Math.cos(a + spread), y2 - size * Math.sin(a + spread)]];
}
export function distToSegment(px: number, py: number, x1: number, y1: number, x2: number, y2: number) {
  const dx = x2 - x1, dy = y2 - y1, l2 = dx * dx + dy * dy; if (!l2) return Math.hypot(px - x1, py - y1);
  const t = clamp(((px - x1) * dx + (py - y1) * dy) / l2, 0, 1); return Math.hypot(px - (x1 + t * dx), py - (y1 + t * dy));
}
export const STEP_R = (a: Ann) => 14 + a.width * 2;
export function bounds(a: Ann) {
  if (a.type === "step") { const r = STEP_R(a); return { x: a.x1 - r, y: a.y1 - r, w: 2 * r, h: 2 * r }; }
  if (a.type === "text") { const size = 14 + a.width * 4; const w = Math.max(24, (a.text ?? "").length * size * 0.56); return { x: a.x1, y: a.y1, w, h: size * 1.3 }; }
  return normRect(a.x1, a.y1, a.x2, a.y2);
}
export function hit(a: Ann, x: number, y: number, tol = 8): boolean {
  if (a.type === "arrow" || a.type === "line") return distToSegment(x, y, a.x1, a.y1, a.x2, a.y2) <= tol + a.width;
  const b = bounds(a);
  if (a.type === "step") return Math.hypot(x - a.x1, y - a.y1) <= STEP_R(a) + 2;
  if (a.type === "ellipse") { const rx = b.w / 2 + tol, ry = b.h / 2 + tol; return ((x - (b.x + b.w / 2)) / rx) ** 2 + ((y - (b.y + b.h / 2)) / ry) ** 2 <= 1 && !(b.w > 30 && b.h > 30 && ((x - (b.x + b.w / 2)) / (b.w / 2 - tol)) ** 2 + ((y - (b.y + b.h / 2)) / (b.h / 2 - tol)) ** 2 < 1); }
  if (a.type === "rect") { const inside = x >= b.x - tol && x <= b.x + b.w + tol && y >= b.y - tol && y <= b.y + b.h + tol; const deep = x > b.x + tol && x < b.x + b.w - tol && y > b.y + tol && y < b.y + b.h - tol; return inside && !(deep && b.w > 2 * tol && b.h > 2 * tol); }
  return x >= b.x - tol && x <= b.x + b.w + tol && y >= b.y - tol && y <= b.y + b.h + tol; // text, highlight, blur: filled hit area
}
export const topHit = (anns: Ann[], x: number, y: number) => { for (let i = anns.length - 1; i >= 0; i--) if (hit(anns[i]!, x, y)) return anns[i]!; return null; };
export const moveAnn = (a: Ann, dx: number, dy: number): Ann => ({ ...a, x1: a.x1 + dx, y1: a.y1 + dy, x2: a.x2 + dx, y2: a.y2 + dy });
export const nextStep = (anns: Ann[]) => anns.reduce((m, a) => (a.type === "step" ? Math.max(m, a.n ?? 0) : m), 0) + 1;
/** Renumber step badges 1..n in creation order (after deletes). */
export const renumber = (anns: Ann[]) => { let n = 0; return anns.map(a => (a.type === "step" ? { ...a, n: ++n } : a)); };
export const clampCrop = (c: Crop, w: number, h: number): Crop | null => { const x = clamp(c.x, 0, w), y = clamp(c.y, 0, h); const cw = clamp(c.w, 0, w - x), ch = clamp(c.h, 0, h - y); return cw < 8 || ch < 8 ? null : { x: Math.round(x), y: Math.round(y), w: Math.round(cw), h: Math.round(ch) }; };
export const outputSize = (w: number, h: number, d: Doc) => { const c = d.crop ?? { x: 0, y: 0, w, h }; const p = d.bg.enabled ? d.bg.padding : 0; return { w: c.w + 2 * p, h: c.h + 2 * p, innerW: c.w, innerH: c.h, pad: p }; };
export const gradientPoints = (w: number, h: number, angleDeg: number) => { const a = (angleDeg - 90) * Math.PI / 180, cx = w / 2, cy = h / 2, l = Math.abs(w * Math.cos(a)) / 2 + Math.abs(h * Math.sin(a)) / 2; return { x0: cx - Math.cos(a) * l, y0: cy - Math.sin(a) * l, x1: cx + Math.cos(a) * l, y1: cy + Math.sin(a) * l }; };
export const sanitizeBg = (b: Partial<Background> | undefined): Background => ({ enabled: !!b?.enabled, padding: clamp(Math.round(Number(b?.padding) || 64), 0, 240), radius: clamp(Math.round(Number(b?.radius) || 0), 0, 60), shadow: b?.shadow !== false, preset: typeof b?.preset === "string" ? b.preset : "aurora" });
export const fmtDuration = (ms: number) => { const s = Math.round(ms / 1000); return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`; };
