import AppKit
import ScreenCaptureKit

/// Window screenshots the CleanShot way: transparent background with the window
/// shadow, or composited onto the desktop wallpaper with padding.
enum WindowCapture {
    static func capture(windowID: CGWindowID) async throws -> (NSImage, Double) {
        let s = SettingsStore.shared
        let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
        guard let window = content.windows.first(where: { $0.windowID == windowID }) else { throw AgentError("NOT_FOUND", "That window is gone.") }
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        let scale = Double(filter.pointPixelScale)
        let shadow = s.captureWindowShadow && !NSEvent.modifierFlags.contains(.option)
        let transparent = s.windowScreenshotStyle == "transparent" || NSEvent.modifierFlags.contains(.shift)
        let pad = shadow ? 40.0 : 0.0
        config.width = max(1, Int((filter.contentRect.width + pad * 2) * scale)); config.height = max(1, Int((filter.contentRect.height + pad * 2) * scale))
        config.showsCursor = false
        config.ignoreShadowsSingleWindow = !shadow
        config.backgroundColor = .clear
        config.sourceRect = CGRect(x: -pad, y: -pad, width: filter.contentRect.width + pad * 2, height: filter.contentRect.height + pad * 2)
        let cg = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        var image = NSImage(cgImage: cg, size: CGSize(width: CGFloat(cg.width) / scale, height: CGFloat(cg.height) / scale))
        if !transparent { image = compositeOnWallpaper(image, windowFrame: window.frame, scale: scale) }
        return (image, scale)
    }

    /// Draw the window capture over the matching slice of the desktop picture,
    /// with the user's padding.
    private static func compositeOnWallpaper(_ win: NSImage, windowFrame: CGRect, scale: Double) -> NSImage {
        let s = SettingsStore.shared
        let padding = 20 + 100 * s.windowPadding // 20…120 pt
        let outSize = NSSize(width: win.size.width + padding * 2, height: win.size.height + padding * 2)
        let out = NSImage(size: outSize)
        out.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        let mainH = NSScreen.screens[0].frame.height
        let cocoaFrame = CGRect(x: windowFrame.minX, y: mainH - windowFrame.maxY, width: windowFrame.width, height: windowFrame.height)
        let screen = NSScreen.screens.first { $0.frame.intersects(cocoaFrame) } ?? NSScreen.main
        if let screen, let url = NSWorkspace.shared.desktopImageURL(for: screen), let wall = NSImage(contentsOf: url) {
            // Scale the wallpaper to fill the screen, then take the slice under the padded window.
            let sf = screen.frame
            let k = max(sf.width / wall.size.width, sf.height / wall.size.height)
            let drawn = NSRect(x: sf.midX - wall.size.width * k / 2 - (cocoaFrame.minX - padding), y: sf.midY - wall.size.height * k / 2 - (cocoaFrame.minY - padding), width: wall.size.width * k, height: wall.size.height * k)
            wall.draw(in: drawn, from: .zero, operation: .copy, fraction: 1)
        } else {
            NSColor(white: 0.15, alpha: 1).setFill(); NSRect(origin: .zero, size: outSize).fill()
        }
        win.draw(in: NSRect(x: padding, y: padding, width: win.size.width, height: win.size.height))
        out.unlockFocus()
        return out
    }
}
