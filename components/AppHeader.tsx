"use client";
import Link from "next/link";
import { Logo } from "@/components/Logo";
import { BP } from "@/lib/basepath";
import { IdentifyUser, onSignOutSubmit } from "@/lib/analytics";
export function AppHeader({ user, children }: { user: { id: string; name: string; email: string; demo: boolean; guest?: boolean }; children?: React.ReactNode }) {
  return <header className="app-hd"><IdentifyUser id={user.id} kind={user.guest ? "guest" : user.demo ? "demo" : "firebase"} /><Link href="/app" style={{ color: "inherit", textDecoration: "none" }}><Logo size={26} /></Link>
    <div className="app-hd__mid">{children}</div>
    <div className="app-hd__user"><span className="ids-muted" style={{ fontSize: 13 }}>{user.guest ? "Guest · sign in to keep your work" : user.demo ? "Demo account" : user.email}</span>
      <form method="post" action={`${BP}/api/session/logout`} onSubmit={onSignOutSubmit}><button className="ids-btn ids-btn--ghost ids-btn--sm">Sign out</button></form></div></header>;
}
