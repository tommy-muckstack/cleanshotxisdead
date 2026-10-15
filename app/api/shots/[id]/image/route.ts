import { NextRequest, NextResponse } from "next/server";
import { getShot, shotBytes } from "@/lib/shot/cloud";
export const runtime = "nodejs";
export async function GET(_: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params; if (!/^[a-z0-9]{6,20}$/.test(id)) return NextResponse.json({ error: "Not found" }, { status: 404 });
  const s = await getShot(id); const b = s && (await shotBytes(id)); if (!s || !b) return NextResponse.json({ error: "Not found" }, { status: 404 });
  return new NextResponse(Buffer.from(b), { headers: { "content-type": "image/png", "cache-control": "public, max-age=3600", "x-content-type-options": "nosniff" } });
}
