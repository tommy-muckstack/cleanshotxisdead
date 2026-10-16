import AppKit
import ServiceManagement
import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, wallpaper, shortcuts, quickAccess, recording, screenshots, annotate, cloud, advanced, about
    var id: String { rawValue }
    var title: String {
        switch self { case .general: "General"; case .wallpaper: "Wallpaper"; case .shortcuts: "Shortcuts"; case .quickAccess: "Quick Access"; case .recording: "Recording"; case .screenshots: "Screenshots"; case .annotate: "Annotate"; case .cloud: "Cloud"; case .advanced: "Advanced"; case .about: "About" }
    }
    var symbol: String {
        switch self { case .general: "gearshape.fill"; case .wallpaper: "photo.fill"; case .shortcuts: "command.square.fill"; case .quickAccess: "rectangle.on.rectangle.angled"; case .recording: "video.fill"; case .screenshots: "camera.fill"; case .annotate: "pencil.and.outline"; case .cloud: "cloud.fill"; case .advanced: "wrench.and.screwdriver.fill"; case .about: "info.circle.fill" }
    }
}

@MainActor
final class SettingsWindowController {
    private let window: NSWindow
    private let model = SettingsTabModel()
    init() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 670, height: 640), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.titlebarAppearsTransparent = true; window.isReleasedWhenClosed = false; window.center()
        window.appearance = NSAppearance(named: .darkAqua)
        let host = NSHostingView(rootView: SettingsView(tabs: model))
        host.translatesAutoresizingMaskIntoConstraints = true; host.autoresizingMask = [.width, .height]
        host.sizingOptions = []
        window.contentView = host
        window.setContentSize(NSSize(width: 670, height: 640))
        window.title = "General"
        model.onChange = { [weak self] in self?.window.title = $0.title }
    }
    func show(tab: SettingsTab? = nil) {
        if let tab { model.tab = tab }
        NSApp.activate(ignoringOtherApps: true); window.makeKeyAndOrderFront(nil)
    }
}

final class SettingsTabModel: ObservableObject {
    @Published var tab: SettingsTab = .general { didSet { onChange?(tab) } }
    var onChange: ((SettingsTab) -> Void)?
}

