import AppKit
import Sparkle
import SwiftUI

@main
struct CleanShotXIsDeadApp {
    @MainActor static var delegate: AppDelegate?
    static func main() {
        MainActor.assumeIsolated {
            let app = NSApplication.shared
            let d = AppDelegate(); delegate = d; app.delegate = d
            app.run()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var updater: SPUStandardUpdaterController?
    private let capture = CaptureController.shared
    private var settingsWindow: SettingsWindowController?
    private var historyWindow: HistoryWindowController?
    private var recordTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if Bundle.main.bundleURL.pathExtension == "app" { updater = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil) }
        installEditMenu()
        setUpStatusItem()
        Hotkeys.shared.perform = { [weak self] in self?.perform($0) }
        Hotkeys.shared.registerAll()
        Analytics.track("app_opened")
        ScreenRecorder.shared.onStateChange = { [weak self] in self?.refreshStatusIcon() }
        NotificationCenter.default.addObserver(forName: .showMenuBarIconChanged, object: nil, queue: .main) { [weak self] _ in self?.refreshStatusIcon() }
        if let tab = ProcessInfo.processInfo.environment["CSX_SETTINGS_TAB"].flatMap(SettingsTab.init(rawValue:)) { showSettings(); settingsWindow?.show(tab: tab) }
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            Task { @MainActor in _ = await CaptureEngine.shared.authorizeInteractively(); self.showSettings() }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showSettings(); return false }
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { if let image = NSImage(contentsOf: url) { capture.editor.open(image: image, fileURL: url) } }
    }

    // MARK: Actions

    func perform(_ action: HotkeyAction) {
        switch action {
        case .allInOne, .captureArea: capture.captureArea()
        case .toggleDesktopIcons: DesktopIcons.toggle()
        case .openHistory: showHistory()
        case .restoreLastCapture: if let e = HistoryStore.shared.entries.first, let img = NSImage(contentsOf: e.fileURL) { QuickAccessOverlay.shared.add(e, image: img) }
        case .capturePreviousArea: capture.capturePreviousArea()
        case .captureFullscreen: capture.captureFullscreen()
        case .captureWindow: capture.captureWindow()
        case .scrollingCapture: ScrollingCapture.shared.begin()
        case .selfTimer: capture.selfTimer()
        case .captureAreaCopy: capture.captureArea(.copy)
        case .captureAreaSave: capture.captureArea(.save)
        case .captureAreaUpload: capture.captureArea(.upload)
        case .captureAreaAnnotate: capture.captureArea(.annotate)
        case .captureAreaPin: capture.captureArea(.pin)
        case .captureText: capture.captureArea(.text)
        case .recordScreen: ScreenRecorder.shared.toggle()
        case .openAnnotate: capture.openFile()
        case .openFromClipboard: capture.openFromClipboard()
        case .pinLast: if let e = HistoryStore.shared.entries.first(where: { $0.kind == .screenshot }), let img = NSImage(contentsOf: e.fileURL) { PinnedWindow.show(image: img) }
        case .annotateLast: if let e = HistoryStore.shared.entries.first(where: { $0.kind == .screenshot }), let img = NSImage(contentsOf: e.fileURL) { capture.editor.open(image: img, fileURL: e.fileURL) }
        }
    }
    @objc private func menuAction(_ sender: NSMenuItem) { if let a = HotkeyAction(rawValue: sender.identifier?.rawValue ?? "") { perform(a) } }
    @objc func showSettings() { if settingsWindow == nil { settingsWindow = SettingsWindowController() }; settingsWindow?.show(); Analytics.track("app_settings_opened") }
    @objc func showHistory() { if historyWindow == nil { historyWindow = HistoryWindowController() }; historyWindow?.show() }
    @objc private func showAbout() { settingsWindow = settingsWindow ?? SettingsWindowController(); settingsWindow?.show(tab: .about) }
    @objc private func checkForUpdates() { if let updater { updater.checkForUpdates(nil) } else { Toast.show("Updates work in the installed app, not a dev build", systemImage: "arrow.down.circle") } }
    @objc private func pinToScreen() { capture.pinFromFile() }

    // MARK: Status item

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = StatusIcon.image(recording: false)
        item.button?.imagePosition = .imageLeading
        let menu = NSMenu(); menu.delegate = self; menu.autoenablesItems = false
        item.menu = menu
        statusItem = item
        refreshStatusIcon()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        func row(_ title: String, _ symbol: String, _ action: HotkeyAction?, selector: Selector = #selector(menuAction(_:)), target: AnyObject? = nil) {
            let it = NSMenuItem(title: title, action: selector, keyEquivalent: "")
            it.target = target ?? self
            it.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?.withSymbolConfiguration(.init(pointSize: 13, weight: .medium))
            if let action { it.identifier = NSUserInterfaceItemIdentifier(action.rawValue)
                if let c = Hotkeys.shared.combo(action) { let (k, m) = c.menuKeyEquivalent; it.keyEquivalent = k; it.keyEquivalentModifierMask = m } }
            menu.addItem(it)
        }
        let recording = ScreenRecorder.shared.isRecording
        row("All-In-One", "rectangle.dashed", .allInOne)
        row("Capture Area", "viewfinder", .captureArea)
        row("Capture Fullscreen", "display", .captureFullscreen)
        row("Capture Window", "macwindow", .captureWindow)
        row("Scrolling Capture", "arrow.down.to.line", .scrollingCapture)
        row("Self-Timer", "timer", .selfTimer)
        row("Capture Text (OCR)", "text.viewfinder", .captureText)
        row(recording ? "Stop Recording" : "Record Screen", recording ? "stop.circle" : "video", .recordScreen)
        menu.addItem(.separator())
        row(DesktopIcons.hidden ? "Show Desktop Icons" : "Hide Desktop Icons", DesktopIcons.hidden ? "eye" : "eye.slash", .toggleDesktopIcons)
        menu.addItem(.separator())
        row("Open...", "folder", .openAnnotate)
        row("Open from Clipboard", "doc.on.clipboard", .openFromClipboard)
        row("Pin to the Screen...", "pin", nil, selector: #selector(pinToScreen))
        menu.addItem(.separator())
        row("Capture History...", "clock.arrow.circlepath", .openHistory)
        menu.addItem(.separator())
        menu.addItem(withTitle: "About CleanShotXIsDead...", action: #selector(showAbout), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings...", action: #selector(showSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    private func refreshStatusIcon() {
        let rec = ScreenRecorder.shared.isRecording
        statusItem?.isVisible = SettingsStore.shared.showMenuBarIcon || rec
        statusItem?.button?.image = StatusIcon.image(recording: rec)
        recordTimer?.invalidate(); recordTimer = nil
        if rec, SettingsStore.shared.menuBarRecordingTime {
            recordTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in let e = Int(ScreenRecorder.shared.elapsed); self?.statusItem?.button?.title = String(format: " %02d:%02d", e / 60, e % 60) }
            }
        } else { statusItem?.button?.title = "" }
    }

    /// Menu-bar apps get no ⌘C/⌘V/⌘Z without an Edit menu.
    private func installEditMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: ",").target = self
        appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let editItem = NSMenuItem(); main.addItem(editItem)
        let edit = NSMenu(title: "Edit"); editItem.submenu = edit
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        let window = NSMenuItem(); main.addItem(window)
        let wm = NSMenu(title: "Window"); window.submenu = wm
        wm.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        NSApp.mainMenu = main
    }
}

