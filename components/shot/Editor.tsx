"use client";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { BP } from "@/lib/basepath";
import { track, EVENTS } from "@/lib/analytics";
import { getItem, putItem } from "@/lib/shot/db";
import { COLORS, emptyDoc, PRESETS, type Ann, type Doc, type Item, type Tool } from "@/lib/shot/types";
import { clampCrop, moveAnn, nextStep, normRect, renumber, rid, topHit, bounds } from "@/lib/shot/geometry";
import { canvasToBlob, renderOutput, renderWorkspace } from "@/lib/shot/render";
const TOOLS: { id: Tool; label: string; key: string; icon: string }[] = [
  { id: "select", label: "Select", key: "V", icon: "↖" }, { id: "arrow", label: "Arrow", key: "A", icon: "→" }, { id: "rect", label: "Rectangle", key: "R", icon: "▭" }, { id: "ellipse", label: "Ellipse", key: "O", icon: "◯" },
  { id: "line", label: "Line", key: "L", icon: "╱" }, { id: "text", label: "Text", key: "T", icon: "T" }, { id: "highlight", label: "Highlight", key: "H", icon: "▬" }, { id: "blur", label: "Blur", key: "B", icon: "▦" }, { id: "step", label: "Step", key: "N", icon: "①" }, { id: "crop", label: "Crop", key: "C", icon: "⌗" },
];
export function Editor({ userId, itemId }: { userId: string; itemId: string }) {
  const [item, setItem] = useState<Item | null | undefined>(undefined); const [doc, setDoc] = useState<Doc>(emptyDoc()); const [past, setPast] = useState<Doc[]>([]); const [future, setFuture] = useState<Doc[]>([]);
  const [tool, setTool] = useState<Tool>("arrow"); const [color, setColor] = useState(COLORS[0]!); const [width, setWidth] = useState(4); const [draft, setDraft] = useState<Ann | null>(null); const [sel, setSel] = useState<string | null>(null);
  const [view, setView] = useState<"edit" | "preview">("edit"); const [textEdit, setTextEdit] = useState<{ x: number; y: number; value: string } | null>(null); const [crop, setCrop] = useState<{ x: number; y: number; w: number; h: number } | null>(null);
  const [busy, setBusy] = useState(""); const [link, setLink] = useState<string | null>(null); const [msg, setMsg] = useState("");
  const cropRef = useRef<{ x: number; y: number; w: number; h: number } | null>(null); const img = useRef<HTMLImageElement | null>(null); const cv = useRef<HTMLCanvasElement>(null); const drag = useRef<null | { kind: "draw" | "move" | "crop"; sx: number; sy: number; last: { x: number; y: number }; id?: string }>(null); const loaded = useRef(false);
  useEffect(() => { let url = ""; (async () => { const it = await getItem(userId, itemId); if (!it || it.kind !== "image") { setItem(null); return; } url = URL.createObjectURL(it.blob); const im = new Image(); im.onload = () => { img.current = im; setDoc(it.doc ?? emptyDoc()); loaded.current = true; setItem(it); if (it.cloudId) setLink(`${location.origin}${BP}/s/${it.cloudId}`); }; im.src = url; })(); return () => { if (url) URL.revokeObjectURL(url); }; }, [userId, itemId]);
  const commit = useCallback((next: Doc) => { setPast(p => [...p.slice(-60), doc]); setFuture([]); setDoc(next); }, [doc]);
  const undo = () => setPast(p => { if (!p.length) return p; setFuture(f => [doc, ...f]); setDoc(p[p.length - 1]!); setSel(null); return p.slice(0, -1); });
  const redo = () => setFuture(f => { if (!f.length) return f; setPast(p => [...p, doc]); setDoc(f[0]!); return f.slice(1); });
  useEffect(() => { if (!item || !loaded.current) return; const t = setTimeout(() => putItem(userId, { ...item, doc }), 350); return () => clearTimeout(t); }, [doc]); // eslint-disable-line react-hooks/exhaustive-deps
  // paint
  useEffect(() => {
    const c = cv.current, im = img.current; if (!c || !im || !item) return;
    if (view === "preview") { const o = renderOutput(im, item.w, item.h, doc); c.width = o.width; c.height = o.height; c.getContext("2d")!.drawImage(o, 0, 0); return; }
    const ws = renderWorkspace(im, item.w, item.h, draft ? [...doc.anns, draft] : doc.anns); c.width = item.w; c.height = item.h; const ctx = c.getContext("2d")!; ctx.drawImage(ws, 0, 0);
    const cr = tool === "crop" && crop ? crop : doc.crop; if (cr) { ctx.save(); ctx.fillStyle = "rgba(0,0,0,.55)"; ctx.beginPath(); ctx.rect(0, 0, c.width, c.height); ctx.rect(cr.x, cr.y, cr.w, cr.h); ctx.fill("evenodd"); ctx.strokeStyle = "#fff"; ctx.setLineDash([8, 6]); ctx.lineWidth = 2; ctx.strokeRect(cr.x, cr.y, cr.w, cr.h); ctx.restore(); }
    const s = doc.anns.find(a => a.id === sel); if (s && !draft) { const b = bounds(s); ctx.save(); ctx.strokeStyle = "#0A84FF"; ctx.setLineDash([6, 4]); ctx.lineWidth = 2; ctx.strokeRect(b.x - 6, b.y - 6, b.w + 12, b.h + 12); ctx.restore(); }
  }, [doc, draft, sel, view, tool, crop, item]);
  const pt = (e: React.PointerEvent | PointerEvent) => { const c = cv.current!, r = c.getBoundingClientRect(); return { x: (e.clientX - r.left) * (c.width / r.width), y: (e.clientY - r.top) * (c.height / r.height) }; };
  const down = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (view !== "edit" || textEdit) return; const p = pt(e); e.currentTarget.setPointerCapture(e.pointerId);
    if (tool === "select") { const h = topHit(doc.anns, p.x, p.y); setSel(h?.id ?? null); if (h) { setPast(x => [...x.slice(-60), doc]); setFuture([]); drag.current = { kind: "move", sx: p.x, sy: p.y, last: p, id: h.id }; } return; }
    if (tool === "text") { e.preventDefault(); setTextEdit({ x: p.x, y: p.y, value: "" }); return; }
    if (tool === "step") { commit({ ...doc, anns: [...doc.anns, { id: rid(), type: "step", x1: p.x, y1: p.y, x2: p.x, y2: p.y, color, width, n: nextStep(doc.anns) }] }); return; }
    if (tool === "crop") { setCrop({ x: p.x, y: p.y, w: 0, h: 0 }); drag.current = { kind: "crop", sx: p.x, sy: p.y, last: p }; return; }
    drag.current = { kind: "draw", sx: p.x, sy: p.y, last: p }; setDraft({ id: rid(), type: tool as Ann["type"], x1: p.x, y1: p.y, x2: p.x, y2: p.y, color, width }); setSel(null);
  };
  const move = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const d = drag.current; if (!d) return; const p = pt(e);
    if (d.kind === "draw") setDraft(a => (a ? { ...a, x2: e.shiftKey && (a.type === "rect" || a.type === "ellipse") ? a.x1 + Math.sign(p.x - a.x1) * Math.max(Math.abs(p.x - a.x1), Math.abs(p.y - a.y1)) : p.x, y2: e.shiftKey && (a.type === "rect" || a.type === "ellipse") ? a.y1 + Math.sign(p.y - a.y1) * Math.max(Math.abs(p.x - a.x1), Math.abs(p.y - a.y1)) : p.y } : a));
    else if (d.kind === "crop") { const r = normRect(d.sx, d.sy, p.x, p.y); cropRef.current = r; setCrop(r); }
    else if (d.kind === "move") { const dx = p.x - d.last.x, dy = p.y - d.last.y; d.last = p; setDoc(x => ({ ...x, anns: x.anns.map(a => (a.id === d.id ? moveAnn(a, dx, dy) : a)) })); }
  };
  const up = () => {
    const d = drag.current; drag.current = null; if (!d) return;
    if (d.kind === "draw" && draft) { const big = Math.hypot(draft.x2 - draft.x1, draft.y2 - draft.y1) > 4; if (big) { commit({ ...doc, anns: [...doc.anns, draft] }); setSel(draft.id); } setDraft(null); }
    if (d.kind === "crop" && cropRef.current && item) { const c = clampCrop(cropRef.current, item.w, item.h); cropRef.current = null; if (c) commit({ ...doc, crop: c }); setCrop(null); }
  };
  const del = useCallback((id: string) => { commit({ ...doc, anns: renumber(doc.anns.filter(a => a.id !== id)) }); setSel(null); }, [commit, doc]);
  useEffect(() => {
    const k = (e: KeyboardEvent) => { const t = e.target as HTMLElement; if (t.tagName === "INPUT" || t.tagName === "TEXTAREA" || t.tagName === "SELECT") return;
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "z") { e.preventDefault(); e.shiftKey ? redo() : undo(); return; } if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "y") { e.preventDefault(); redo(); return; }
      if ((e.key === "Delete" || e.key === "Backspace") && sel) { e.preventDefault(); del(sel); return; }
      if (e.metaKey || e.ctrlKey || e.altKey) return; const tl = TOOLS.find(x => x.key.toLowerCase() === e.key.toLowerCase()); if (tl) setTool(tl.id); };
    window.addEventListener("keydown", k); return () => window.removeEventListener("keydown", k);
  });
  const commitText = () => { if (textEdit && textEdit.value.trim()) commit({ ...doc, anns: [...doc.anns, { id: rid(), type: "text", x1: textEdit.x, y1: textEdit.y, x2: textEdit.x, y2: textEdit.y, color, width: Math.max(2, Math.min(width, 8)), text: textEdit.value.trim() }] }); setTextEdit(null); };
  const exportBlob = async () => canvasToBlob(renderOutput(img.current!, item!.w, item!.h, doc));
  const flash = (m: string) => { setMsg(m); setTimeout(() => setMsg(""), 2200); };
  const download = async () => { const b = await exportBlob(); const a = document.createElement("a"); a.href = URL.createObjectURL(b); a.download = `${(item!.name || "screenshot").replace(/[^\w.-]+/g, "-")}.png`; a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 4000); flash("Downloaded"); track(EVENTS.app_editor_exported, { mode: "download", annotations: doc.anns.length }); };
  const copy = async () => { try { await navigator.clipboard.write([new ClipboardItem({ "image/png": await exportBlob() })]); flash("Copied to clipboard"); track(EVENTS.app_editor_exported, { mode: "copy", annotations: doc.anns.length }); } catch { flash("Clipboard not available here. Use Download."); } };
  const upload = async () => { setBusy("upload"); try { const fd = new FormData(); fd.set("file", await exportBlob(), "shot.png"); fd.set("name", item!.name); const r = await fetch(`${BP}/api/shots`, { method: "POST", body: fd }); const j = await r.json(); if (!r.ok) { flash(j.error ?? "Upload failed"); return; } const full = `${location.origin}${BP}${j.url}`; setLink(full); track(EVENTS.app_shared, { channel: "cloud", annotations: doc.anns.length }); const next = { ...item!, cloudId: j.shot.id, doc }; setItem(next); await putItem(userId, next); } finally { setBusy(""); } };
  const sorted = useMemo(() => TOOLS, []); const selAnn = doc.anns.find(a => a.id === sel);
  const setBg = (p: Partial<Doc["bg"]>) => commit({ ...doc, bg: { ...doc.bg, ...p } });
  if (item === undefined) return <p className="ids-muted" style={{ padding: 24 }}>Loading…</p>;
  if (item === null) return <div className="ids-card" style={{ margin: 40, padding: 32 }}><h2>Capture not found</h2><p className="ids-muted">It may have been deleted, or it lives in another browser.</p><Link href="/app">Back to library</Link></div>;
  return <div className="cse"><div className="cse__top"><Link href="/app" className="iconbtn" style={{ textDecoration: "none", color: "inherit" }}>← Library</Link>
    <input className="cse__name" aria-label="Capture name" value={item.name} onChange={e => { const n = { ...item, name: e.target.value }; setItem(n); putItem(userId, { ...n, doc }); }} />
    <div className="tb"><button className="iconbtn" onClick={undo} disabled={!past.length} aria-label="Undo">↶</button><button className="iconbtn" onClick={redo} disabled={!future.length} aria-label="Redo">↷</button>
      <button className={"iconbtn" + (view === "preview" ? " on" : "")} onClick={() => setView(v => (v === "edit" ? "preview" : "edit"))} aria-pressed={view === "preview"}>Preview</button></div><span style={{ flex: 1 }} />
    <span className="ids-muted" style={{ fontSize: 13 }} aria-live="polite">{msg}</span>
    <button className="iconbtn" onClick={copy}>Copy</button><button className="iconbtn" onClick={download}>Download PNG</button><button className="ids-btn ids-btn--primary ids-btn--sm" onClick={upload} disabled={busy === "upload"}>{busy ? "Uploading…" : "Share link"}</button></div>
    {link && <div className="cse__link" data-testid="share-link"><span>Shared:</span><input readOnly aria-label="Share link" value={link} onFocus={e => e.currentTarget.select()} /><button className="iconbtn" onClick={() => { navigator.clipboard.writeText(link).catch(() => {}); flash("Link copied"); }}>Copy link</button><button className="iconbtn" onClick={() => setLink(null)} aria-label="Hide link">×</button></div>}
    <div className="cse__body"><div className="cse__tools" role="toolbar" aria-label="Annotation tools">{sorted.map(t => <button key={t.id} className={"cse__tool" + (tool === t.id ? " on" : "")} aria-label={t.label} aria-pressed={tool === t.id} title={`${t.label} (${t.key})`} onClick={() => { setTool(t.id); if (t.id !== "select") setSel(null); }}>{t.icon}</button>)}</div>
      <main className="cse__stage"><div className="cse__canvas-wrap">
        <canvas ref={cv} className={"cse__canvas" + (view === "edit" ? ` tool-${tool}` : "")} data-testid="canvas" onPointerDown={down} onPointerMove={move} onPointerUp={up} onPointerCancel={up} style={{ aspectRatio: undefined }} />
        {textEdit && cv.current && <input autoFocus className="cse__text" aria-label="Annotation text" style={{ left: `${(textEdit.x / cv.current.width) * 100}%`, top: `${(textEdit.y / cv.current.height) * 100}%`, color }} value={textEdit.value} onChange={e => setTextEdit({ ...textEdit, value: e.target.value })} onKeyDown={e => { if (e.key === "Enter") commitText(); if (e.key === "Escape") setTextEdit(null); }} onBlur={commitText} />}</div></main>
      <aside className="cse__side" aria-label="Inspector">
        <h4>Style</h4><div className="cse__colors">{COLORS.map(c => <button key={c} className={"cse__sw" + (color === c ? " on" : "")} style={{ background: c }} aria-label={`Color ${c}`} onClick={() => { setColor(c); if (selAnn) commit({ ...doc, anns: doc.anns.map(a => (a.id === sel ? { ...a, color: c } : a)) }); }} />)}</div>
        <label className="cse__row">Size<input type="range" min={2} max={16} value={width} aria-label="Stroke size" onChange={e => setWidth(Number(e.target.value))} /></label>
        {selAnn && <button className="iconbtn" onClick={() => del(selAnn.id)}>Delete selected</button>}
        {doc.crop && <button className="iconbtn" onClick={() => commit({ ...doc, crop: null })}>Reset crop ({doc.crop.w}×{doc.crop.h})</button>}
        <h4>Background</h4><label className="cse__row"><input type="checkbox" checked={doc.bg.enabled} onChange={e => setBg({ enabled: e.target.checked })} /> Beautify with background</label>
        {doc.bg.enabled && <><div className="cse__presets">{PRESETS.map(p => <button key={p.id} className={"cse__pre" + (doc.bg.preset === p.id ? " on" : "")} style={{ background: `linear-gradient(135deg, ${p.stops[0]}, ${p.stops[1]})` }} aria-label={`Background ${p.name}`} onClick={() => setBg({ preset: p.id })} />)}</div>
          <label className="cse__row">Padding<input type="range" min={0} max={160} value={doc.bg.padding} aria-label="Padding" onChange={e => setBg({ padding: Number(e.target.value) })} /></label>
          <label className="cse__row">Corners<input type="range" min={0} max={40} value={doc.bg.radius} aria-label="Corner radius" onChange={e => setBg({ radius: Number(e.target.value) })} /></label>
          <label className="cse__row"><input type="checkbox" checked={doc.bg.shadow} onChange={e => setBg({ shadow: e.target.checked })} /> Shadow</label></>}
        <p className="ids-muted" style={{ fontSize: 12.5 }}>Shortcuts: V A R O L T H B N C · Delete · ⌘Z / ⇧⌘Z · hold Shift for squares.</p>
      </aside></div></div>;
}
