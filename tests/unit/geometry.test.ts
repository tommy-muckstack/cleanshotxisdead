import { describe, it, expect } from "vitest";
import type { Ann, Doc } from "@/lib/shot/types";
import { emptyDoc } from "@/lib/shot/types";
import { arrowHead, bounds, clampCrop, distToSegment, fmtDuration, gradientPoints, hit, moveAnn, nextStep, normRect, outputSize, renumber, sanitizeBg, topHit } from "@/lib/shot/geometry";
const A = (o: Partial<Ann>): Ann => ({ id: "a", type: "rect", x1: 0, y1: 0, x2: 100, y2: 50, color: "#f00", width: 4, ...o });
describe("geometry", () => {
  it("normalises rects from any drag direction", () => { expect(normRect(50, 40, 10, 10)).toEqual({ x: 10, y: 10, w: 40, h: 30 }); });
  it("arrow barbs are symmetric about the shaft and point backwards", () => {
    const [l, r] = arrowHead(0, 0, 100, 0, 20); expect(l[0]).toBeCloseTo(r[0]); expect(l[1]).toBeCloseTo(-r[1]); expect(l[0]).toBeLessThan(100); expect(Math.hypot(100 - l[0], l[1])).toBeCloseTo(20);
  });
  it("distance to segment (interior and endpoints)", () => { expect(distToSegment(5, 3, 0, 0, 10, 0)).toBe(3); expect(distToSegment(-4, 3, 0, 0, 10, 0)).toBe(5); expect(distToSegment(1, 1, 2, 2, 2, 2)).toBeCloseTo(Math.SQRT2); });
  it("hit-testing: outlines for shapes, fills for blur/highlight, circles for steps", () => {
    const r = A({ x2: 200, y2: 100 }); expect(hit(r, 100, 0)).toBe(true); expect(hit(r, 100, 50)).toBe(false); expect(hit(r, 400, 400)).toBe(false);
    expect(hit(A({ type: "blur", x2: 200, y2: 100 }), 100, 50)).toBe(true); expect(hit(A({ type: "arrow", x2: 100, y2: 0 }), 50, 5)).toBe(true); expect(hit(A({ type: "arrow", x2: 100, y2: 0 }), 50, 40)).toBe(false);
    const s = A({ type: "step", x1: 50, y1: 50, n: 1 }); expect(hit(s, 55, 55)).toBe(true); expect(hit(s, 120, 50)).toBe(false);
    const e = A({ type: "ellipse", x2: 200, y2: 100 }); expect(hit(e, 100, 0)).toBe(true); expect(hit(e, 100, 50)).toBe(false);
  });
  it("topHit prefers the most recently drawn annotation", () => { const a = A({ id: "1", type: "blur", x2: 100, y2: 100 }), b = A({ id: "2", type: "blur", x2: 100, y2: 100 }); expect(topHit([a, b], 50, 50)!.id).toBe("2"); expect(topHit([a, b], 500, 500)).toBeNull(); });
  it("moves every coordinate", () => { expect(moveAnn(A({}), 5, -5)).toMatchObject({ x1: 5, y1: -5, x2: 105, y2: 45 }); });
  it("numbers steps and renumbers after deletes", () => {
    const s = (id: string, n: number) => A({ id, type: "step", n }); expect(nextStep([])).toBe(1); expect(nextStep([s("a", 1), A({ id: "r" }), s("b", 2)])).toBe(3);
    expect(renumber([s("a", 1), s("b", 5), A({ id: "r" }), s("c", 9)]).filter(x => x.type === "step").map(x => x.n)).toEqual([1, 2, 3]);
  });
  it("clamps and rejects tiny crops", () => { expect(clampCrop({ x: -10, y: 5, w: 5000, h: 100 }, 800, 600)).toEqual({ x: 0, y: 5, w: 800, h: 100 }); expect(clampCrop({ x: 10, y: 10, w: 3, h: 300 }, 800, 600)).toBeNull(); });
  it("output size accounts for crop and background padding", () => {
    const d: Doc = emptyDoc(); expect(outputSize(800, 600, d)).toMatchObject({ w: 800, h: 600, pad: 0 }); d.crop = { x: 0, y: 0, w: 400, h: 300 }; d.bg.enabled = true; d.bg.padding = 50; expect(outputSize(800, 600, d)).toMatchObject({ w: 500, h: 400, innerW: 400, pad: 50 });
  });
  it("gradient line spans the box for common angles", () => { const g = gradientPoints(200, 100, 90); expect(g.y0).toBeCloseTo(50); expect(g.y1).toBeCloseTo(50); expect(g.x0).toBeCloseTo(0); expect(g.x1).toBeCloseTo(200); });
  it("sanitises background settings and bounds text", () => { expect(sanitizeBg({ padding: 9999, radius: -4, enabled: true })).toMatchObject({ padding: 240, radius: 0, enabled: true, shadow: true }); expect(bounds(A({ type: "text", text: "Hello", x1: 10, y1: 20 })).x).toBe(10); });
  it("formats recording durations", () => { expect(fmtDuration(0)).toBe("0:00"); expect(fmtDuration(65_400)).toBe("1:05"); });
});