struct SettingsView: View {
    @ObservedObject var tabs: SettingsTabModel
    @ObservedObject var s = SettingsStore.shared
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            ScrollView { pane.padding(.vertical, 18).frame(maxWidth: .infinity) }
        }
        .frame(width: 670, height: 640)
        .background(Color(nsColor: NSColor(white: 0.17, alpha: 1)))
        .preferredColorScheme(.dark)
    }

    private var toolbar: some View {
        HStack(spacing: 2) {
            ForEach(SettingsTab.allCases) { t in
                Button { tabs.tab = t } label: {
                    VStack(spacing: 3) {
                        Image(systemName: t.symbol).font(.system(size: 20)).frame(height: 26)
                        Text(t.title).font(.system(size: 11))
                    }
                    .foregroundStyle(tabs.tab == t ? MM.Colors.accent : Color.white.opacity(0.7))
                    .frame(width: 60, height: 54)
                    .background(RoundedRectangle(cornerRadius: 7).fill(tabs.tab == t ? Color.white.opacity(0.08) : .clear))
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.top, 30).padding(.bottom, 6)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var pane: some View {
        switch tabs.tab {
        case .general: general
        case .wallpaper: WallpaperPane()
        case .shortcuts: ShortcutsPane()
        case .quickAccess: quickAccess
        case .recording: RecordingPane()
        case .screenshots: screenshots
        case .annotate: annotate
        case .cloud: cloud
        case .advanced: advanced
        case .about: AboutPane()
        }
    }

    // MARK: Panes

    private var general: some View {
        Form {
            Section {
                LabeledContent("Startup:") { Toggle("Start at login", isOn: Binding(get: { LoginItem.enabled }, set: { LoginItem.enabled = $0 })) }
                LabeledContent("Sounds:") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Play sounds", isOn: $s.playSounds)
                        HStack { Text("Shutter sound:").foregroundStyle(.secondary); Picker("", selection: $s.captureSound) { ForEach(CaptureSound.allCases) { Text($0.label).tag($0) } }.labelsHidden().frame(width: 160) }.padding(.leading, 20)
                    }
                }
                LabeledContent("Menu bar:") { Toggle("Show icon", isOn: $s.showMenuBarIcon).onChange(of: s.showMenuBarIcon) { NotificationCenter.default.post(name: .showMenuBarIconChanged, object: nil) } }
            }
            Section {
                LabeledContent("Export location:") {
                    Button { chooseFolder() } label: { HStack { Image(systemName: "folder.fill").foregroundStyle(MM.Colors.accent); Text(s.screenshotFolderPath.replacingOccurrences(of: NSHomeDirectory(), with: "~")).lineLimit(1); Spacer() }.frame(width: 320) }
                }
                LabeledContent("Desktop icons:") { Toggle("Hide while capturing", isOn: $s.hideDesktopIconsWhileCapturing) }
            }
            Section {
                LabeledContent("After capture:") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Here you can decide what should happen after taking a screenshot or recording a video.").foregroundStyle(.secondary).frame(width: 360, alignment: .leading)
                        afterCaptureTable
                    }
                }
            }
        }.formStyle(.columns).padding(.horizontal, 36)
    }

    private var afterCaptureTable: some View {
        VStack(spacing: 0) {
            HStack { Text("Screenshot").frame(width: 90); Text("Recording").frame(width: 90); Text("Action").frame(maxWidth: .infinity, alignment: .leading) }
                .font(.system(size: 13, weight: .semibold)).padding(.vertical, 8).padding(.horizontal, 8)
            Divider()
            afterRow("Show Quick Access Overlay", $s.afterShotOverlay, $s.afterRecOverlay)
            afterRow("Copy file to clipboard", $s.afterShotCopy, $s.afterRecCopy)
            afterRow("Save", $s.afterShotSave, $s.afterRecSave)
            afterRow("Upload to Cloud & copy link", $s.afterShotUpload, $s.afterRecUpload)
            afterRow("Open Annotate tool", $s.afterShotAnnotate, nil)
            afterRow("Pin to the screen", $s.afterShotPin, nil)
        }
        .frame(width: 400)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.1)))
    }
    private func afterRow(_ title: String, _ a: Binding<Bool>, _ b: Binding<Bool>?) -> some View {
        HStack {
            Toggle("", isOn: a).labelsHidden().frame(width: 90)
            Group { if let b { Toggle("", isOn: b).labelsHidden() } else { Text("–").foregroundStyle(.secondary) } }.frame(width: 90)
            Text(title).frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.vertical, 6).padding(.horizontal, 8)
        .background(Color.white.opacity(0.02))
    }

    private var quickAccess: some View {
        Form {
            Section {
                LabeledContent("Position on screen:") { Picker("", selection: $s.overlayPosition) { Text("Left").tag("Left"); Text("Right").tag("Right") }.labelsHidden().frame(width: 200) }
                LabeledContent("Multi-display:") { VStack(alignment: .leading) { Toggle("Move to active screen", isOn: $s.overlayMoveToActiveScreen); Text("Active screen is the screen where your cursor is pointing.").foregroundStyle(.secondary) } }
                LabeledContent("Overlay size:") { Slider(value: $s.overlaySize, in: 0...1, step: 0.25).frame(width: 200) }
            }
            Section {
                LabeledContent("Auto-close:") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Enable", isOn: $s.overlayAutoClose)
                        HStack { Text("Action:").foregroundStyle(.secondary); Picker("", selection: $s.overlayAutoCloseAction) { Text("Save and Close").tag("Save and Close"); Text("Close").tag("Close") }.labelsHidden().frame(width: 150) }.padding(.leading, 20)
                        HStack { Text("Interval:").foregroundStyle(.secondary); Picker("", selection: $s.overlayAutoCloseSeconds) { ForEach([5, 10, 15, 30, 60], id: \.self) { Text("\($0) seconds").tag($0) } }.labelsHidden().frame(width: 150) }.padding(.leading, 20)
                    }
                }
                LabeledContent("Drag & drop:") { Toggle("Close after dragging", isOn: $s.overlayCloseAfterDrag) }
                LabeledContent("Cloud upload:") { Toggle("Close after uploading", isOn: $s.overlayCloseAfterUpload) }
                LabeledContent("Save button behavior:") { VStack(alignment: .leading) { Text("Save to \"Export location\""); Text("Press with ⌥ (option) to choose the destination.").foregroundStyle(.secondary) } }
            }
        }.formStyle(.columns).padding(.horizontal, 36)
    }

    private var screenshots: some View {
        Form {
            Section {
                LabeledContent("File format:") { Picker("", selection: $s.fileFormat) { Text("PNG").tag("PNG"); Text("JPG").tag("JPG") }.labelsHidden().frame(width: 100) }
                LabeledContent("Retina:") { Toggle("Scale Retina screenshots to 1x", isOn: $s.scaleRetinaTo1x) }
                LabeledContent("Color management:") { Toggle("Convert to sRGB profile", isOn: $s.convertToSRGB) }
                LabeledContent("Frame:") { Toggle("Add 1px border to all screenshots", isOn: $s.addBorder) }
            }
            Section {
                LabeledContent("Self-Timer interval:") { Picker("", selection: $s.selfTimerSeconds) { ForEach([3, 5, 10], id: \.self) { Text("\($0) Seconds").tag($0) } }.labelsHidden().frame(width: 160) }
            }
            Section {
                LabeledContent("Freeze screen:") { VStack(alignment: .leading) { Toggle("Freeze screen when taking a screenshot", isOn: $s.freezeScreen); Text("Use this option to capture hover states, animations, or fast-moving content.").foregroundStyle(.secondary) } }
            }
        }.formStyle(.columns).padding(.horizontal, 36)
    }

    private var annotate: some View {
        Form {
            Section {
                LabeledContent("Shadow:") { Toggle("Draw shadow on objects", isOn: $s.drawShadowOnObjects) }
                LabeledContent("Window:") { VStack(alignment: .leading) { Toggle("Always on top", isOn: $s.annotateAlwaysOnTop) } }
            }
        }.formStyle(.columns).padding(.horizontal, 36)
    }

    private var cloud: some View {
        Form {
            Section {
                LabeledContent("Account:") { VStack(alignment: .leading, spacing: 6) { Text("No account needed. Uploads create a public link on the CleanShotXIsDead web app.").frame(width: 360, alignment: .leading); Text("Free, no sign-in. Delete a link any time from the web app.").foregroundStyle(.secondary) } }
                LabeledContent("Server:") { TextField("", text: $s.cloudBaseURL).frame(width: 320) }
                LabeledContent("After upload:") { Toggle("Copy link to clipboard", isOn: $s.cloudCopyLinkAfterUpload) }
            }
        }.formStyle(.columns).padding(.horizontal, 36)
    }

    private var advanced: some View {
        Form {
            Section {
                LabeledContent("File name:") { VStack(alignment: .leading) { TextField("", text: $s.fileNamePattern).frame(width: 320); Text("%y year · %m month · %d day · %H hour · %M minute · %S second").foregroundStyle(.secondary) } }
                LabeledContent("Capture History:") { Toggle("Keep a history of captures", isOn: $s.captureHistoryEnabled) }
                LabeledContent("History folder:") { Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([HistoryStore.folder.appendingPathComponent("History")]) } }
            }
        }.formStyle(.columns).padding(.horizontal, 36)
    }

    private func chooseFolder() {
        let p = NSOpenPanel(); p.canChooseDirectories = true; p.canChooseFiles = false; p.canCreateDirectories = true
        p.directoryURL = s.screenshotFolderURL
        if p.runModal() == .OK, let url = p.url { s.screenshotFolderPath = url.path }
    }
}

