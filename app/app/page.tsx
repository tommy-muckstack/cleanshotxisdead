import { currentUser } from "@/lib/session";
import { Library } from "@/components/shot/Library";
export default async function AppHome() { const u = (await currentUser())!; return <Library userId={u.id} />; }
