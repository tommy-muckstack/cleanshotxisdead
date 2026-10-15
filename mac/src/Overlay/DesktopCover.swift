import AppKit
import SwiftUI

/// Wallpaper pane behaviour: while desktop icons are hidden, optionally cover the
/// desktop with a custom image or a plain colour (a window at desktop level).
@MainActor
enum DesktopCover {
    private static var windows: [NSWindow] = []
    static func apply() {
        let s = SettingsStore.shared
        remove()
        guard DesktopIcons.hidden, s.wallpaperMode != "desktop" else { return }
        for screen in NSScreen.screens {
            let w = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
            w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            w.ignoresMouseEvents = true; w.hasShadow = false; w.isOpaque = true
            if s.wallpaperMode == "plain" {
                w.backgroundColor = NSColor(hex: s.wallpaperColorHex) ?? .darkGray
            } else if let img = NSImage(contentsOfFile: s.wallpaperImagePath) {
                let v = NSImageView(frame: NSRect(origin: .zero, size: screen.frame.size)); v.image = img; v.imageScaling = .scaleProportionallyUpOrDown; v.imageAlignment = .alignCenter
                w.contentView = v; w.backgroundColor = .black
            } else { w.backgroundColor = .darkGray }
            w.orderFrontRegardless(); windows.append(w)
        }
    }
    static func remove() { windows.forEach { $0.orderOut(nil) }; windows = [] }
}

extension NSColor {
    convenience init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespaces); if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let v = UInt32(h, radix: 16) else { return nil }
        self.init(red: CGFloat((v >> 16) & 0xff) / 255, green: CGFloat((v >> 8) & 0xff) / 255, blue: CGFloat(v & 0xff) / 255, alpha: 1)
    }
    var hexString: String {
        let c = usingColorSpace(.deviceRGB) ?? self
        return String(format: "#%02X%02X%02X", Int(c.redComponent * 255), Int(c.greenComponent * 255), Int(c.blueComponent * 255))
    }
}