extension Notification.Name { static let showMenuBarIconChanged = Notification.Name("showMenuBarIconChanged") }

/// Menu-bar glyph: the tombstone mark as a template image (red dot while recording).
@MainActor enum StatusIcon {
    static func image(recording: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let img = NSImage(size: size, flipped: false) { rect in
            let ink = NSColor.black
            let stone = NSBezierPath()
            stone.move(to: NSPoint(x: 4, y: 3)); stone.line(to: NSPoint(x: 4, y: 10))
            stone.appendArc(withCenter: NSPoint(x: 9, y: 10), radius: 5, startAngle: 180, endAngle: 0, clockwise: false)
            stone.line(to: NSPoint(x: 14, y: 3)); stone.close()
            ink.setFill(); stone.fill()
            NSBezierPath(roundedRect: NSRect(x: 2, y: 1.5, width: 14, height: 2.4), xRadius: 1, yRadius: 1).fill()
            let x = NSBezierPath(); x.lineWidth = 1.8; x.lineCapStyle = .round
            x.move(to: NSPoint(x: 6.8, y: 6.3)); x.line(to: NSPoint(x: 11.2, y: 10.7)); x.move(to: NSPoint(x: 11.2, y: 6.3)); x.line(to: NSPoint(x: 6.8, y: 10.7))
            NSColor.white.setStroke(); x.stroke()
            if recording { NSColor.systemRed.setFill(); NSBezierPath(ovalIn: NSRect(x: 12, y: 11, width: 6, height: 6)).fill() }
            return true
        }
        img.isTemplate = !recording
        return img
    }
}
