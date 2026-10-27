import Link from "next/link";
import { Mark } from "./Mark";
import "./cshome.css";
import { MeasuredPage } from "./m/MeasuredPage";
import hm from "./m/home390.json";

export const CsMark = ({ s = 30 }: { s?: number }) => <Mark size={s} />;
export function CsNav() {
  return <header className="cs-nav"><Link href="/" className="lg"><CsMark /><b>CleanShotX</b></Link>
    <nav><a>Product <i>⌄</i></a><Link href="/pricing">Pricing</Link><a>License Manager</a><a>Support <i>⌄</i></a></nav>
    <Link href="/download" className="bn">Download</Link></header>;
}
const FC: [string, string[]][] = [["Product", ["All Features", "Changelog", "Open source", "URL scheme API"]], ["CleanShotX Cloud", ["About CleanShotX Cloud", "Log in to Cloud", "Security", "Terms of Service", "Privacy Policy", "Bug Bounty"]], ["License", ["Pricing", "Download"]], ["Support", ["Contact us", "FAQ", "Press kit", "Status Page", "YouTube"]]];
export function CsDark({ top }: { top: number }) {
  return <section className="cs-dark" style={{ top }}>
    <span className="app"><CsMark s={90} /></span>
    <h2>Upgrade your Mac screen<br />capture workflow today.</h2>
    <p className="sb">Free and open source. No account, no license, no subscription.</p>
    <Link href="/download" className="gb">Get CleanShotX for Mac</Link>
    <hr />
    <div className="nl"><b>Stay in the loop</b><span>New features, product news, and occasional deals. No spam.</span></div>
    <div className="em"><i>Your email</i><u>Subscribe</u><small>By subscribing, you agree to receive marketing emails from this app. You can unsubscribe anytime. See our Privacy policy.</small></div>
    <hr className="h2" />
    {FC.map(([h, ls], i) => <div key={h} className="fc" style={{ left: 68 + i * 332 }}><b>{h}</b>{ls.map((l) => <a key={l}>{l}</a>)}</div>)}
    <div className="cp">CleanShotXIsDead, an independent open-source project <span>Apache-2.0</span></div>
    <div className="so"><i /><i /></div>
  </section>;
}
export const CsFoot = CsDark;

type Th = string;
const Card = ({ x, y, w, h, th, t, d, children }: { x: number; y: number; w: number; h: number; th: Th; t: string; d?: string; children?: React.ReactNode }) =>
  <div className={"cd " + th} style={{ left: x, top: y, width: w, height: h }}><h3>{t}</h3>{d && <p>{d}</p>}{children}<span className="art" /></div>;
const Blk = ({ x, y, w, h, th, k = "" }: { x: number; y: number; w: number; h: number; th: string; k?: string }) => <div className={"blk " + th + " " + k} style={{ left: x, top: y, width: w, height: h }}><span className="win" /></div>;
const Head = ({ y, t, p, btn, w = 560, pill }: { y: number; t: string; p: string; btn?: string; w?: number; pill?: boolean }) =>
  <>
    <h2 className="hd" style={{ top: y }}>{t}{pill && <em className="pl">▷ Introducing Studio Mode</em>}</h2>
    <p className="sp" style={{ top: y + 62, width: w }}>{p}</p>
    {btn && <a className="eb" style={{ top: y + 78 }}>{btn}</a>}
  </>;
const Feat = ({ x, y, t, p, items, btn, k = "" }: { x: number; y: number; t: string; p: string; items?: string[]; btn?: string; k?: string }) =>
  <div className={"ft " + k} style={{ left: x, top: y }}><h2>{t}</h2><p>{p}</p>{items?.map((i) => <div key={i} className="it"><i />{i}</div>)}{btn && <a className="ob">{btn}</a>}</div>;

