import Link from "next/link";
import "./cshome.css";
import "./cspricing.css";
import { CsNav, CsDark, CsMark } from "./CsHome";

const Ic = () => <i className="ic" />;
const MAC: [string, string, string][] = [["Screenshots & screen recording", "✓", "✓"], ["Video Editor with smart zooms", "✓", "✓"], ["Annotation tools", "✓", "✓"], ["All app features included", "✓", "✓"]];
const CLOUD: [string, string, string][] = [["One-click upload and sharing", "✓", "✓"], ["Storage", "1 GB", "Unlimited"], ["Quality", "4K", "4K"], ["Video transcription", "✓", "✓"], ["Comments", "✓", "✓"], ["Custom domain and branding", "–", "✓"], ["Team management", "–", "✓"], ["SSO", "–", "✓"], ["SCIM", "–", "✓"], ["File access control", "–", "✓"], ["Password protection", "–", "✓"]];
const FAQ = ["Is the Cloud account required to use the app?", "What are the system requirements?", "Where can I find my license?", "Where can I get an invoice for my purchase?", "Does it support adding zooms to videos?", "How can I re-download the app?", "Is there a trial version?", "Is there a student discount?", "Does it work on Windows?", "How to transfer my license to a different Mac?", "How to add more devices to my license?"];
const Row = ({ r, y }: { r: [string, string, string]; y: number }) => <div className="rw" style={{ top: y }}><span>{r[0]}</span><b className={r[1] === "–" ? "d" : ""}>{r[1] === "✓" ? <u>✓</u> : r[1]}</b><b className={r[2] === "–" ? "d" : ""}>{r[2] === "✓" ? <u>✓</u> : r[2]}</b></div>;

export function CsPricing() {
  return <div className="cs-home cs-pr">
    <CsNav />
    <h1 className="ph">Choose your <span>setup</span></h1>
    <p className="ps">Both plans include the full Mac app.<br />Pro adds unlimited Cloud storage, custom branding, and team features.</p>
    <div className="pc a"><div className="band">One-time payment</div>
      <div className="in"><h3>CleanShot Basic</h3><div className="pp"><b>$35</b><small>Pay once, use forever.</small></div>
        <div className="f"><Ic />Mac app</div><div className="f"><Ic />One year of updates</div><div className="f"><Ic />Cloud</div><div className="f s"><Ic />1 GB storage</div>
        <p className="st">Are you a student or PixelSnap 2 user?<br /><a>Get a discount ›</a></p><Link href="/login" className="bb">Buy now</Link></div></div>
    <div className="pc b"><div className="band">For teams and power users</div>
      <div className="in"><h3>CleanShot Pro <span className="tg"><u>Yearly -17%</u><u className="o">Monthly</u></span></h3><div className="pp"><b>$10</b><small>per user/mo, billed annually</small></div>
        <div className="f"><Ic />Mac app</div><div className="f"><Ic />Always up to date</div><div className="f"><Ic />Cloud</div><div className="f s"><Ic />Unlimited storage</div><div className="f s"><Ic />Custom domain and branding</div><div className="f s"><Ic />Advanced sharing and security</div><div className="f"><Ic />Team</div><div className="f s"><Ic />Centralized access management</div><div className="f s"><Ic />SSO and SCIM</div>
        <Link href="/login" className="bb" style={{ top: 539 }}>Start a subscription</Link></div></div>
    <p className="pn" style={{ top: 1130 }}>Prices in USD. Taxes may apply at checkout. The app requires macOS 13.0 or newer.</p>
    <p className="pn" style={{ top: 1160 }}>Cloud plans are subject to our fair use policy.</p>
    <div className="mb"><CsMark s={46} /><div><b>30-Day Money-Back Guarantee</b><span>Try it risk-free. If it&apos;s not the right fit, just let us know.</span></div><div className="rr"><b>4.9</b> <i>★★★★★</i> <small>Based on user reviews</small></div></div>
    <h2 className="hd" style={{ top: 1574 }}>Compare plans</h2>
    <b className="ch" style={{ left: 727 }}>CleanShot Basic</b><b className="ch" style={{ left: 1181 }}>CleanShot Pro</b>
    <div className="sec" style={{ top: 1692 }}><Ic />Mac App</div>
    {MAC.map((r, i) => <Row key={r[0]} r={r} y={1780 + i * 57.4} />)}
    <div className="rw" style={{ top: 2009 }}><span>Updates</span><b>1 year<small>Optional renewal at $19 per year</small></b><b>Always up to date</b></div>
    <div className="sec" style={{ top: 2090 }}><Ic />Cloud</div>
    {CLOUD.map((r, i) => <Row key={r[0]} r={r} y={2174 + i * 57.4} />)}
    <div className="dc" style={{ left: 125 }}><i className="o1" /><h2>PixelSnap 2 users</h2><p>Enjoy 20% off CleanShot as an existing PixelSnap customer.</p><a>Get a discount</a></div>
    <div className="dc" style={{ left: 528 }}><i className="o2" /><h2>Student discount</h2><p>Get 30% off with your university-issued email address.</p><a>Get a discount</a></div>
    <div className="dc" style={{ left: 931 }}><i className="o3" /><h2>Download with Setapp</h2><p>Get CleanShot with one Setapp subscription, alongside 200+ Mac apps.</p><a className="dk">Available on Setapp</a></div>
    <h2 className="hd" style={{ top: 3382 }}>FAQ</h2><p className="fh" style={{ top: 3440 }}>Didn&apos;t find your answer?<br /><span>Reach out to us at support@example.com</span></p>
    {FAQ.map((q, i) => <div key={q} className="fq" style={{ top: 3388 + i * 71.1 }}>{q}<svg width="14" height="14" viewBox="0 0 14 14"><path d="M3 5l4 4 4-4" fill="none" stroke="#121317" strokeWidth="1.5" /></svg></div>)}
    <CsDark top={4226} />
  </div>;
}
