import { NextResponse } from "next/server";
/** Every "Download" CTA lands here: the latest signed + notarized Mac build on GitHub Releases. */
const DOWNLOAD_URL = "https://github.com/tommy-muckstack/cleanshotxisdead/releases/latest/download/CleanShotXIsDead.dmg";
export const dynamic = "force-static";
export function GET() { return NextResponse.redirect(DOWNLOAD_URL, 307); }
