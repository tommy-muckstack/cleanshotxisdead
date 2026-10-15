import type { Item } from "./types";
/** Tiny IndexedDB wrapper: captures (image/video blobs + edit state) stay on this device, one database per account. */
const open = (user: string) => new Promise<IDBDatabase>((res, rej) => { const r = indexedDB.open(`cleanshotxisdead:${user}`, 1); r.onupgradeneeded = () => r.result.createObjectStore("items", { keyPath: "id" }); r.onsuccess = () => res(r.result); r.onerror = () => rej(r.error); });
const run = async <T,>(user: string, mode: IDBTransactionMode, f: (s: IDBObjectStore) => IDBRequest<T>) => { const db = await open(user); return new Promise<T>((res, rej) => { const r = f(db.transaction("items", mode).objectStore("items")); r.onsuccess = () => { res(r.result); db.close(); }; r.onerror = () => { rej(r.error); db.close(); }; }); };
export const putItem = (user: string, it: Item) => run(user, "readwrite", s => s.put(it));
export const getItem = (user: string, id: string) => run<Item | undefined>(user, "readonly", s => s.get(id));
export const allItems = async (user: string) => ((await run<Item[]>(user, "readonly", s => s.getAll())) ?? []).sort((a, b) => b.createdAt - a.createdAt);
export const delItem = (user: string, id: string) => run(user, "readwrite", s => s.delete(id));
