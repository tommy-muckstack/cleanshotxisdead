import AppKit
import SwiftUI

/// Scrolling Capture: select an area, then scroll (or let the app auto-scroll)
/// while frames are stitched into one tall image. Mirrors CleanShot X's flow:
/// Start → scroll → Done, with an Auto-scroll option.
@MainActor
final class ScrollingCapture: ObservableObject, SelectionOverlayDelegate {
    static let shared = ScrollingCapture()
    @Published private(set) var active = false
    @Published private(set) var started = false
    @Published private(set) var sections = 0
    @Published private(set) var message = "Scroll down slowly to add more content, or turn on Auto-scroll."
    @Published var autoScroll = false { didSet { if autoScroll { startAutoScroll() } else { autoTask?.cancel() } } }
    private var region = CGRect.zero
    private var previous: CGImage?
    private var composite: CGImage?
    private var task: Task<Void, Never>?
    private var autoTask: Task<Void, Never>?
    private var overlay: SelectionOverlayCoordinator?
    private var panel: NSPanel?
    private var frame: NSPanel?
    private var capturing = false
    private var stuckCount = 0

    func begin() {
        guard !active else { panel?.orderFrontRegardless(); return }
        Task { @MainActor in
            guard await CaptureEngine.shared.authorizeInteractively() else { return }
            let frozen = try? await CaptureEngine.shared.captureAllDisplaysComposite()
            overlay = SelectionOverlayCoordinator(frozenCapture: frozen, idleTimeout: 60); overlay?.delegate = self; overlay?.showAll()
        }
    }
    func selectionOverlayDidComplete(with rect: CGRect) {
        overlay?.hideAll(); overlay = nil
        guard rect.width >= 100, rect.height >= 100 else { Toast.show("Select a larger area", systemImage: "rectangle.dashed"); return }
        region = rect; active = true; started = false; sections = 0; previous = nil; composite = nil; stuckCount = 0
        message = "Press Start, then scroll down slowly. Keep part of the previous section visible."
        showFrame(); showPanel()
        Analytics.track("app_scrolling_capture_started")
    }
    func selectionOverlayDidCancel() { overlay?.hideAll(); overlay = nil }

    func start() {
        started = true
        message = "Scroll down slowly to add more content, or turn on Auto-scroll."
        task = Task { while !Task.isCancelled, active { await sample(); try? await Task.sleep(for: .milliseconds(700)) } }
    }

    private func startAutoScroll() {
        guard AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary) else {
            autoScroll = false; message = "Auto-scroll needs Accessibility access. Grant it in System Settings → Privacy & Security → Accessibility."; return
        }
        if !started { start() }
        autoTask = Task { @MainActor in
            while !Task.isCancelled, active, autoScroll {
                let mainH = NSScreen.screens[0].frame.height
                let p = CGPoint(x: region.midX, y: mainH - region.midY)
                CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
                let lines = Int32(-max(3, region.height / 40))
                CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: lines, wheel2: 0, wheel3: 0)?.post(tap: .cghidEventTap)
                try? await Task.sleep(for: .milliseconds(800))
                if stuckCount >= 3 { autoScroll = false; message = "Reached the end. Press Done to save \(sections) sections."; break }
            }
        }
    }

    private func sample() async {
        guard !capturing, active else { return }; capturing = true
        panel?.alphaValue = 0; frame?.alphaValue = 0
        defer { capturing = false; if active { panel?.alphaValue = 1; frame?.alphaValue = 1 } }
        do {
            let image = try await CaptureEngine.shared.captureAllDisplaysComposite().crop(to: region)
            guard active, let image, let next = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
            if let previous, let composite {
                let result = try await Task.detached(priority: .userInitiated) { try ScrollStitcher.append(previous: previous, next: next, composite: composite) }.value
                guard active else { return }
                switch result {
                case .unchanged: stuckCount += 1
                case .noOverlap: stuckCount = 0; message = "Couldn't match that section. Scroll back a little and move more slowly."
                case .appended(let combined, _): stuckCount = 0; self.composite = combined; self.previous = next; sections += 1; message = "\(sections) sections captured. Keep scrolling, or press Done."
                }
            } else { previous = next; composite = next; sections = 1; message = "1 section captured. Keep scrolling, or press Done." }
        } catch { message = error.localizedDescription }
    }

    func done() {
        task?.cancel(); autoTask?.cancel(); autoScroll = false
        Task { @MainActor in
            while capturing { try? await Task.sleep(for: .milliseconds(25)) }
            if composite == nil { await sample() }
            guard let composite else { cancel(); return }
            let image = NSImage(cgImage: composite, size: NSSize(width: CGFloat(composite.width) / 2, height: CGFloat(composite.height) / 2))
            let count = sections
            clear()
            CaptureController.shared.finishExternal(image, scale: 2)
            Analytics.track("app_scrolling_capture_saved", ["sections": count])
        }
    }
    func cancel() { clear() }
    private func clear() { task?.cancel(); autoTask?.cancel(); task = nil; autoTask = nil; active = false; started = false; previous = nil; composite = nil; panel?.orderOut(nil); panel = nil; frame?.orderOut(nil); frame = nil }

    private func showFrame() {
        let f = NSPanel(contentRect: region.insetBy(dx: -3, dy: -3), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        f.isOpaque = false; f.backgroundColor = .clear; f.hasShadow = false; f.ignoresMouseEvents = true; f.level = .screenSaver
        f.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        f.contentView = NSHostingView(rootView: RoundedRectangle(cornerRadius: 4).strokeBorder(Color(red: 0.16, green: 0.42, blue: 1), lineWidth: 3))
        f.orderFrontRegardless(); frame = f
    }
    private func showPanel() {
        let p = NSPanel(contentRect: NSRect(x: region.midX - 190, y: max(region.minY - 70, 8), width: 380, height: 58), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.isFloatingPanel = true; p.level = .screenSaver; p.isOpaque = false; p.backgroundColor = .clear; p.hasShadow = true; p.isMovableByWindowBackground = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.contentView = NSHostingView(rootView: ScrollingControls(model: self))
        p.orderFrontRegardless(); panel = p
    }
}

private struct ScrollingControls: View {
    @ObservedObject var model: ScrollingCapture
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Scrolling Capture").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                Text(model.message).font(.system(size: 11)).foregroundStyle(.white.opacity(0.75)).lineLimit(2)
            }
            Spacer()
            if model.started {
                Toggle("Auto-scroll", isOn: $model.autoScroll).toggleStyle(.switch).controlSize(.mini).foregroundStyle(.white)
                Button("Done") { model.done() }.buttonStyle(.borderedProminent).tint(Color(red: 0.16, green: 0.42, blue: 1))
            } else {
                Button("Start") { model.start() }.buttonStyle(.borderedProminent).tint(Color(red: 0.16, green: 0.42, blue: 1))
            }
            Button { model.cancel() } label: { Image(systemName: "xmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white).frame(width: 24, height: 24) }.buttonStyle(.plain)
        }
        .padding(.horizontal, 12).frame(height: 58)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.black.opacity(0.85)))
    }
}
