import Link from "next/link";
import "./cshome.css";
import "./cspricing.css";
import { CsNav, CsDark, CsMark } from "./CsHome";
import { MeasuredPage } from "./m/MeasuredPage";
import pm from "./m/pricing390.json";

const Ic = () => <i className="ic" />;
const MAC: [string, string, string][] = [["Screenshots & screen recording", "✓", "✓"], ["Video Editor with smart zooms", "✓", "✓"], ["Annotation tools", "✓", "✓"], ["All app features included", "✓", "✓"]];
const CLOUD: [string, string, string][] = [["One-click upload and sharing", "✓", "✓"], ["Storage", "1 GB", "Unlimited"], ["Quality", "4K", "4K"], ["Video transcription", "✓", "✓"], ["Comments", "✓", "✓"], ["Custom domain and branding", "–", "✓"], ["Team management", "–", "✓"], ["SSO", "–", "✓"], ["SCIM", "–", "✓"], ["File access control", "–", "✓"], ["Password protection", "–", "✓"]];
const FAQ = ["Is the Cloud account required to use the app?", "What are the system requirements?", "Where can I find my license?", "Where can I get an invoice for my purchase?", "Does it support adding zooms to videos?", "How can I re-download the app?", "Is there a trial version?", "Is there a student discount?", "Does it work on Windows?", "How to transfer my license to a different Mac?", "How to add more devices to my license?"];
const Row = ({ r, y }: { r: [string, string, string]; y: number }) => <div className="rw" style={{ top: y }}><span>{r[0]}</span><b className={r[1] === "–" ? "d" : ""}>{r[1] === "✓" ? <u>✓</u> : r[1]}</b><b className={r[2] === "–" ? "d" : ""}>{r[2] === "✓" ? <u>✓</u> : r[2]}</b></div>;

