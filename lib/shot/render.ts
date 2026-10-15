import type { Ann, Doc } from "./types";
import { PRESETS } from "./types";
import { arrowHead, gradientPoints, normRect, outputSize, STEP_R } from "./geometry";
const mk = (w: number, h: number) => { const c = document.createElement("canvas"); c.width = Math.max(1, Math.round(w)); c.height = Math.max(1, Math.round(h)); return c; };
export const textSize = (a: Ann) => 14 + a.width * 4;
function pixelate(ctx: CanvasRenderingContext2D, src: CanvasImageSource, x: number, y: number, w: number, h: number) {
  if (w < 2 || h < 2) return; const cell = Math.max(6, Math.round(Math.min(w, h) / 8)); const t = mk(Math.max(1, w / cell), Math.max(1, h / cell)); const tc = t.getContext("2d")!;
  tc.imageSmoothingEnabled = true; tc.drawImage(src, x, y, w, h, 0, 0, t.width, t.height);
  ctx.save(); ctx.beginPath(); ctx.rect(x, y, w, h); ctx.clip(); ctx.imageSmoothingEnabled = false; ctx.drawImage(t, 0, 0, t.width, t.height, x, y, w, h); ctx.restore();
}
export function drawAnn(ctx: CanvasRenderingContext2D, a: Ann, base: CanvasImageSource) {
  ctx.save(); ctx.lineCap = "round"; ctx.lineJoin = "round"; ctx.strokeStyle = a.color; ctx.fillStyle = a.color; ctx.lineWidth = a.width;
  const r = normRect(a.x1, a.y1, a.x2, a.y2);
  switch (a.type) {
    case "line": ctx.beginPath(); ctx.moveTo(a.x1, a.y1); ctx.lineTo(a.x2, a.y2); ctx.stroke(); break;
    case "arrow": { const hs = 10 + a.width * 3; ctx.beginPath(); ctx.moveTo(a.x1, a.y1); ctx.lineTo(a.x2, a.y2); ctx.stroke(); const [l, rr] = arrowHead(a.x1, a.y1, a.x2, a.y2, hs); ctx.beginPath(); ctx.moveTo(a.x2, a.y2); ctx.lineTo(l[0], l[1]); ctx.lineTo(rr[0], rr[1]); ctx.closePath(); ctx.fill(); break; }
    case "rect": ctx.strokeRect(r.x, r.y, r.w, r.h); break;
    case "ellipse": ctx.beginPath(); ctx.ellipse(r.x + r.w / 2, r.y + r.h / 2, Math.max(1, r.w / 2), Math.max(1, r.h / 2), 0, 0, Math.PI * 2); ctx.stroke(); break;
    case "highlight": ctx.globalAlpha = 0.38; ctx.fillStyle = a.color; ctx.fillRect(r.x, r.y, r.w, r.h); break;
    case "blur": pixelate(ctx, base, r.x, r.y, r.w, r.h); break;
    case "text": { const size = textSize(a); ctx.font = `600 ${size}px ui-sans-serif, system-ui, sans-serif`; ctx.textBaseline = "top"; const t = a.text ?? ""; const w = ctx.measureText(t).width; ctx.fillStyle = a.color === "#FFFFFF" ? "rgba(0,0,0,.55)" : "rgba(255,255,255,.0)"; if (a.color === "#FFFFFF") { ctx.fillRect(a.x1 - 6, a.y1 - 3, w + 12, size * 1.3 + 6); } ctx.fillStyle = a.color; ctx.shadowColor = a.color === "#FFFFFF" ? "transparent" : "rgba(255,255,255,.7)"; ctx.shadowBlur = 3; ctx.fillText(t, a.x1, a.y1); break; }
    case "step": { const rad = STEP_R(a); ctx.beginPath(); ctx.arc(a.x1, a.y1, rad, 0, Math.PI * 2); ctx.fill(); ctx.strokeStyle = "#fff"; ctx.lineWidth = 2.5; ctx.stroke(); ctx.fillStyle = a.color === "#FFFFFF" || a.color === "#FFCC00" ? "#111" : "#fff"; ctx.font = `700 ${rad * 1.15}px ui-sans-serif, system-ui, sans-serif`; ctx.textAlign = "center"; ctx.textBaseline = "middle"; ctx.fillText(String(a.n ?? 1), a.x1, a.y1 + 1); break; }
  }
  ctx.restore();
}
/** Paint the full uncropped image plus annotations at natural size (the editing surface). */
export function renderWorkspace(img: CanvasImageSource, w: number, h: number, anns: Ann[]): HTMLCanvasElement {
  const c = mk(w, h); const ctx = c.getContext("2d")!; ctx.drawImage(img, 0, 0, w, h); for (const a of anns) drawAnn(ctx, a, img); return c;
}
/** Final export: crop, annotations, optional background (gradient, padding, rounded corners, shadow). */
export function renderOutput(img: CanvasImageSource, w: number, h: number, d: Doc): HTMLCanvasElement {
  const ws = renderWorkspace(img, w, h, d.anns); const o = outputSize(w, h, d); const c = d.crop ?? { x: 0, y: 0, w, h };
  if (!d.bg.enabled) { const out = mk(c.w, c.h); out.getContext("2d")!.drawImage(ws, c.x, c.y, c.w, c.h, 0, 0, c.w, c.h); return out; }
  const out = mk(o.w, o.h); const ctx = out.getContext("2d")!; const p = PRESETS.find(x => x.id === d.bg.preset) ?? PRESETS[0]!; const g = gradientPoints(o.w, o.h, p.angle);
  const grad = ctx.createLinearGradient(g.x0, g.y0, g.x1, g.y1); grad.addColorStop(0, p.stops[0]); grad.addColorStop(1, p.stops[1]); ctx.fillStyle = grad; ctx.fillRect(0, 0, o.w, o.h);
  const rr = Math.min(d.bg.radius, c.w / 2, c.h / 2); const path = () => { ctx.beginPath(); ctx.roundRect(o.pad, o.pad, c.w, c.h, rr); };
  if (d.bg.shadow) { ctx.save(); ctx.shadowColor = "rgba(0,0,0,.45)"; ctx.shadowBlur = Math.max(12, o.pad * 0.6); ctx.shadowOffsetY = Math.max(6, o.pad * 0.25); ctx.fillStyle = "#000"; path(); ctx.fill(); ctx.restore(); }
  ctx.save(); path(); ctx.clip(); ctx.drawImage(ws, c.x, c.y, c.w, c.h, o.pad, o.pad, c.w, c.h); ctx.restore(); return out;
}
export const canvasToBlob = (c: HTMLCanvasElement, type = "image/png") => new Promise<Blob>((res, rej) => c.toBlob(b => (b ? res(b) : rej(new Error("export failed"))), type, 0.92));
/** A believable app window drawn with canvas, used as the demo "screenshot" (no external assets). */
export function sampleScreenshot(): HTMLCanvasElement {
  const W = 1280, H = 800, c = mk(W, H), x = c.getContext("2d")!; x.fillStyle = "#EEF1F6"; x.fillRect(0, 0, W, H);
  x.fillStyle = "#fff"; x.fillRect(0, 0, W, 56); x.fillStyle = "#E5E7EB"; x.fillRect(0, 56, W, 1); x.fillStyle = "#FF5F57"; x.beginPath(); x.arc(28, 28, 7, 0, 7); x.fill(); x.fillStyle = "#FEBC2E"; x.beginPath(); x.arc(52, 28, 7, 0, 7); x.fill(); x.fillStyle = "#28C840"; x.beginPath(); x.arc(76, 28, 7, 0, 7); x.fill();
  x.fillStyle = "#111827"; x.font = "600 18px ui-sans-serif, system-ui"; x.fillText("Acme Analytics", 120, 34);
  x.fillStyle = "#111827"; x.fillRect(0, 57, 220, H - 57); x.fillStyle = "#9CA3AF"; x.font = "500 15px ui-sans-serif, system-ui";
  ["Overview", "Customers", "Revenue", "Reports", "Settings"].forEach((t, i) => { if (i === 1) { x.fillStyle = "#1F2937"; x.fillRect(12, 88 + i * 44 - 22, 196, 38); x.fillStyle = "#fff"; } else x.fillStyle = "#9CA3AF"; x.fillText(t, 36, 88 + i * 44); });
  x.fillStyle = "#111827"; x.font = "700 28px ui-sans-serif, system-ui"; x.fillText("Customers", 260, 112);
  const cards = [["Active", "2,481"], ["New this week", "164"], ["Churn", "1.8%"]]; cards.forEach(([k, v], i) => { const cx = 260 + i * 330; x.fillStyle = "#fff"; x.fillRect(cx, 140, 310, 110); x.fillStyle = "#6B7280"; x.font = "500 15px ui-sans-serif, system-ui"; x.fillText(k!, cx + 20, 176); x.fillStyle = "#111827"; x.font = "700 36px ui-sans-serif, system-ui"; x.fillText(v!, cx + 20, 224); });
  x.fillStyle = "#fff"; x.fillRect(260, 280, 970, 480); x.fillStyle = "#6B7280"; x.font = "600 13px ui-sans-serif, system-ui"; ["NAME", "EMAIL", "PLAN", "MRR"].forEach((t, i) => x.fillText(t, 284 + [0, 250, 560, 780][i]!, 316)); x.fillStyle = "#E5E7EB"; x.fillRect(260, 330, 970, 1);
  const rows = [["Ana Diaz", "ana.diaz@acme-corp.com", "Team", "$480"], ["Bo Li", "bo.li@northwind.io", "Pro", "$96"], ["Cy Park", "cy@parkandco.com", "Team", "$480"], ["Di Wu", "di.wu@lumen.dev", "Starter", "$24"], ["Eli Ross", "eli@rossgroup.net", "Pro", "$96"]];
  rows.forEach((r, i) => { const y = 370 + i * 64; x.fillStyle = "#111827"; x.font = "500 16px ui-sans-serif, system-ui"; r.forEach((t, j) => x.fillText(t, 284 + [0, 250, 560, 780][j]!, y)); x.fillStyle = "#F3F4F6"; x.fillRect(260, y + 28, 970, 1); });
  return c;
}
