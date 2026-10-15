import AppKit
import SwiftUI

/// "Show keystrokes" while recording: a pill inside the recorded area that shows
/// the keys being pressed, so they end up in the video. Needs Accessibility
/// (listen-only event tap), same as CleanShot X.
@MainActor
final class KeystrokeOverlay {
    static let shared = KeystrokeOverlay()
    private var panel: NSPanel?
    private let model = Model()
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var hideTask: Task<Void, Never>?

    static var accessibilityGranted: Bool { AXIsProcessTrusted() }
    static func requestAccessibility() { _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary) }

    func show(in region: CGRect) {
        hide()
        guard AXIsProcessTrusted() else { Toast.show("Show keystrokes needs Accessibility access", systemImage: "keyboard", actionLabel: "Grant", action: { Self.requestAccessibility() }); return }
        let frame = NSRect(x: region.midX - 160, y: region.minY + 24, width: 320, height: 44)
        let p = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.isOpaque = false; p.backgroundColor = .clear; p.hasShadow = false; p.ignoresMouseEvents = true; p.level = .statusBar
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        p.contentView = NSHostingView(rootView: KeysView(model: model)); p.alphaValue = 0
        p.orderFrontRegardless(); panel = p
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, _ in
            let keyCode = UInt32(event.getIntegerValueField(.keyboardEventKeycode)); let flags = event.flags
            Task { @MainActor in KeystrokeOverlay.shared.handle(type: type, keyCode: keyCode, flags: flags) }
            return Unmanaged.passUnretained(event)
        }
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly, eventsOfInterest: mask, callback: callback, userInfo: nil) else { return }
        self.tap = tap
        source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    func hide() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil; source = nil; panel?.orderOut(nil); panel = nil; hideTask?.cancel()
    }
    private func handle(type: CGEventType, keyCode: UInt32, flags: CGEventFlags) {
        var parts: [String] = []
        if flags.contains(.maskControl) { parts.append("⌃") }
        if flags.contains(.maskAlternate) { parts.append("⌥") }
        if flags.contains(.maskShift) { parts.append("⇧") }
        if flags.contains(.maskCommand) { parts.append("⌘") }
        if type == .keyDown { parts.append(HotkeyCombo.keyName(keyCode)) }
        guard !parts.isEmpty else { return }
        model.text = parts.joined(separator: " ")
        panel?.animator().alphaValue = 1
        hideTask?.cancel()
        hideTask = Task { @MainActor in try? await Task.sleep(for: .seconds(1.6)); if !Task.isCancelled { panel?.animator().alphaValue = 0 } }
    }
    final class Model: ObservableObject { @Published var text = "" }
    private struct KeysView: View {
        @ObservedObject var model: Model
        var body: some View {
            Text(model.text).font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                .padding(.horizontal, 16).frame(height: 40)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.black.opacity(0.75)))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