@MainActor enum LoginItem {
    static var enabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set { do { newValue ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister() } catch { Toast.show("Couldn't change login item", systemImage: "exclamationmark.triangle") } }
    }
}

struct ShortcutsPane: View {
    @ObservedObject var hk = Hotkeys.shared
    private let sections = ["General", "Screenshots", "OCR", "Recording", "Annotate & Pin"]
    var body: some View {
        VStack(spacing: 14) {
            ForEach(sections, id: \.self) { sec in
                VStack(spacing: 0) {
                    Text(sec).font(.system(size: 17, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading).padding(14)
                    ForEach(HotkeyAction.allCases.filter { $0.section == sec }) { a in
                        Divider()
                        HStack { Text(a.label + ":"); Spacer(); ShortcutRecorder(action: a) }.padding(.horizontal, 14).padding(.vertical, 8)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.08)))
            }
            HStack { Spacer(); Button("Restore Defaults") { hk.restoreDefaults() } }
        }.padding(.horizontal, 20)
    }
}

struct ShortcutRecorder: View {
    let action: HotkeyAction
    @ObservedObject var hk = Hotkeys.shared
    @State private var recording = false
    @State private var monitor: Any?
    var body: some View {
        Button { startRecording() } label: {
            Text(recording ? "Press keys…" : (hk.combo(action)?.displayString ?? "Record shortcut"))
                .font(.system(size: 13, weight: hk.combo(action) == nil ? .regular : .semibold))
                .foregroundStyle(hk.combo(action) == nil && !recording ? Color.white.opacity(0.5) : .white)
                .frame(width: 180, height: 30)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(recording ? 0.25 : (hk.combo(action) == nil ? 0.08 : 0.18))))
        }.buttonStyle(.plain)
        .contextMenu { Button("Clear") { hk.set(nil, for: action) } }
    }
    private func startRecording() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { e in
            if e.keyCode == 53 { stop(); return nil }
            if e.keyCode == 51 { hk.set(nil, for: action); stop(); return nil }
            if let c = HotkeyCombo.from(event: e) { hk.set(c, for: action); stop(); return nil }
            return e
        }
    }
    private func stop() { recording = false; if let m = monitor { NSEvent.removeMonitor(m) }; monitor = nil }
}