export function CsPricing() {
  return <><MeasuredPage data={pm as never} className="cs-pm" img={(it) => it.y < 60 && it.w > 100 ? <span style={{ display: "flex", alignItems: "center", gap: 10, height: it.h }}><CsMark s={32} /><b style={{ fontSize: 19, letterSpacing: "-.01em", color: "#121317" }}>CleanShotX</b></span> : it.w >= 300 ? <div style={{ width: "100%", height: "100%", borderRadius: 20, background: it.y < 4000 ? "linear-gradient(135deg,#fde3dc,#fbc9c4 55%,#fcd9c8)" : it.y < 4300 ? "linear-gradient(135deg,#e6efff,#cfe0fd 60%,#a8c6fb)" : "linear-gradient(135deg,#f9e8f1,#f8d0e4 70%,#f6bfd9)" }} /> : it.w === 70 || it.w === 44 ? <div style={{ width: it.w, height: it.h, borderRadius: 16, background: it.y < 4000 ? "linear-gradient(135deg,#ffb12e,#ff5a64)" : it.y < 4300 ? "#2f5bff" : "transparent" }}>{it.y > 4300 ? <svg viewBox="0 0 44 70" width="44" height="70"><g fill="#ff3fd0"><rect x="14" y="2" width="16" height="16" rx="3" transform="rotate(45 22 10)" /><rect x="3" y="21" width="16" height="16" rx="3" transform="rotate(45 11 29)" /><rect x="25" y="21" width="16" height="16" rx="3" transform="rotate(45 33 29)" /><rect x="14" y="40" width="16" height="16" rx="3" transform="rotate(45 22 48)" /></g></svg> : null}</div> : it.w === 122 ? <div style={{ width: 122, height: 40, borderRadius: 8, background: "#000", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, fontSize: 15 }}>Open source</div> : it.w === 112 ? <CsMark s={112} /> : it.w > 20 && it.w <= 26 ? <svg viewBox="0 0 24 24" width="100%" height="100%" fill="none" stroke="#1750f2" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><rect x="3.5" y="3.5" width="17" height="17" rx="4.5" /><path d="M8 12h8M12 8v8" /></svg> : it.w < 20 ? <svg viewBox="0 0 16 16" width="100%" height="100%" fill="none" stroke="#6b6e76" strokeWidth="1.3" strokeLinecap="round"><rect x="2" y="5" width="12" height="7" rx="2" /><path d="M5 9h.01" /></svg> : null} /><div className="cs-home cs-pr mp-desk">
    <CsNav />
    <h1 className="ph">What CleanShot X <span>charges</span></h1>
    <p className="ps">These are CleanShot X&apos;s published plans, shown for comparison.<br />CleanShotXIsDead is free: no license, no subscription.</p>
    <div className="pc a"><div className="band">One-time payment</div>
      <div className="in"><h3>CleanShotX Basic</h3><div className="pp"><b>$35</b><small>Pay once, use forever.</small></div>
        <div className="f"><Ic />Mac app</div><div className="f"><Ic />One year of updates</div><div className="f"><Ic />Cloud</div><div className="f s"><Ic />1 GB storage</div>
        <p className="st">CleanShotXIsDead costs nothing.<br /><a>No license needed ›</a></p><Link href="/download" className="bb">Download free</Link></div></div>
    <div className="pc b"><div className="band">For teams and power users</div>
      <div className="in"><h3>CleanShotX Pro <span className="tg"><u>Yearly -17%</u><u className="o">Monthly</u></span></h3><div className="pp"><b>$10</b><small>per user/mo, billed annually</small></div>
        <div className="f"><Ic />Mac app</div><div className="f"><Ic />Always up to date</div><div className="f"><Ic />Cloud</div><div className="f s"><Ic />Unlimited storage</div><div className="f s"><Ic />Custom domain and branding</div><div className="f s"><Ic />Advanced sharing and security</div><div className="f"><Ic />Team</div><div className="f s"><Ic />Centralized access management</div><div className="f s"><Ic />SSO and SCIM</div>
        <Link href="/download" className="bb" style={{ top: 539 }}>Download free</Link></div></div>
    <p className="pn" style={{ top: 1130 }}>Prices in USD. Taxes may apply at checkout. The app requires macOS 13.0 or newer.</p>
    <p className="pn" style={{ top: 1160 }}>Cloud plans are subject to our fair use policy.</p>
    <div className="mb"><CsMark s={46} /><div><b>Free and open source</b><span>Nothing to buy and nothing to refund. Apache-2.0 on GitHub.</span></div><div className="rr"><b>$0</b> <small>for every feature</small></div></div>
    <h2 className="hd" style={{ top: 1574 }}>Compare plans</h2>
    <b className="ch" style={{ left: 727 }}>CleanShotX Basic</b><b className="ch" style={{ left: 1181 }}>CleanShotX Pro</b>
    <div className="sec" style={{ top: 1692 }}><Ic />Mac App</div>
    {MAC.map((r, i) => <Row key={r[0]} r={r} y={1780 + i * 57.4} />)}
    <div className="rw" style={{ top: 2009 }}><span>Updates</span><b>1 year<small>Optional renewal at $19 per year</small></b><b>Always up to date</b></div>
    <div className="sec" style={{ top: 2090 }}><Ic />Cloud</div>
    {CLOUD.map((r, i) => <Row key={r[0]} r={r} y={2174 + i * 57.4} />)}
    <div className="dc" style={{ left: 125 }}><i className="o1" /><h2>No license key</h2><p>The app is free for everyone, so there is nothing to activate.</p><Link href="/download">Download free</Link></div>
    <div className="dc" style={{ left: 528 }}><i className="o2" /><h2>No subscription</h2><p>Every feature is included, with no trial clock and no renewal.</p><Link href="/download">Download free</Link></div>
    <div className="dc" style={{ left: 931 }}><i className="o3" /><h2>Open source</h2><p>Apache-2.0 on GitHub. Read the code, report a bug or build it yourself.</p><a className="dk" href="https://github.com/tommy-muckstack/cleanshotxisdead">View the source</a></div>
    <h2 className="hd" style={{ top: 3382 }}>FAQ</h2><p className="fh" style={{ top: 3440 }}>Didn&apos;t find your answer?<br /><span>Reach out to us at support@example.com</span></p>
    {FAQ.map((q, i) => <div key={q} className="fq" style={{ top: 3388 + i * 71.1 }}>{q}<svg width="14" height="14" viewBox="0 0 14 14"><path d="M3 5l4 4 4-4" fill="none" stroke="#121317" strokeWidth="1.5" /></svg></div>)}
    <CsDark top={4226} />
  </div></>;
}
