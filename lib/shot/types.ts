export type Tool = "select" | "arrow" | "rect" | "ellipse" | "line" | "text" | "highlight" | "blur" | "step" | "crop";
export type Ann = { id: string; type: Exclude<Tool, "select" | "crop">; x1: number; y1: number; x2: number; y2: number; color: string; width: number; text?: string; n?: number };
export type Crop = { x: number; y: number; w: number; h: number };
export type Background = { enabled: boolean; padding: number; radius: number; shadow: boolean; preset: string };
export type Doc = { anns: Ann[]; crop: Crop | null; bg: Background };
export const DEFAULT_BG: Background = { enabled: false, padding: 64, radius: 14, shadow: true, preset: "aurora" };
export const emptyDoc = (): Doc => ({ anns: [], crop: null, bg: { ...DEFAULT_BG } });
export const PRESETS: { id: string; name: string; stops: [string, string]; angle: number }[] = [
  { id: "aurora", name: "Aurora", stops: ["#7C3AED", "#06B6D4"], angle: 135 }, { id: "sunset", name: "Sunset", stops: ["#F97316", "#EC4899"], angle: 135 }, { id: "mint", name: "Mint", stops: ["#10B981", "#A7F3D0"], angle: 160 },
  { id: "night", name: "Night", stops: ["#0F172A", "#334155"], angle: 160 }, { id: "peach", name: "Peach", stops: ["#FDBA74", "#FDE68A"], angle: 120 }, { id: "ocean", name: "Ocean", stops: ["#2563EB", "#22D3EE"], angle: 45 },
];
export const COLORS = ["#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#0A84FF", "#AF52DE", "#FFFFFF", "#111111"];
export type Item = { id: string; kind: "image" | "video"; name: string; createdAt: number; w: number; h: number; blob: Blob; doc?: Doc; cloudId?: string; durationMs?: number };
