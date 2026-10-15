import { getDoc, putDoc, listDocs, delDoc } from "@/lib/store";
export type CloudShot = { id: string; ownerId: string; name: string; createdAt: number; views: number; w: number; h: number; bytes: number };
export const MAX_BYTES = 5_000_000;
const PNG = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
export const isPng = (b: Uint8Array) => PNG.every((v, i) => b[i] === v);
/** PNG IHDR width/height without decoding. */
export const pngSize = (b: Uint8Array) => ({ w: ((b[16]! << 24) | (b[17]! << 16) | (b[18]! << 8) | b[19]!) >>> 0, h: ((b[20]! << 24) | (b[21]! << 16) | (b[22]! << 8) | b[23]!) >>> 0 });
const newId = () => Array.from(crypto.getRandomValues(new Uint8Array(10)), b => "abcdefghijkmnpqrstuvwxyz23456789"[b % 32]).join("");
export async function saveShot(ownerId: string, name: string, bytes: Uint8Array): Promise<CloudShot> {
  if (bytes.length > MAX_BYTES) throw new Error("Image is too large (5 MB max)"); if (bytes.length < 33 || !isPng(bytes)) throw new Error("Only PNG images can be shared");
  const { w, h } = pngSize(bytes); if (!w || !h || w > 12000 || h > 12000) throw new Error("Unsupported image size");
  const s: CloudShot = { id: newId(), ownerId, name: name.replace(/[^\w .-]/g, "").slice(0, 80) || "Screenshot", createdAt: Date.now(), views: 0, w, h, bytes: bytes.length };
  await putDoc("shots", s.id, s); await putDoc("shot-bytes", s.id, { b64: Buffer.from(bytes).toString("base64") }); return s;
}
export const getShot = (id: string) => getDoc<CloudShot>("shots", id);
export const listShots = async (ownerId: string) => (await listDocs<CloudShot>("shots")).filter(s => s.ownerId === ownerId).sort((a, b) => b.createdAt - a.createdAt);
export async function shotBytes(id: string) { const d = await getDoc<{ b64: string }>("shot-bytes", id); return d ? new Uint8Array(Buffer.from(d.b64, "base64")) : null; }
export async function bumpViews(s: CloudShot) { s.views++; await putDoc("shots", s.id, s); }
export async function deleteShot(id: string) { await delDoc("shots", id); await delDoc("shot-bytes", id); }
