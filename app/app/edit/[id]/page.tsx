import { currentUser } from "@/lib/session";
import { Editor } from "@/components/shot/Editor";
export default async function EditPage({ params }: { params: Promise<{ id: string }> }) { const u = (await currentUser())!; return <Editor userId={u.id} itemId={(await params).id} />; }
