import { notFound } from "next/navigation";
import Link from "next/link";
import { getShot, bumpViews } from "@/lib/shot/cloud";
import { BP } from "@/lib/basepath";
import { Logo } from "@/components/Logo";
import { TrackOnMount, EVENTS } from "@/lib/analytics";
export const dynamic = "force-dynamic";
export async function generateMetadata({ params }: { params: Promise<{ id: string }> }) { const s = await getShot((await params).id); return { title: s ? `${s.name} · CleanShotXIsDead` : "Not found", robots: { index: false } }; }
export default async function SharedShot({ params }: { params: Promise<{ id: string }> }) {
  const id = (await params).id; const s = /^[a-z0-9]{6,20}$/.test(id) ? await getShot(id) : null; if (!s) notFound(); await bumpViews(s);
  return <main className="cs-share"><TrackOnMount event={EVENTS.app_shot_viewed} /><header><Link href="/" style={{ color: "inherit", textDecoration: "none" }}><Logo size={24} /></Link><a className="ids-btn ids-btn--secondary ids-btn--sm" href={`${BP}/api/shots/${s.id}/image`} download={`${s.name}.png`}>Download</a></header>
    <div className="cs-share__img"><img src={`${BP}/api/shots/${s.id}/image`} alt={s.name} width={s.w} height={s.h} data-testid="shared-img" /></div>
    <footer><b>{s.name}</b><span className="ids-muted">{s.w}×{s.h} · {(s.bytes / 1024).toFixed(0)} KB · {s.views} view{s.views === 1 ? "" : "s"} · {new Date(s.createdAt).toLocaleDateString()}</span></footer></main>;
}
