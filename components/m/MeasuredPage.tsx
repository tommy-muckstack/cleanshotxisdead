import Link from "next/link";
import "./measured.css";

// Renders a layout JSON produced by scripts/m2json.mjs (the original's 390px geometry) with absolute positioning.
// Use it for the <=900px variant of a page: wrap in <div className="mp-wrap"> next to the desktop markup (hidden at <=900px via .mp-desk).
type Item = { k: "t" | "b" | "svg" | "img"; x: number; y: number; w: number; h: number; z?: number; t?: string; fs?: string; lh?: string; fw?: string; c?: string; ls?: string; ta?: string; td?: string; fi?: number; href?: number; bg?: string; bi?: string; bd?: string; bs?: string; bp?: string; br?: string; r?: string; sh?: string; svg?: string; alt?: string };
export type Measured = { H: number; bg?: string; items: Item[] };
const CHECK = '<svg viewBox="0 0 20 20" width="100%" height="100%" fill="none" stroke="#121317" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"><circle cx="10" cy="10" r="7.5"/><path d="M6.8 10.2l2.2 2.2 4.2-4.6"/></svg>';
const CTA = /get|buy|log ?in|sign|start|subscribe|download|try|contact/i;

export function MeasuredPage({ data, className = "", skip, img, bgFallback = "linear-gradient(180deg,#dbe8ff,#f5f8ff 60%,#fff)" }: { data: Measured; className?: string; skip?: (i: Item) => boolean; img?: (i: Item, style: React.CSSProperties) => React.ReactNode; bgFallback?: string | ((i: Item) => string) }) {
  const items = data.items.filter(i => !(skip && skip(i)));
  return <div className={`mp ${className}`} style={{ height: data.H, background: data.bg && !/0, 0, 0, 0\)/.test(data.bg) ? data.bg : "#fff" }}>
    {items.map((it, i) => {
      const pos = { left: it.x, top: it.y, width: it.w, height: it.h, zIndex: it.z ?? 0 } as React.CSSProperties;
      if (it.k === "b") return <div key={i} className="mp-b" style={{ ...pos, background: [it.bi?.includes('url("http') ? (typeof bgFallback === "function" ? bgFallback(it) : bgFallback) : it.bi, it.bg].filter(Boolean).join(",") || undefined, backgroundSize: it.bs, backgroundPosition: it.bp, backgroundRepeat: it.br, border: it.bd, borderRadius: it.r, boxShadow: it.sh }} />;
      if (it.k === "svg") return <div key={i} className="mp-i" style={pos} dangerouslySetInnerHTML={{ __html: it.svg! }} />;
      if (it.k === "img" && img) { const r = img(it, pos); if (r) return <div key={i} style={{ position: "absolute", ...pos }}>{r}</div>; }
      if (it.k === "img") return it.w <= 20 ? <div key={i} className="mp-i" style={pos} dangerouslySetInnerHTML={{ __html: CHECK }} /> : <div key={i} className="mp-ph" style={{ ...pos, borderRadius: it.r || (it.w < 130 ? "16px" : "12px") }} />;
      const style = { left: it.x, top: it.y, minWidth: it.w, height: it.h, zIndex: it.z ?? 3, fontSize: it.fs, lineHeight: it.lh, fontWeight: it.fw, color: it.c, letterSpacing: it.ls, textDecoration: it.td, fontStyle: it.fi ? "italic" : undefined } as React.CSSProperties;
      return it.href ? <Link key={i} href={CTA.test(it.t || "") ? "/login" : "/"} className="mp-t" style={style}>{it.t}</Link> : <span key={i} className="mp-t" style={style}>{it.t}</span>;
    })}
  </div>;
}
