import { NextRequest, NextResponse } from "next/server";
import { currentUser } from "@/lib/session";
import { deleteShot, getShot } from "@/lib/shot/cloud";
export const runtime = "nodejs";
export async function DELETE(_: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const u = await currentUser(); const s = await getShot((await params).id); if (!u || !s || s.ownerId !== u.id) return NextResponse.json({ error: "Not found" }, { status: 404 });
  await deleteShot(s.id); return new NextResponse(null, { status: 204 });
}
