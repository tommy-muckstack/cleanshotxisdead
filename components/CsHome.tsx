import Link from "next/link";
import "./cshome.css";

export const CsMark = ({ s = 30 }: { s?: number }) => <span className="cs-mark" style={{ width: s, height: s }}><svg width={s * .6} height={s * .6} viewBox="0 0 24 24" aria-hidden><path d="M4 9V5h4M20 9V5h-4M4 15v4h4M20 15v4h-4" fill="none" stroke="#fff" strokeWidth="2.4" strokeLinecap="round" /><circle cx="12" cy="12" r="3" fill="#fff" /></svg></span>;
export function CsNav() {
  return <header className="cs-nav"><Link href="/" className="lg"><CsMark /><b>CleanShot</b></Link>
    <nav><a>Product <i>⌄</i></a><Link href="/pricing">Pricing</Link><a>License Manager</a><a>Support <i>⌄</i></a></nav>
    <Link href="/login" className="li">Log in</Link><Link href="/login" className="bn">Buy now</Link></header>;
}
const FC: [string, string[]][] = [["Product", ["All Features", "Changelog", "Testimonials", "Affiliate Program", "Available discounts", "URL scheme API"]], ["CleanShot Cloud", ["About CleanShot Cloud", "Log in to Cloud", "Security", "Terms of Service", "Privacy Policy", "Bug Bounty"]], ["License", ["Pricing", "License Manager", "Buy additional seats", "EULA", "Download"]], ["Support", ["Contact us", "FAQ", "Press kit", "Status Page", "YouTube"]]];
export function CsDark({ top }: { top: number }) {
  return <section className="cs-dark" style={{ top }}>
    <span className="app"><CsMark s={90} /></span>
    <h2>Upgrade your Mac screen<br />capture workflow today.</h2>
    <p className="sb">Try CleanShot risk-free with our 30-day money-back guarantee.</p>
    <Link href="/login" className="gb">Get CleanShot X for Mac</Link>
    <hr />
    <div className="nl"><b>Stay in the loop</b><span>New features, product news, and occasional deals. No spam.</span></div>
    <div className="em"><i>Your email</i><u>Subscribe</u><small>By subscribing, you agree to receive marketing emails from this app. You can unsubscribe anytime. See our Privacy policy.</small></div>
    <hr className="h2" />
    {FC.map(([h, ls], i) => <div key={h} className="fc" style={{ left: 68 + i * 332 }}><b>{h}</b>{ls.map((l) => <a key={l}>{l}</a>)}</div>)}
    <div className="cp">Copyright © MTW <span>ISO 27001</span></div>
    <div className="so"><i /><i /></div>
  </section>;
}
export const CsFoot = CsDark;

type Th = string;
const Card = ({ x, y, w, h, th, t, d, children }: { x: number; y: number; w: number; h: number; th: Th; t: string; d?: string; children?: React.ReactNode }) =>
  <div className={"cd " + th} style={{ left: x, top: y, width: w, height: h }}><h3>{t}</h3>{d && <p>{d}</p>}{children}<span className="art" /></div>;
const Blk = ({ x, y, w, h, th }: { x: number; y: number; w: number; h: number; th: string }) => <div className={"blk " + th} style={{ left: x, top: y, width: w, height: h }}><span className="win" /></div>;
const Head = ({ y, t, p, btn, w = 560, pill }: { y: number; t: string; p: string; btn?: string; w?: number; pill?: boolean }) =>
  <>
    <h2 className="hd" style={{ top: y }}>{t}{pill && <em className="pl">▷ Introducing Studio Mode</em>}</h2>
    <p className="sp" style={{ top: y + 62, width: w }}>{p}</p>
    {btn && <a className="eb" style={{ top: y + 78 }}>{btn}</a>}
  </>;
const Feat = ({ x, y, t, p, items, btn }: { x: number; y: number; t: string; p: string; items?: string[]; btn?: string }) =>
  <div className="ft" style={{ left: x, top: y }}><h2>{t}</h2><p>{p}</p>{items?.map((i) => <div key={i} className="it"><i />{i}</div>)}{btn && <a className="ob">{btn}</a>}</div>;

