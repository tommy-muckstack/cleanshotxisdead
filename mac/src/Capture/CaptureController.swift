import AppKit
import SwiftUI
import Vision

/// Every capture mode end to end: freeze → select → crop → process → history →
/// after-capture actions (overlay / copy / save / upload / annotate / pin).
@MainActor
final class CaptureController: SelectionOverlayDelegate {
    static let shared = CaptureController()

    enum AreaMode { case capture, copy, save, upload, annotate, pin, text, record }
    private var areaMode: AreaMode = .capture
    private var overlay: SelectionOverlayCoordinator?
    private var frozenCapture: CompositeCapture?
    private var isStartingCapture = false
    private(set) var lastRegion: CGRect?
    let editor = EditorWindowController()
    var recorder: ScreenRecorder { ScreenRecorder.shared }

    // MARK: Entry points

    func captureArea(_ mode: AreaMode = .capture) {
        guard !isStartingCapture else { return }
        if overlay?.isShowing == true { selectionOverlayDidCancel() }
        isStartingCapture = true
        areaMode = mode
        Task { @MainActor in
            defer { isStartingCapture = false }
            guard await CaptureEngine.shared.authorizeInteractively() else { showPermissionAlert(); return }
            DesktopIcons.hideForCaptureIfNeeded()
            let frozen = SettingsStore.shared.freezeScreen || mode != .record
                ? try? await CaptureEngine.shared.captureAllDisplaysComposite() : nil
            frozenCapture = frozen
            overlay = SelectionOverlayCoordinator(frozenCapture: frozen, idleTimeout: 60)
            overlay?.delegate = self
            overlay?.showAll()
        }
    }

    func captureFullscreen(afterDelay seconds: Int = 0) {
        Task { @MainActor in
            guard await CaptureEngine.shared.authorizeInteractively() else { showPermissionAlert(); return }
            if seconds > 0 { await Countdown.run(seconds: seconds) }
            DesktopIcons.hideForCaptureIfNeeded()
            guard let frozen = try? await CaptureEngine.shared.captureAllDisplaysComposite() else { return }
            let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main ?? NSScreen.screens[0]
            guard let image = frozen.crop(to: screen.frame) else { return }
            finish(image, scale: frozen.scaleFactor, kind: seconds > 0 ? "timer" : "fullscreen")
        }
    }

    func selfTimer() { captureFullscreen(afterDelay: SettingsStore.shared.selfTimerSeconds) }

    func capturePreviousArea() {
        guard let rect = lastRegion else { captureArea(); return }
        Task { @MainActor in
            guard await CaptureEngine.shared.authorizeInteractively() else { showPermissionAlert(); return }
            DesktopIcons.hideForCaptureIfNeeded()
            guard let frozen = try? await CaptureEngine.shared.captureAllDisplaysComposite(), let image = frozen.crop(to: rect) else { return }
            finish(image, scale: frozen.scaleFactor, kind: "previous_area")
        }
    }

    func captureWindow() {
        Task { @MainActor in
            guard await CaptureEngine.shared.authorizeInteractively() else { showPermissionAlert(); return }
            WindowPicker.shared.pick { [weak self] windowID in
                guard let windowID else { return }
                Task { @MainActor in
                    do {
                        let (image, scale) = try await WindowCapture.capture(windowID: windowID)
                        self?.finish(image, scale: scale, kind: "window")
                    } catch { Toast.show("Couldn't capture that window", systemImage: "exclamationmark.triangle") }
                }
            }
        }
    }