struct AboutPane: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 96, height: 96)
            Text("CleanShotXIsDead").font(.system(size: 22, weight: .bold))
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev")").foregroundStyle(.secondary)
            Text("A free, open-source screenshot and recording app for the Mac.\nNo account, no license, no subscription.").multilineTextAlignment(.center).padding(.top, 6)
            HStack(spacing: 14) {
                Link("Website", destination: URL(string: "https://yourappisdead.com/cleanshotxisdead")!)
                Link("Source on GitHub", destination: URL(string: "https://github.com/tommy-muckstack/cleanshotxisdead")!)
            }.padding(.top, 4)
            Text("Not affiliated with CleanShot X. CleanShot X is a trademark of its owner. Apache-2.0.").font(.system(size: 11)).foregroundStyle(.secondary).padding(.top, 20)
        }.padding(30)
    }
}


struct WallpaperPane: View {
    @ObservedObject var s = SettingsStore.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Choose a wallpaper to display when desktop icons are hidden:").foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 12) {
                radio("Desktop wallpaper", "desktop")
                HStack(spacing: 10) { radio("Custom wallpaper:", "custom"); Button(s.wallpaperImagePath.isEmpty ? "Choose…" : (s.wallpaperImagePath as NSString).lastPathComponent) { chooseImage() }.frame(width: 300, alignment: .leading) }
                HStack(spacing: 10) { radio("Plain color:", "plain"); ColorPicker("", selection: Binding(get: { Color(nsColor: NSColor(hex: s.wallpaperColorHex) ?? .darkGray) }, set: { s.wallpaperColorHex = NSColor($0).hexString })).labelsHidden() }
            }.padding(.leading, 8)
            Divider().padding(.vertical, 6)
            HStack(alignment: .top, spacing: 30) {
                VStack(alignment: .leading, spacing: 6) { Text("Window screenshots:").font(.system(size: 14, weight: .semibold)); Text("Hold ⇧ Shift while taking a screenshot to get a transparent background.").foregroundStyle(.secondary).frame(width: 230, alignment: .leading) }
                HStack(spacing: 40) {
                    styleTile("With wallpaper", "wallpaper", wallpaper: true)
                    styleTile("Transparent", "transparent", wallpaper: false)
                }
            }
            HStack { Text("Padding:").frame(width: 100, alignment: .leading); VStack(spacing: 2) { Slider(value: $s.windowPadding, in: 0...1, step: 0.25); HStack { Text("Min"); Spacer(); Text("Default"); Spacer(); Text("Max") }.font(.system(size: 11)).foregroundStyle(.secondary) }.frame(width: 420) }
            HStack(alignment: .top) { Text("Shadow:").frame(width: 100, alignment: .leading); VStack(alignment: .leading) { Toggle("Capture window shadow", isOn: $s.captureWindowShadow); Text("Hold ⌥ (option) while taking a screenshot to disable shadow.").foregroundStyle(.secondary) } }
        }.padding(.horizontal, 36)
        .onChange(of: s.wallpaperMode) { DesktopCover.apply() }
    }
    private func radio(_ title: String, _ value: String) -> some View {
        Button { s.wallpaperMode = value } label: { HStack(spacing: 8) { Image(systemName: s.wallpaperMode == value ? "largecircle.fill.circle" : "circle").foregroundStyle(s.wallpaperMode == value ? MM.Colors.accent : .secondary); Text(title) } }.buttonStyle(.plain)
    }
    private func styleTile(_ title: String, _ value: String, wallpaper: Bool) -> some View {
        Button { s.windowScreenshotStyle = value } label: {
            VStack(spacing: 10) {
                ZStack {
                    if wallpaper { LinearGradient(colors: [.orange, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) } else { Checker() }
                    RoundedRectangle(cornerRadius: 6).fill(Color.white).frame(width: 70, height: 48).overlay(alignment: .topLeading) { HStack(spacing: 3) { Circle().fill(.red); Circle().fill(.yellow); Circle().fill(.green) }.frame(height: 6).padding(5) }
                }.frame(width: 120, height: 90).clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(s.windowScreenshotStyle == value ? MM.Colors.accent : .clear, lineWidth: 3))
                Text(title).foregroundStyle(s.windowScreenshotStyle == value ? .primary : .secondary)
            }
        }.buttonStyle(.plain)
    }
    private func chooseImage() {
        let p = NSOpenPanel(); p.allowedContentTypes = [.image]; if p.runModal() == .OK, let u = p.url { s.wallpaperImagePath = u.path; s.wallpaperMode = "custom" }
    }
    private struct Checker: View { var body: some View { Canvas { ctx, size in for y in stride(from: 0, to: size.height, by: 10) { for x in stride(from: 0, to: size.width, by: 10) { ctx.fill(Path(CGRect(x: x, y: y, width: 10, height: 10)), with: .color(((Int(x / 10) + Int(y / 10)) % 2 == 0) ? Color.gray.opacity(0.5) : Color.gray.opacity(0.25))) } } } } }
}

