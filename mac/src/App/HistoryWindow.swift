import AppKit
import SwiftUI

@MainActor
final class HistoryWindowController {
    private let window: NSWindow
    init() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 820, height: 560), styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Capture History"; window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 560, height: 360)
        let host = NSHostingView(rootView: HistoryView().frame(minWidth: 560, idealWidth: 820, minHeight: 360, idealHeight: 560))
        host.translatesAutoresizingMaskIntoConstraints = true; host.autoresizingMask = [.width, .height]
        host.frame = NSRect(origin: .zero, size: NSSize(width: 820, height: 560))
        window.contentView = host
        window.setContentSize(NSSize(width: 820, height: 560)); window.center()
    }
    func show() {
        NSApp.activate(ignoringOtherApps: true); window.makeKeyAndOrderFront(nil)
        if window.frame.width < 800 { window.setContentSize(NSSize(width: 820, height: 560)); window.center() }
    }
}

struct HistoryView: View {
    @ObservedObject var store = HistoryStore.shared
    @State private var selected: String?
    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 14)]
    var body: some View {
        Group {
            if store.entries.isEmpty {
                VStack(spacing: 8) { Image(systemName: "clock.arrow.circlepath").font(.system(size: 36)).foregroundStyle(.secondary); Text("No captures yet").font(.title3); Text("Screenshots and recordings show up here.").foregroundStyle(.secondary) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(store.entries) { e in HistoryCard(entry: e, selected: selected == e.id).onTapGesture { selected = e.id }.onTapGesture(count: 2) { open(e) }
                            .contextMenu {
                                Button("Open") { open(e) }
                                Button("Copy") { if let img = NSImage(contentsOf: e.fileURL) { CaptureActions.copyImage(img) } else { CaptureActions.copyFile(e.fileURL) } }
                                Button("Save to Export Location") { CaptureActions.saveToExportLocation(e) }
                                Button("Upload to Cloud") { Task { await CloudUploader.shared.upload(e) } }
                                Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([e.fileURL]) }
                                Divider()
                                Button("Delete", role: .destructive) { store.remove(e, deleteFile: true) }
                            } }
                    }.padding(16)
                }
            }
        }
        .background(MM.Colors.background)
    }
    private func open(_ e: HistoryEntry) {
        if e.kind == .screenshot, let img = NSImage(contentsOf: e.fileURL) { CaptureController.shared.editor.open(image: img, fileURL: e.fileURL) } else { NSWorkspace.shared.open(e.fileURL) }
    }
}

private struct HistoryCard: View {
    let entry: HistoryEntry
    let selected: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                if entry.kind == .screenshot, let img = NSImage(contentsOf: entry.fileURL) { Image(nsImage: img).resizable().scaledToFill() }
                else { Image(nsImage: entry.fileURL.pathExtension == "gif" ? (NSImage(contentsOf: entry.fileURL) ?? entry.fileURL.movieThumbnail()) : entry.fileURL.movieThumbnail()).resizable().scaledToFill().overlay(Image(systemName: "play.circle.fill").font(.system(size: 28)).foregroundStyle(.white.opacity(0.9))) }
            }
            .frame(height: 120).clipped().clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(selected ? MM.Colors.accent : MM.Colors.border, lineWidth: selected ? 2 : 1))
            Text(entry.fileURL.lastPathComponent).font(MM.Fonts.secondary).lineLimit(1)
            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened)).font(MM.Fonts.metadata).foregroundStyle(MM.Colors.textSecondary)
        }
        .draggable(entry.fileURL)
    }
}
