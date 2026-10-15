import { NextRequest, NextResponse } from "next/server";
import { currentUser } from "@/lib/session";
import { listShots, saveShot } from "@/lib/shot/cloud";
export const runtime = "nodejs";
export async function GET() { const u = await currentUser(); if (!u) return NextResponse.json({ error: "Sign in required" }, { status: 401 }); return NextResponse.json({ shots: await listShots(u.id) }); }
export async function POST(req: NextRequest) {
  const u = await currentUser(); if (!u) return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  try { const fd = await req.formData(); const f = fd.get("file"); if (!(f instanceof File)) return NextResponse.json({ error: "No image" }, { status: 400 });
    const s = await saveShot(u.id, String(fd.get("name") ?? "Screenshot"), new Uint8Array(await f.arrayBuffer())); return NextResponse.json({ shot: s, url: `/s/${s.id}` }, { status: 201 });
  } catch (e) { return NextResponse.json({ error: (e as Error).message }, { status: 422 }); }
}