struct RecordingPane: View {
    @ObservedObject var s = SettingsStore.shared
    @State private var tab = "General"
    var body: some View {
        VStack(spacing: 16) {
            Picker("", selection: $tab) { Text("General").tag("General"); Text("Video").tag("Video"); Text("GIF").tag("GIF") }.pickerStyle(.segmented).labelsHidden().frame(width: 260)
            Group {
                if tab == "General" {
                    Form {
                        LabeledContent("Controls:") { Toggle("Show controls while recording", isOn: $s.showRecordingControls) }
                        LabeledContent("Menu bar:") { Toggle("Display recording time", isOn: $s.menuBarRecordingTime) }
                        LabeledContent("Retina:") { Toggle("Scale Retina videos to 1x", isOn: $s.scaleRetinaVideos) }
                        LabeledContent("Cursor:") { VStack(alignment: .leading) { Toggle("Show cursor", isOn: $s.showCursorInRecordings); Toggle("Highlight clicks", isOn: $s.cursorEffects) } }
                        LabeledContent("Keyboard:") { VStack(alignment: .leading) { Toggle("Show keystrokes", isOn: $s.showKeystrokes).onChange(of: s.showKeystrokes) { if s.showKeystrokes, !KeystrokeOverlay.accessibilityGranted { KeystrokeOverlay.requestAccessibility() } }; if s.showKeystrokes, !KeystrokeOverlay.accessibilityGranted { Text("Needs Accessibility access (System Settings → Privacy & Security).").foregroundStyle(.secondary) } } }
                        LabeledContent("Audio:") { VStack(alignment: .leading) { Toggle("Record microphone", isOn: $s.recordMicrophone); Toggle("Record computer audio", isOn: $s.recordComputerAudio) } }
                        LabeledContent("Recording area:") { VStack(alignment: .leading) { Toggle("Remember last selection", isOn: $s.rememberLastSelection); Toggle("Show countdown", isOn: $s.showCountdown) } }
                    }
                } else if tab == "Video" {
                    Form {
                        LabeledContent("Max resolution:") { VStack(alignment: .leading) { Picker("", selection: $s.videoQuality) { Text("Original").tag("High"); Text("1080p").tag("1080p"); Text("720p").tag("720p") }.labelsHidden().frame(width: 140); Text("Set maximum resolution to reduce file size and upload time.").foregroundStyle(.secondary) } }
                        LabeledContent("Video FPS:") { Picker("", selection: $s.videoFPS) { ForEach([24, 30, 60], id: \.self) { Text("\($0)").tag($0) } }.labelsHidden().frame(width: 90) }
                        LabeledContent("Format:") { Text("MP4 (H.264)").foregroundStyle(.secondary) }
                    }
                } else {
                    Form {
                        LabeledContent("GIF FPS:") { HStack { Text("\(s.gifFPS)").frame(width: 40).padding(.vertical, 4).background(RoundedRectangle(cornerRadius: 6).fill(.black.opacity(0.4))); Slider(value: Binding(get: { Double(s.gifFPS) }, set: { s.gifFPS = Int($0) }), in: 5...30, step: 1).frame(width: 260) } }
                        LabeledContent("GIF quality:") { VStack(alignment: .leading) { HStack { Slider(value: $s.gifQuality, in: 0...1, step: 0.1).frame(width: 200); Toggle("Optimize GIFs", isOn: $s.gifLoop) }; HStack { Text("Low"); Spacer(); Text("High") }.font(.system(size: 11)).foregroundStyle(.secondary).frame(width: 200); Text("Setting the quality to maximum can speed up the processing time, but it will increase file size.").foregroundStyle(.secondary).frame(width: 340, alignment: .leading) } }
                        LabeledContent("GIF size:") { VStack(alignment: .leading) { Picker("", selection: $s.gifMaxWidth) { Text("480 x auto").tag(480); Text("640 x auto").tag(640); Text("800 x auto (default)").tag(800); Text("1280 x auto").tag(1280); Text("Original").tag(100000) }.labelsHidden().frame(width: 220); Text("Set maximum resolution of your GIFs. The GIF is only downscaled if needed.").foregroundStyle(.secondary).frame(width: 340, alignment: .leading) } }
                    }
                }
            }.formStyle(.columns).padding(.horizontal, 36)
        }
    }
}