export function CsHome() {
  return <div className="cs-home">
    <CsNav />
    <a className="intro">▷ Introducing Studio Mode</a>
    <h1 className="h1"><span>There are average capture apps.</span><br /><span>And there&apos;s CleanShot.</span></h1>
    <p className="lede">The Mac-native toolkit for screenshots, recordings and collaboration. Trusted by 250,000+ users.</p>
    <Link href="/login" className="b1">Get CleanShot for Mac</Link><a className="b2">▷ How it works</a>
    <a className="gu">30-Day Money-Back Guarantee ›</a>
    <div className="vid"><span className="pl">▶</span></div>
    <div className="tq"><p>This is an exceptionally well executed product. Quickly turned into my screenshot tool of choice. Bravo.</p><div className="who"><i /><b>Jason Fried<br /><small>Basecamp</small></b></div><span className="ar"><u>←</u><u>→</u></span></div>
    <p className="tr">Trusted by teams at:</p>
    <div className="lgs">{["linear", "Vercel", "CURSOR", "1Password", "Framer", "Basecamp"].map((l) => <span key={l}>{l}</span>)}</div>
    <Feat x={124} y={1442} t="Always one drag away" p="Capture something and it's instantly ready to share. Save it, copy it, or drop it straight into any app. No folders to dig through, no flow to break." />
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
    <Head y={4097} t="Share with CleanShot Cloud" p="Share screenshots and recordings instantly, gather feedback, and keep every capture easy to find, whether you work solo or with a team." btn="Explore CleanShot Cloud" w={560} />
    <Card x={124} y={4280} w={583} h={420} th="c-blue" t="Share with one click" d="Upload any screenshot or recording and get a clean link instantly, ready to send anywhere." />
    <Card x={733} y={4280} w={279} h={420} th="c-lt" t="Custom domain and branding" />
    <Card x={1037} y={4280} w={279} h={420} th="c-navy" t="Enterprise-grade security"><u className="iso">ISO 27001</u></Card>
    <Card x={125} y={4722} w={278} h={418} th="c-sky" t="Ready for teams" d="Start simple, then add SSO, SCIM, and admin controls when your team needs them." />
    <Card x={428} y={4722} w={584} h={418} th="c-navy2" t="Discuss in context" d="Leave comments directly on screenshots and recordings so feedback stays attached to the work." />
    <Card x={1037} y={4722} w={279} h={418} th="c-navy" t="Automatic transcripts" />
    <h2 className="hd" style={{ top: 5341 }}>Video Editor<em className="pl">▷ Introducing Studio Mode</em></h2>
    <p className="sp" style={{ top: 5403, width: 600 }}>Turn raw screen recordings into polished videos with a fast, Mac-native editor built right into CleanShot. Add zooms, trim mistakes, and fine-tune every detail before you export.</p>
    <a className="eb" style={{ top: 5419 }}>Explore recording</a>
    <div className="blk b-black" style={{ left: 124, top: 5555, width: 1192, height: 550 }}><span className="win" /></div>
    <Feat x={124} y={6342} t="Scrolling Capture" p="Capture full pages, long chats, documents, and code that stretch beyond your screen, all in one clean image." items={["Capture every scrollable content", "Works in every app"]} btn="Explore screenshots" />
    <Blk x={635} y={6305} w={681} h={480} th="b-navy" />
    <Blk x={124} y={6985} w={681} h={480} th="b-black" />
    <Feat x={884} y={6995} t="Background Tool" p="Turn plain screenshots into polished visuals with beautiful backgrounds, padding, shadows, and custom styles, ready to share anywhere." items={["Perfect for social posts and docs", "20 beautiful backgrounds included", "Create your own presets"]} btn="Learn more" />
    <Feat x={124} y={7715} t="Text Recognition" p="Copy text from screenshots, images, and scanned documents in seconds, with fast on-device recognition built into the app." items={["Copy text from any image", "Read QR codes instantly", "Fast and private by design"]} />
    <Blk x={635} y={7665} w={681} h={480} th="b-navy" />
    <h2 className="hd" style={{ top: 8315 }}>Built for everyday Mac workflows</h2>
    <Card x={124} y={8403} w={583} h={418} th="c-navy2" t="Capture History" d="Never lose a screenshot or recording. Quickly find, restore, and reuse anything you captured before." />
    <Card x={733} y={8403} w={279} h={418} th="c-lav" t="Pin screenshots" d="Keep any screenshot visible above other windows while you compare, reference, or copy details." />
    <Card x={1037} y={8403} w={279} h={418} th="c-blue" t="Hide Desktop icons" />
    <Card x={124} y={8847} w={280} h={445} th="c-navy" t="Truly Mac-native" d="Built specifically for Mac, with speed, low memory use and battery life in mind." />
    <Card x={428} y={8847} w={280} h={445} th="c-lav2" t="Make it yours" d="Customize shortcuts, capture behavior, file formats, and sharing options to match the way you work." />
    <Card x={733} y={8847} w={583} h={445} th="c-blue" t="Designed exclusively for macOS" d="Every interaction is designed to feel less like an app and more like a natural part of macOS. No cross-platform compromises." />
    <a className="all" style={{ top: 9303 }}>Check all 50+ features ›</a>
    <p className="tl">Testimonials</p><h2 className="hd" style={{ top: 9609 }}>Loved by Mac users</h2>
    <div className="rt"><b>4.9 <i>★★★★★</i></b><small>Based on user reviews</small><a>Check out 350+ tweets ›</a></div>
    <div className="tws" style={{ top: 9752 }}>{[["Steven Tey, Dub.co", "We've been long-time users of CleanShot at Dub! I literally cannot live without it anymore - every time I get a new Mac, CleanShot is the first app I install"], ["John O'Nolan, Ghost.org", "An absolutely essential tool for remote companies, where high quality annotated screenshots and recordings make up an enormous amount of team communication. I couldn't live without it."], ["Thomas Paul Mann, Raycast", "CleanShot lets me turn what's on my screen into something worth sharing. It's quick, polished and incredibly quick, and seamlessly"]].map(([n, t], i) => <div key={n} className="tw" style={{ left: 135 + i * 503 }}><i /><b>{n}</b><p>{t}</p></div>)}</div>
    <span className="cn" style={{ top: 10145 }}><u>←</u><u>→</u></span>
    <CsDark top={10302} />
  </div>;
}