export function CsHome() {
  return <><MeasuredPage data={hm as never} className="cs-hm" img={(it) => it.y < 60 && it.w > 100 ? <span style={{ display: "flex", alignItems: "center", gap: 10, height: it.h }}><CsMark s={32} /><b style={{ fontSize: 19, letterSpacing: "-.01em", color: "#121317" }}>CleanShotX</b></span> : null} />
  <div className="cs-home mp-desk">
    <CsNav />
    <a className="intro">▷ Introducing Studio Mode</a>
    <h1 className="h1"><span>There are average capture apps.</span><br /><span>And there&apos;s CleanShotX.</span></h1>
    <p className="lede">The Mac-native toolkit for screenshots, recordings and collaboration. Free and open source.</p>
    <Link href="/download" className="b1">Get CleanShotX for Mac</Link><a className="b2">▷ How it works</a>
    <a className="gu">Free forever, no license needed ›</a>
    <div className="vid"><span className="pl">▶</span></div>
    <div className="tq"><p>Every feature is free. No account, no license key and no subscription, and the code is on GitHub for anyone to read.</p><div className="who"><i /><b>The CleanShotXIsDead promise<br /><small>Apache-2.0</small></b></div><span className="ar"><u>←</u><u>→</u></span></div>
    <p className="tr">Built in the open:</p>
    <div className="lgs">{["Free", "Open source", "Apache-2.0", "No account", "No license key"].map((l) => <span key={l}>{l}</span>)}</div>
    <Feat k="k1" x={124} y={1442} t="Always one drag away" p="Capture something and it's instantly ready to share. Save it, copy it, or drop it straight into any app. No folders to dig through, no flow to break." />
    <Blk x={635} y={1277} w={681} h={480} th="b-blue" />
    <Head y={1957} t="Screen recordings worth sharing" p="Record your screen in a few clicks, then export a polished video or a quick GIF. Everything you need to make it look great is already built in." btn="Explore recording" w={640} />
    <Card x={124} y={2140} w={583} h={417} th="c-peach" t="Add your camera" d="Add a webcam bubble to your recording so people see you, not just your screen." />
    <Card x={733} y={2140} w={279} h={417} th="c-sky" t="Highlight every click" d="Make clicks easy to follow with automatic highlights." />
    <Card x={1037} y={2140} w={279} h={417} th="c-sky2" t="Show keystrokes" d="Display shortcuts and key presses while you record." />
    <Card x={124} y={2582} w={280} h={418} th="c-navy" t="Voice and system audio" d="Capture what you say and what you hear, perfectly synced with your screen." />
    <Card x={428} y={2582} w={280} h={418} th="c-lav" t="MP4 or GIF" d="Export crisp videos or quick GIFs in seconds." />
    <Card x={733} y={2582} w={583} h={418} th="c-lav2" t="Smart zooms" d="Guide attention with automatically generated smooth zooms that highlight important details and make your recordings easier to follow." />
    <Head y={3201} t="Make your point, fast" p="Mark up details, hide sensitive information, add beautiful backgrounds, and crop when needed. All without leaving the app." btn="Explore screenshots" w={560} />
    <div className="car" style={{ top: 3385 }}>{[["Markup", "c-sky"], ["Redact", "c-lav"], ["Add Background", "c-sky2"], ["Crop", "c-sky"]].map(([t, th], i) => <div key={t} className={"cc " + th} style={{ left: 125 + i * 402 }}><b>{t}</b><span className="art" /></div>)}</div>
    <span className="cn" style={{ top: 3860 }}><u>←</u><u>→</u></span>
    <Head y={4097} t="Share with CleanShotX Cloud" p="Share screenshots and recordings with a link. Uploads go to the web app as a guest, so there is nothing to sign up for." btn="Explore CleanShotX Cloud" w={560} />
    <Card x={124} y={4280} w={583} h={420} th="c-blue" t="Share with one click" d="Upload any screenshot or recording and get a clean link instantly, ready to send anywhere." />
    <Card x={733} y={4280} w={279} h={420} th="c-lt" t="Public share links" />
    <Card x={1037} y={4280} w={279} h={420} th="c-navy" t="View counter on every link" />
    <Card x={125} y={4722} w={278} h={418} th="c-sky" t="No account needed" d="Uploads go up as a guest. There is nothing to sign up for and no storage plan to buy." />
    <Card x={428} y={4722} w={584} h={418} th="c-navy2" t="Opens in any browser" d="Share links open in the browser app, so anyone you send one to can view the capture." />
    <Card x={1037} y={4722} w={279} h={418} th="c-navy" t="No subscription" />
    <h2 className="hd" style={{ top: 5341 }}>Video Editor<em className="pl">▷ Introducing Studio Mode</em></h2>
    <p className="sp" style={{ top: 5403, width: 600 }}>Turn raw screen recordings into polished videos with a fast, Mac-native editor built right into CleanShotX. Add zooms, trim mistakes, and fine-tune every detail before you export.</p>
    <a className="eb" style={{ top: 5419 }}>Explore recording</a>
    <div className="blk b-black" style={{ left: 124, top: 5555, width: 1192, height: 550 }}><span className="win" /></div>
    <Feat k="k2" x={124} y={6342} t="Scrolling Capture" p="Capture full pages, long chats, documents, and code that stretch beyond your screen, all in one clean image." items={["Capture every scrollable content", "Works in every app"]} btn="Explore screenshots" />
    <Blk k="sc" x={635} y={6305} w={681} h={480} th="b-navy" />
    <Blk x={124} y={6985} w={681} h={480} th="b-black" />
    <Feat k="k3" x={884} y={6995} t="Background Tool" p="Turn plain screenshots into polished visuals with beautiful backgrounds, padding, shadows, and custom styles, ready to share anywhere." items={["Perfect for social posts and docs", "20 beautiful backgrounds included", "Create your own presets"]} btn="Learn more" />
    <Feat k="k4" x={124} y={7715} t="Text Recognition" p="Copy text from screenshots, images, and scanned documents in seconds, with fast on-device recognition built into the app." items={["Copy text from any image", "Read QR codes instantly", "Fast and private by design"]} />
    <Blk x={635} y={7665} w={681} h={480} th="b-navy" />
    <h2 className="hd" style={{ top: 8315 }}>Built for everyday Mac workflows</h2>
    <Card x={124} y={8403} w={583} h={418} th="c-navy2" t="Capture History" d="Never lose a screenshot or recording. Quickly find, restore, and reuse anything you captured before." />
    <Card x={733} y={8403} w={279} h={418} th="c-lav" t="Pin screenshots" d="Keep any screenshot visible above other windows while you compare, reference, or copy details." />
    <Card x={1037} y={8403} w={279} h={418} th="c-blue" t="Hide Desktop icons" />
    <Card x={124} y={8847} w={280} h={445} th="c-navy" t="Truly Mac-native" d="Built specifically for Mac, with speed, low memory use and battery life in mind." />
    <Card x={428} y={8847} w={280} h={445} th="c-lav2" t="Make it yours" d="Customize shortcuts, capture behavior, file formats, and sharing options to match the way you work." />
    <Card x={733} y={8847} w={583} h={445} th="c-blue" t="Designed exclusively for macOS" d="Every interaction is designed to feel less like an app and more like a natural part of macOS. No cross-platform compromises." />
    <a className="all" style={{ top: 9303 }}>Check all 50+ features ›</a>
    <p className="tl">Why it&apos;s free</p><h2 className="hd" style={{ top: 9609 }}>Made for Mac users</h2>
    <div className="rt"><b>$0</b><small>for every feature</small><a href="https://github.com/tommy-muckstack/cleanshotxisdead">View the source ›</a></div>
    <div className="tws" style={{ top: 9752 }}>{[["Free for everyone", "Every capture mode, the annotation editor, recording and share links are included. There is no paid tier to unlock."], ["Open source", "The Mac app and the web app are Apache-2.0 on GitHub. Read the code, report a bug or build it yourself."], ["Nothing to sign up for", "No account, no license key and no subscription. Download the app and start capturing."]].map(([n, t], i) => <div key={n} className="tw" style={{ left: 135 + i * 503 }}><i /><b>{n}</b><p>{t}</p></div>)}</div>
    <span className="cn" style={{ top: 10145 }}><u>←</u><u>→</u></span>
    <CsDark top={10302} />
  </div></>;
}
