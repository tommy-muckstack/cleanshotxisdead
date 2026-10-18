import "@/vendor/isdead-design/css/cleanshotx.css";
import "@/vendor/isdead-design/css/components.css";
import "./globals.css";
import { site } from "@/site.config";
import { Analytics, LinkTracking } from "@/lib/analytics/posthog";
export const metadata = { title: `${site.name}: free, open-source ${site.replaces} alternative`, description: site.hero.subtitle, icons: { icon: "/cleanshotxisdead/favicon.svg" } };
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en" data-ids-theme="cleanshotx"><body className="ids-root">{children}<Analytics /><LinkTracking /></body></html>;
}
