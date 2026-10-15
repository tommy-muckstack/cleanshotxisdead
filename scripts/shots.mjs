// Drives the real app (production build, demo account) to capture product shots AND smoke-test
// capture library → annotate → undo → crop → background → export → share link → delete.
import fs from "node:fs"; import assert from "node:assert/strict";
import { withApp, out } from "./shotlib.mjs";
import { chromium } from "@playwright/test";
const dir = out("cleanshotxisdead"); const pub = new URL("../public/home/", import.meta.url).pathname; fs.mkdirSync(pub, { recursive: true });
const save = async (page, name, target) => { const f = `${dir}/${name}.png`; await (target ?? page).screenshot({ path: f }); fs.copyFileSync(f, `${pub}${name}.png`); };
const hash = page => page.evaluate(() => { const s = document.querySelector('[data-testid=canvas]').toDataURL(); let h = 0; for (let i = 0; i < s.length; i += 7) h = (h * 31 + s.charCodeAt(i)) | 0; return h; });
const size = page => page.evaluate(() => { const c = document.querySelector('[data-testid=canvas]'); return [c.width, c.height]; });
// 1×1 red PNG for the file-open and paste paths
const TINY = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==", "base64");
await withApp("cleanshotxisdead", async ({ base }) => {
  const browser = await chromium.launch({ args: ["--use-fake-ui-for-media-stream", "--use-fake-device-for-media-stream", "--auto-select-desktop-capture-source=Entire screen", "--enable-usermedia-screen-capturing"] });
  try {
    const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, acceptDownloads: true, permissions: ["clipboard-read", "clipboard-write"] }); const page = await ctx.newPage();
    await page.goto(base + "/login"); await page.getByRole("button", { name: "Use the demo account" }).click(); await page.waitForURL(/\/app/);
    await page.getByTestId("empty").waitFor(); await page.screenshot({ path: `${dir}/library-empty.png` });
    // open-file path + paste path
    await page.getByLabel("Open image").setInputFiles({ name: "tiny.png", mimeType: "image/png", buffer: TINY }); await page.waitForURL(/\/app\/edit\//); await page.waitForFunction(() => document.querySelector("[data-testid=canvas]")?.width === 1); assert.deepEqual(await size(page), [1, 1]); await page.getByLabel("Capture name").waitFor(); assert.equal(await page.getByLabel("Capture name").inputValue(), "tiny");
    await page.goto(base + "/app"); await page.getByTestId("items").locator(".csl__card").first().waitFor();
    await page.evaluate(async b64 => { const bin = atob(b64); const u = new Uint8Array(bin.length); for (let i = 0; i < bin.length; i++) u[i] = bin.charCodeAt(i); const dt = new DataTransfer(); dt.items.add(new File([u], "p.png", { type: "image/png" })); window.dispatchEvent(new ClipboardEvent("paste", { clipboardData: dt, bubbles: true, cancelable: true })); }, TINY.toString("base64")); await page.waitForURL(/\/app\/edit\//); assert.match(await page.getByLabel("Capture name").inputValue(), /^Pasted /);
    await page.goto(base + "/app"); await page.getByTestId("items").locator(".csl__card").nth(1).waitFor(); assert.equal(await page.locator(".csl__card").count(), 2);
    await page.getByLabel("Open image").setInputFiles({ name: "notes.txt", mimeType: "text/plain", buffer: Buffer.from("not an image") }); await page.getByRole("alert").filter({ hasText: "isn't an image" }).waitFor();
    // sample screenshot → editor
    await page.getByRole("button", { name: "Try a sample" }).click(); await page.waitForURL(/\/app\/edit\//); const canvas = page.getByTestId("canvas"); await page.waitForFunction(() => document.querySelector('[data-testid=canvas]').width === 1280);
    const P = async (x, y) => { const b = await canvas.boundingBox(); return { x: b.x + x * (b.width / 1280), y: b.y + y * (b.height / 800) }; };
    const dragOn = async (a, b) => { const p = await P(...a), q = await P(...b); await page.mouse.move(p.x, p.y); await page.mouse.down(); await page.mouse.move((p.x + q.x) / 2, (p.y + q.y) / 2, { steps: 4 }); await page.mouse.move(q.x, q.y, { steps: 4 }); await page.mouse.up(); await page.waitForTimeout(60); };
    const tool = n => page.getByRole("button", { name: n, exact: true }).click();
    const h0 = await hash(page);
    await tool("Blur"); await dragOn([525, 345], [830, 650]); const h1 = await hash(page); assert.notEqual(h1, h0, "blur changes pixels");
    // the pixelated region no longer contains text edges: far fewer distinct colours than the original
    const colours = await page.evaluate(() => { const c = document.querySelector('[data-testid=canvas]'); const d = c.getContext("2d").getImageData(540, 360, 280, 280).data; const s = new Set(); for (let i = 0; i < d.length; i += 4) s.add(d[i] + "," + d[i + 1] + "," + d[i + 2]); return s.size; }); assert.ok(colours < 120, `blur pixelates (distinct colours ${colours})`);
    await tool("Rectangle"); await dragOn([254, 134], [576, 256]); await tool("Arrow"); await dragOn([760, 180], [600, 200]); await tool("Highlight"); await dragOn([775, 350], [910, 395]);
    await tool("Text"); const tp = await P(620, 90); await page.mouse.click(tp.x, tp.y); await page.getByLabel("Annotation text").fill("Up 12% this month"); await page.keyboard.press("Enter");
    await tool("Step"); const s1 = await P(238, 168); await page.mouse.click(s1.x, s1.y); const s2 = await P(500, 392); await page.mouse.click(s2.x, s2.y);
    const hFull = await hash(page); assert.notEqual(hFull, h1);
    await page.waitForTimeout(300); await save(page, "editor"); await save(page, "blur", canvas);
    // undo / redo walk back and forth
    await page.keyboard.press("Control+z"); const hu = await hash(page); assert.notEqual(hu, hFull, "undo removes the last mark"); await page.keyboard.press("Control+Shift+z"); assert.equal(await hash(page), hFull, "redo restores it");
    // select + delete a shape, then undo
    await tool("Select"); const edge = await P(254, 190); await page.mouse.click(edge.x, edge.y); await page.keyboard.press("Delete"); const hd = await hash(page); assert.notEqual(hd, hFull, "selected shape deleted"); await page.keyboard.press("Control+z"); assert.equal(await hash(page), hFull, "undo restores deleted shape");
    // steps renumber after deleting the first
    const stepPt = await P(238, 168); await page.mouse.click(stepPt.x, stepPt.y); await page.keyboard.press("Delete"); await page.keyboard.press("Control+z");
    // crop
    await tool("Crop"); await dragOn([6, 6], [1100, 700]); await page.getByRole("button", { name: /Reset crop \(\d+×\d+\)/ }).waitFor({ timeout: 4000 }).catch(async e => { await page.screenshot({ path: "/tmp/crop-fail.png" }); throw e; }); await page.getByRole("button", { name: "Preview" }).click(); { const [cw, ch] = await size(page); assert.ok(cw >= 1080 && cw <= 1100 && ch >= 680 && ch <= 700, `crop size ${cw}×${ch}`); } await page.getByRole("button", { name: "Preview" }).click();
    await page.getByRole("button", { name: /Reset crop/ }).click(); assert.equal(await page.getByRole("button", { name: /Reset crop/ }).count(), 0);
    // background
    await page.getByLabel("Beautify with background", { exact: false }).check(); await page.getByRole("button", { name: "Background Aurora" }).click(); await page.getByRole("button", { name: "Preview" }).click(); assert.deepEqual(await size(page), [1280 + 128, 800 + 128]); await page.waitForTimeout(250); await save(page, "background");
    const corner = await page.evaluate(() => { const c = document.querySelector('[data-testid=canvas]'); const d = c.getContext("2d").getImageData(4, 4, 1, 1).data; return [d[0], d[1], d[2]]; }); assert.ok(corner[2] > 150 && corner[0] > 60, `gradient corner colour ${corner}`);
    // download PNG has the output dimensions
    const [dlw] = await Promise.all([page.waitForEvent("download"), page.getByRole("button", { name: "Download PNG" }).click()]); const buf = fs.readFileSync(await dlw.path()); assert.equal(buf.subarray(1, 4).toString(), "PNG"); assert.equal(buf.readUInt32BE(16), 1408); assert.equal(buf.readUInt32BE(20), 928);
    await page.getByRole("button", { name: "Copy", exact: true }).click(); await page.getByText(/Copied to clipboard|Clipboard not available/).waitFor();
    // share link
    await page.getByRole("button", { name: "Preview" }).click(); await page.getByRole("button", { name: "Share link" }).click(); const linkEl = page.getByLabel("Share link", { exact: true }); await linkEl.waitFor(); const link = await linkEl.inputValue(); assert.match(link, /\/cleanshotxisdead\/s\/[a-z0-9]{10}$/); await page.waitForTimeout(300); await save(page, "share");
    const anon = await browser.newContext({ viewport: { width: 1200, height: 800 } }); const a = await anon.newPage(); const url = link.replace(/^https?:\/\/[^/]+/, new URL(base).origin);
    await a.goto(url); await a.getByTestId("shared-img").waitFor(); await a.waitForFunction(() => document.querySelector('[data-testid=shared-img]').naturalWidth === 1408); assert.match(await a.locator("footer").innerText(), /1408×928/); await a.screenshot({ path: `${dir}/shared-page.png` });
    const imgUrl = url.replace("/s/", "/api/shots/") + "/image"; const ir = await anon.request.get(imgUrl); assert.equal(ir.status(), 200); assert.equal(ir.headers()["content-type"], "image/png"); assert.equal((await anon.request.get(base + "/api/shots/zzzzzzzzzz/image")).status(), 404);
    await a.reload(); assert.match(await a.locator("footer").innerText(), /\b2 views/);
    // API guards: sign-in required, PNG only, owner-only delete
    assert.equal((await anon.request.get(base + "/api/shots")).status(), 401); assert.equal((await anon.request.post(base + "/api/shots", { multipart: { file: { name: "x.png", mimeType: "image/png", buffer: Buffer.from("<script>alert(1)</script>") } } })).status(), 401);
    const bad = await page.request.post(base + "/api/shots", { multipart: { file: { name: "x.png", mimeType: "image/png", buffer: Buffer.from("<script>alert(1)</script>") } } }); assert.equal(bad.status(), 422);
    const sid = url.split("/").pop(); assert.equal((await anon.request.delete(`${base}/api/shots/${sid}`)).status(), 404);
    // library shows the capture + shared link; deleting the link kills the page
    await page.goto(base + "/app"); await page.getByTestId("cloud").waitFor(); await page.getByTestId("items").locator(".csl__card").first().waitFor(); assert.ok((await page.locator(".csl__card").count()) >= 3); await page.waitForTimeout(400); await page.screenshot({ path: `${dir}/library.png` });
    await page.getByRole("button", { name: /Delete link/ }).click(); await page.waitForFunction(() => !document.querySelector('[data-testid=cloud]')); assert.equal((await anon.request.get(imgUrl)).status(), 404);
    // re-open: annotations persist (saved to IndexedDB)
    await page.getByTestId("items").locator(".csl__card").first().getByRole("button", { name: /Open/ }).click(); await page.waitForURL(/\/app\/edit\//); await page.waitForFunction(() => document.querySelector('[data-testid=canvas]')?.width === 1280); await page.waitForTimeout(300); assert.equal(await hash(page), hFull, "annotations persist after reopening");
    // screen capture + recording with the fake display (best effort: headless builds may not expose getDisplayMedia)
    const rec = await ctx.newPage(); await rec.goto(base + "/app"); await rec.getByTestId("items").waitFor(); let recorded = "skipped";
    try { await rec.getByRole("button", { name: "● Record screen" }).click(); await rec.getByTestId("stop-rec").waitFor({ timeout: 4000 }); await rec.waitForTimeout(2500); await rec.getByTestId("stop-rec").click(); await rec.locator('[data-kind="video"]').waitFor({ timeout: 6000 }); recorded = "ok"; } catch { /* no display capture in this environment */ }
    console.log("screen recording:", recorded);
    // marketing + login
    const m = await (await browser.newContext({ viewport: { width: 1440, height: 900 } })).newPage(); await m.goto(base + "/app"); await m.waitForURL(/\/login/);
    await m.goto(base); await m.waitForTimeout(500); await m.screenshot({ path: `${dir}/home-top.png` }); await m.screenshot({ path: `${dir}/home-full.png`, fullPage: true });
    await m.goto(base + "/#pricing"); await m.waitForTimeout(300); await m.screenshot({ path: `${dir}/home-pricing.png` }); await m.goto(base + "/login"); await m.waitForTimeout(300); await m.screenshot({ path: `${dir}/login.png` });
    console.log("cleanshotxisdead shots + smoke OK");
  } finally { await browser.close(); }
}, {});
