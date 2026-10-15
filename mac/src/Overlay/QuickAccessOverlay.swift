import AppKit
import SwiftUI

/// The Quick Access Overlay: a stack of capture cards in a screen corner.
/// Hover reveals actions; cards drag into any app; auto-close saves + dismisses.
@MainActor
final class QuickAccessOverlay: ObservableObject {
    static let shared = QuickAccessOverlay()
    struct Item: Identifiable { let id: String; var entry: HistoryEntry; let image: NSImage; let addedAt = Date() }
    @Published var items: [Item] = []
    @Published var hovering = false
    private var panel: NSPanel?
    private var timer: Timer?

    func add(_ entry: HistoryEntry, image: NSImage) {
        items.append(Item(id: entry.id, entry: entry, image: image))
        if items.count > 4 { autoClose(items[0]) }
        showPanel(); scheduleAutoClose()
    }
    func close(_ item: Item) {
        items.removeAll { $0.id == item.id }
        if items.isEmpty { hidePanel() } else { layout() }
    }
    func closeAll() { items.removeAll(); hidePanel() }
    func autoClose(_ item: Item) {
        if SettingsStore.shared.overlayAutoCloseAction == "Save and Close" { CaptureActions.saveToExportLocation(item.entry, quiet: true) }
        close(item)
    }

    private func scheduleAutoClose() {
        timer?.invalidate()
        guard SettingsStore.shared.overlayAutoClose else { return }
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(SettingsStore.shared.overlayAutoCloseSeconds), repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.hovering { self.scheduleAutoClose(); return }
                for item in self.items { self.autoClose(item) }
            }
        }
    }
    func hoverChanged(_ h: Bool) { hovering = h; if !h { scheduleAutoClose() } else { timer?.invalidate() } }

    private func showPanel() {
        if panel == nil {
            let p = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            p.isFloatingPanel = true; p.level = .floating; p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            p.isOpaque = false; p.backgroundColor = .clear; p.hasShadow = false; p.animationBehavior = .utilityWindow
            let hosting = NSHostingView(rootView: OverlayStackView(model: self))
            hosting.translatesAutoresizingMaskIntoConstraints = true; hosting.autoresizingMask = [.width, .height]
            p.contentView = hosting; panel = p
        }
        layout(); panel?.orderFrontRegardless()
    }
    func layout() {
        guard let panel else { return }
        let s = SettingsStore.shared
        let screen = (s.overlayMoveToActiveScreen ? NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } : nil) ?? NSScreen.main ?? NSScreen.screens[0]
        let v = screen.visibleFrame
        let w = cardWidth + 40, h = CGFloat(items.count) * (cardHeight + 12) + 40
        let x = s.overlayPosition == "Right" ? v.maxX - w : v.minX
        panel.setFrame(NSRect(x: x, y: v.minY, width: w, height: h), display: true)
    }
    var cardWidth: CGFloat { 200 + 160 * SettingsStore.shared.overlaySize }
    var cardHeight: CGFloat { cardWidth * 0.68 }
    private func hidePanel() { timer?.invalidate(); panel?.orderOut(nil) }
}

private struct OverlayStackView: View {
    @ObservedObject var model: QuickAccessOverlay
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer(minLength: 0)
            ForEach(model.items) { item in OverlayCard(model: model, item: item).transition(.move(edge: .bottom).combined(with: .opacity)) }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: SettingsStore.shared.overlayPosition == "Right" ? .bottomTrailing : .bottomLeading)
        .animation(MM.Motion.silky, value: model.items.map(\.id))
        .onHover { model.hoverChanged($0) }
    }
}

private struct OverlayCard: View {
    @ObservedObject var model: QuickAccessOverlay
    let item: QuickAccessOverlay.Item
    @State private var hovering = false
    @State private var uploading = false
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(nsImage: item.image).resizable().scaledToFill()
                .frame(width: model.cardWidth, height: model.cardHeight).clipped()
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(hovering ? MM.Colors.accent : Color.white.opacity(0.25), lineWidth: hovering ? 2 : 1))
                .shadow(color: .black.opacity(0.45), radius: 14, y: 6)
                .overlay(alignment: .bottom) { if hovering { actions.padding(8) } }
                .overlay(alignment: .topTrailing) { if item.entry.kind == .recording { Image(systemName: "video.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(.white).padding(6).background(Circle().fill(.black.opacity(0.6))).padding(8) } }
            if hovering {
                Button { model.close(item) } label: { Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundStyle(.white).frame(width: 22, height: 22).background(Circle().fill(.black.opacity(0.7))) }
                    .buttonStyle(.plain).offset(x: -8, y: -8).clickable(minSize: 22)
            }
        }
        .onHover { hovering = $0 }
        .animation(MM.Motion.gentle, value: hovering)
        .onTapGesture(count: 2) { annotate() }
        .draggable(item.entry.fileURL) { Image(nsImage: item.image).resizable().scaledToFit().frame(width: 120) }
        .help("Double-click to annotate, drag anywhere")
    }
    private var actions: some View {
        HStack(spacing: 6) {
            action("square.and.arrow.up", "Share") { NSSharingServicePicker(items: [item.entry.fileURL]).show(relativeTo: .zero, of: NSApp.keyWindow?.contentView ?? NSView(), preferredEdge: .minY) }
            action("pin", "Pin to the screen") { PinnedWindow.show(image: item.image); model.close(item) }
            action("doc.on.doc", "Copy") { item.entry.kind == .recording ? CaptureActions.copyFile(item.entry.fileURL) : CaptureActions.copyImage(item.image); Toast.show("Copied", systemImage: "doc.on.doc") }
            action("square.and.arrow.down", "Save") {
                if NSEvent.modifierFlags.contains(.option) { CaptureActions.saveAs(item.entry) } else { CaptureActions.saveToExportLocation(item.entry) }
                model.close(item)
            }
            if item.entry.kind == .screenshot { action("pencil.tip.crop.circle", "Annotate") { annotate() } }
            action(uploading ? "icloud.and.arrow.up" : "icloud.and.arrow.up", "Upload to Cloud") {
                uploading = true
                Task { await CloudUploader.shared.upload(item.entry); uploading = false; if SettingsStore.shared.overlayCloseAfterUpload { model.close(item) } }
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(.black.opacity(0.78)))
    }
    private func action(_ symbol: String, _ help: String, _ run: @escaping () -> Void) -> some View {
        Button(action: run) { Image(systemName: symbol).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white).frame(width: 26, height: 24) }
            .buttonStyle(.plain).help(help).clickable(minSize: 24)
    }
    private func annotate() { CaptureController.shared.editor.open(image: item.image, fileURL: item.entry.fileURL); model.close(item) }
}