    func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .heic, .gif]
        panel.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url, let image = NSImage(contentsOf: url) else { return }
        editor.open(image: image, fileURL: url)
    }

    func openFromClipboard() {
        guard let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self])?.first as? NSImage else {
            Toast.show("No image on the clipboard", systemImage: "doc.on.clipboard"); return
        }
        let entry = store(image, kind: .screenshot, retina: image.recommendedRetina)
        editor.open(image: image, fileURL: entry.fileURL)
    }

    func pinFromFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .heic, .gif]
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url, let image = NSImage(contentsOf: url) else { return }
        PinnedWindow.show(image: image)
    }

    // MARK: SelectionOverlayDelegate

    func selectionOverlayDidComplete(with rect: CGRect) {
        overlay?.hideAll(); overlay = nil
        lastRegion = rect
        let frozen = frozenCapture; frozenCapture = nil
        switch areaMode {
        case .record:
            DesktopIcons.restoreAfterCapture()
            recorder.start(region: rect)
        case .text:
            guard let image = frozen?.crop(to: rect) else { return }
            DesktopIcons.restoreAfterCapture()
            Task { await OCR.copyText(from: image) }
        default:
            guard let image = frozen?.crop(to: rect) else { return }
            finish(image, scale: Double(frozen?.scaleFactor ?? 2), kind: "area")
        }
    }

    func selectionOverlayDidCancel() {
        overlay?.hideAll(); overlay = nil; frozenCapture = nil
        DesktopIcons.restoreAfterCapture()
    }

    // MARK: Pipeline

    /// Entry for captures produced elsewhere (scrolling capture).
    func finishExternal(_ image: NSImage, scale: Double) { finish(image, scale: scale, kind: "scrolling") }

    private func finish(_ raw: NSImage, scale: Double, kind: String) {
        DesktopIcons.restoreAfterCapture()
        let s = SettingsStore.shared
        var image = raw
        if s.scaleRetinaTo1x, scale > 1 { image = image.scaled(by: 1 / scale) }
        if s.addBorder { image = image.withBorder() }
        let entry = store(image, kind: .screenshot, retina: !s.scaleRetinaTo1x && scale > 1)
        if s.playSounds { CaptureSoundPlayer.shared.play() }
        Analytics.track("app_capture_taken", ["kind": kind, "mode": String(describing: areaMode)])

        let mode = areaMode; areaMode = .capture
        switch mode {
        case .copy: CaptureActions.copyImage(image); Toast.show("Copied to clipboard", systemImage: "doc.on.doc")
        case .save: CaptureActions.saveToExportLocation(entry)
        case .upload: Task { await CloudUploader.shared.upload(entry) }
        case .annotate: editor.open(image: image, fileURL: entry.fileURL)
        case .pin: PinnedWindow.show(image: image)
        default:
            if s.afterShotCopy { CaptureActions.copyImage(image) }
            if s.afterShotSave { CaptureActions.saveToExportLocation(entry, quiet: true) }
            if s.afterShotUpload { Task { await CloudUploader.shared.upload(entry) } }
            if s.afterShotAnnotate { editor.open(image: image, fileURL: entry.fileURL) }
            if s.afterShotPin { PinnedWindow.show(image: image) }
            if s.afterShotOverlay { QuickAccessOverlay.shared.add(entry, image: image) }
        }
    }

    /// Writes the capture into the history folder and records it.
    @discardableResult
    func store(_ image: NSImage, kind: HistoryEntry.Kind, retina: Bool, date: Date = Date()) -> HistoryEntry {
        let s = SettingsStore.shared
        let ext = s.fileFormat.lowercased() == "jpg" ? "jpg" : "png"
        let name = HistoryStore.fileName(for: date, ext: ext, retina: retina)
        let url = HistoryStore.folder.appendingPathComponent("History").appendingPathComponent(name)
        try? image.encoded(format: ext, sRGB: s.convertToSRGB)?.write(to: url)
        let entry = HistoryEntry(id: UUID().uuidString, path: url.path, kind: kind, createdAt: date)
        if s.captureHistoryEnabled { HistoryStore.shared.add(entry) }
        return entry
    }

    func recordingFinished(url: URL) {
        let entry = HistoryEntry(id: UUID().uuidString, path: url.path, kind: .recording, createdAt: Date())
        if SettingsStore.shared.captureHistoryEnabled { HistoryStore.shared.add(entry) }
        let s = SettingsStore.shared
        if s.afterRecCopy { CaptureActions.copyFile(entry.fileURL) }
        if s.afterRecSave { CaptureActions.saveToExportLocation(entry, quiet: true) }
        if s.afterRecUpload { Task { await CloudUploader.shared.upload(entry) } }
        let thumb = url.pathExtension == "gif" ? (NSImage(contentsOf: url) ?? url.movieThumbnail()) : url.movieThumbnail()
        if s.afterRecOverlay { QuickAccessOverlay.shared.add(entry, image: thumb) }
        Analytics.track("app_recording_saved", ["format": url.pathExtension])
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "CleanShotXIsDead needs Screen Recording access"
        alert.informativeText = "Grant it in System Settings → Privacy & Security → Screen Recording, then relaunch the app."
        alert.addButton(withTitle: "Open System Settings"); alert.addButton(withTitle: "Later")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn, let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}

