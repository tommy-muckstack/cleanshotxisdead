import AppKit
import SwiftUI

/// "Pin to the screen": a floating, borderless image that stays on top.
@MainActor
enum PinnedWindow {
    private static var panels: [NSPanel] = []
    static func show(image: NSImage) {
        let maxW = (NSScreen.main?.visibleFrame.width ?? 1200) * 0.5
        let scale = min(1, maxW / max(image.size.width, 1))
        let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        let p = NSPanel(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel, .resizable], backing: .buffered, defer: false)
        p.isFloatingPanel = true; p.level = .floating; p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isOpaque = false; p.backgroundColor = .clear; p.hasShadow = true; p.isMovableByWindowBackground = true
        p.contentAspectRatio = size
        let view = PinnedView(image: image) { p.orderOut(nil); panels.removeAll { $0 === p } }
        p.contentView = NSHostingView(rootView: view)
        p.center(); p.orderFrontRegardless(); panels.append(p)
    }
}

private struct PinnedView: View {
    let image: NSImage
    let onClose: () -> Void
    @State private var hovering = false
    var body: some View {
        Image(nsImage: image).resizable().scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
            .overlay(alignment: .topTrailing) {
                if hovering {
                    HStack(spacing: 4) {
                        Button { CaptureActions.copyImage(image); Toast.show("Copied", systemImage: "doc.on.doc") } label: { Image(systemName: "doc.on.doc") }
                        Button(action: onClose) { Image(systemName: "xmark") }
                    }
                    .buttonStyle(.plain).font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                    .padding(6).background(Capsule().fill(.black.opacity(0.7))).padding(8)
                }
            }
            .onHover { hovering = $0 }
            .onTapGesture(count: 2, perform: onClose)
            .onKeyPress(.escape) { onClose(); return .handled }
            .help("Drag to move, double-click or ⎋ to unpin")
    }
}