@MainActor enum CaptureActions {
    static func copyImage(_ image: NSImage) {
        let pb = NSPasteboard.general; pb.clearContents()
        if let png = image.encoded(format: "png", sRGB: false) { pb.setData(png, forType: .png) }
    }
    static func copyFile(_ url: URL) {
        let pb = NSPasteboard.general; pb.clearContents(); pb.writeObjects([url as NSURL])
    }
    /// Copies the history file into the export location (CleanShot's "Save").
    @discardableResult
    static func saveToExportLocation(_ entry: HistoryEntry, quiet: Bool = false) -> URL? {
        let dest = SettingsStore.shared.screenshotFolderURL.appendingPathComponent(entry.fileURL.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: dest.path) { try FileManager.default.removeItem(at: dest) }
            try FileManager.default.copyItem(at: entry.fileURL, to: dest)
            if !quiet { Toast.show("Saved to \(dest.deletingLastPathComponent().lastPathComponent)", systemImage: "checkmark.circle") }
            return dest
        } catch {
            Toast.show("Couldn't save: \(error.localizedDescription)", systemImage: "exclamationmark.triangle"); return nil
        }
    }
    static func saveAs(_ entry: HistoryEntry) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = entry.fileURL.lastPathComponent
        panel.directoryURL = SettingsStore.shared.screenshotFolderURL
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.copyItem(at: entry.fileURL, to: url)
    }
}

/// "Hide desktop icons" — the Finder preference CleanShot toggles.
enum DesktopIcons {
    private static var hiddenForCapture = false
    static var hidden: Bool {
        let out = shell("defaults read com.apple.finder CreateDesktop 2>/dev/null")
        return ["0", "false", "no"].contains(out.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
    }
    static func set(hidden: Bool) {
        _ = shell("defaults write com.apple.finder CreateDesktop -bool \(hidden ? "false" : "true"); killall Finder")
    }
    static func toggle() { set(hidden: !hidden); Task { @MainActor in try? await Task.sleep(for: .milliseconds(600)); DesktopCover.apply() } }
    static func hideForCaptureIfNeeded() {
        guard SettingsStore.shared.hideDesktopIconsWhileCapturing, !hidden else { return }
        hiddenForCapture = true; set(hidden: true)
        Task { @MainActor in try? await Task.sleep(for: .milliseconds(500)); DesktopCover.apply() }
    }
    static func restoreAfterCapture() {
        guard hiddenForCapture else { return }
        hiddenForCapture = false; set(hidden: false)
        Task { @MainActor in DesktopCover.remove() }
    }
    @discardableResult private static func shell(_ cmd: String) -> String {
        let p = Process(); p.launchPath = "/bin/zsh"; p.arguments = ["-c", cmd]
        let pipe = Pipe(); p.standardOutput = pipe; p.standardError = Pipe()
        try? p.run(); p.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}

enum OCR {
    static func copyText(from image: NSImage) async {
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate; request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        try? handler.perform([request])
        let lines = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        let text = lines.joined(separator: "\n")
        await MainActor.run {
            if text.isEmpty { Toast.show("No text found", systemImage: "text.viewfinder"); return }
            NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string)
            if SettingsStore.shared.playSounds { CaptureSoundPlayer.shared.play() }
            Toast.show("Text copied to clipboard", systemImage: "text.viewfinder")
        }
    }
}

extension NSImage {
    var recommendedRetina: Bool { (representations.first?.pixelsWide ?? 0) > Int(size.width) + 1 }
    func scaled(by factor: CGFloat) -> NSImage {
        let newSize = NSSize(width: size.width * factor, height: size.height * factor)
        let img = NSImage(size: newSize); img.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        draw(in: NSRect(origin: .zero, size: newSize)); img.unlockFocus(); return img
    }
    func withBorder() -> NSImage {
        let img = NSImage(size: size); img.lockFocus()
        draw(in: NSRect(origin: .zero, size: size))
        NSColor(white: 0, alpha: 0.6).setStroke()
        let path = NSBezierPath(rect: NSRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)); path.lineWidth = 1; path.stroke()
        img.unlockFocus(); return img
    }
    func encoded(format: String, sRGB: Bool) -> Data? {
        guard var tiff = tiffRepresentation, var rep = NSBitmapImageRep(data: tiff) else { return nil }
        if sRGB, let converted = rep.converting(to: .sRGB, renderingIntent: .perceptual) { rep = converted; tiff = rep.tiffRepresentation ?? tiff }
        return format == "jpg" ? rep.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) : rep.representation(using: .png, properties: [:])
    }
}

extension URL {
    func movieThumbnail() -> NSImage {
        let asset = AVURLAsset(url: self)
        let gen = AVAssetImageGenerator(asset: asset); gen.appliesPreferredTrackTransform = true
        if let cg = try? gen.copyCGImage(at: .init(seconds: 0.2, preferredTimescale: 600), actualTime: nil) {
            return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        }
        return NSImage(systemSymbolName: "video", accessibilityDescription: nil) ?? NSImage()
    }
}
import AVFoundation
