import AppKit
import AVFoundation
import ScreenCaptureKit
import SwiftUI

/// Region screen recording to .mp4 via ScreenCaptureKit's recording output.
@MainActor
final class ScreenRecorder: NSObject, ObservableObject {
    static let shared = ScreenRecorder()
    enum Mode: String { case video, gif }
    @Published private(set) var isRecording = false
    @Published private(set) var startedAt: Date?
    @Published var mode: Mode = .video
    private var chooser: RecordingChooser?
    private var region = CGRect.zero
    private var stream: SCStream?
    private var output: Any?
    private var outputURL: URL?
    private var controls: RecordingControls?
    var onStateChange: (() -> Void)?

    func toggle() { isRecording ? stop() : CaptureController.shared.captureArea(.record) }

    /// After the area is selected: show CleanShot's pre-record bar (Video / GIF,
    /// mic, Start). Start → begin(region:).
    func start(region: CGRect) {
        guard #available(macOS 15.0, *) else { Toast.show("Screen recording needs macOS 15 or newer", systemImage: "video.slash"); return }
        self.region = region
        chooser?.close(); chooser = RecordingChooser(recorder: self, region: region); chooser?.show()
    }
    func cancelChooser() { chooser?.close(); chooser = nil }
    func begin() {
        chooser?.close(); chooser = nil
        let region = self.region
        guard #available(macOS 15.0, *) else { return }
        Task { @MainActor in
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                let displays = DisplayLayout.allDisplays(from: content)
                guard let display = displays.first(where: { $0.frame.intersects(region) }) ?? displays.first else { return }
                let filter = SCContentFilter(display: display.scDisplay, excludingWindows: [])
                let cfg = SCStreamConfiguration()
                let s = SettingsStore.shared
                let scale = s.scaleRetinaVideos ? 1 : display.scaleFactor
                let local = CGRect(x: region.minX - display.frame.minX, y: display.frame.maxY - region.maxY, width: region.width, height: region.height)
                cfg.sourceRect = local
                cfg.width = Int(region.width * scale); cfg.height = Int(region.height * scale)
                cfg.showsCursor = s.showCursorInRecordings
                cfg.capturesAudio = s.recordComputerAudio
                cfg.captureMicrophone = s.recordMicrophone
                cfg.minimumFrameInterval = CMTime(value: 1, timescale: Int32(mode == .gif ? max(10, s.gifFPS) : s.videoFPS))
                if s.videoQuality == "1080p", cfg.width > 1920 { let k = 1920.0 / Double(cfg.width); cfg.width = 1920; cfg.height = Int(Double(cfg.height) * k) }
                if s.videoQuality == "720p", cfg.width > 1280 { let k = 1280.0 / Double(cfg.width); cfg.width = 1280; cfg.height = Int(Double(cfg.height) * k) }
                let stream = SCStream(filter: filter, configuration: cfg, delegate: nil)
                let url = HistoryStore.folder.appendingPathComponent("History").appendingPathComponent(HistoryStore.fileName(for: Date(), ext: "mp4", retina: false))
                let recCfg = SCRecordingOutputConfiguration(); recCfg.outputURL = url; recCfg.outputFileType = .mp4; recCfg.videoCodecType = .h264
                let rec = SCRecordingOutput(configuration: recCfg, delegate: self)
                try stream.addRecordingOutput(rec)
                if s.showCountdown { await Countdown.run(seconds: 3) }
                try await stream.startCapture()
                self.stream = stream; self.output = rec; self.outputURL = url
                isRecording = true; startedAt = Date(); onStateChange?()
                if s.showRecordingControls { controls = RecordingControls(recorder: self, region: region); controls?.show() }
                if s.cursorEffects { CursorEffects.shared.show(regionAppKit: region) }
                if s.showKeystrokes { KeystrokeOverlay.shared.show(in: region) }
                Analytics.track("app_recording_started", ["mode": mode.rawValue, "mic": s.recordMicrophone, "system_audio": s.recordComputerAudio])
                if s.playSounds { CaptureSoundPlayer.shared.play() }
            } catch { Toast.show("Couldn't start recording: \(error.localizedDescription)", systemImage: "exclamationmark.triangle") }
        }
    }

    func stop() {
        guard isRecording, let stream else { return }
        isRecording = false; onStateChange?()
        controls?.close(); controls = nil
        CursorEffects.shared.hide(); KeystrokeOverlay.shared.hide()
        Task { @MainActor in
            try? await stream.stopCapture()
            self.stream = nil; self.output = nil
            guard let url = outputURL else { return }
            outputURL = nil; try? await Task.sleep(for: .milliseconds(300))
            if mode == .gif { await convertToGif(url) } else { CaptureController.shared.recordingFinished(url: url) }
        }
    }
    var elapsed: TimeInterval { startedAt.map { Date().timeIntervalSince($0) } ?? 0 }

    private var gifTask: Task<Void, Never>?
    private func convertToGif(_ movie: URL) async {
        let s = SettingsStore.shared
        let gif = movie.deletingPathExtension().appendingPathExtension("gif")
        let progress = GifProgress()
        let panel = GifProgress.panel(progress, onCancel: { [weak self] in self?.gifTask?.cancel() })
        gifTask = Task.detached(priority: .userInitiated) {
            do {
                try await GifExporter.export(movie: movie, to: gif, fps: s.gifFPS, maxWidth: CGFloat(s.gifMaxWidth), quality: s.gifQuality, loop: s.gifLoop) { v in Task { @MainActor in progress.value = v } }
                await MainActor.run { panel.orderOut(nil); try? FileManager.default.removeItem(at: movie); CaptureController.shared.recordingFinished(url: gif) }
            } catch is CancellationError {
                await MainActor.run { panel.orderOut(nil); try? FileManager.default.removeItem(at: gif); Toast.show("GIF conversion stopped. Saved as a video instead.", systemImage: "video"); CaptureController.shared.recordingFinished(url: movie) }
            } catch {
                await MainActor.run { panel.orderOut(nil); Toast.show("GIF failed: \(error.localizedDescription). Saved as a video.", systemImage: "exclamationmark.triangle"); CaptureController.shared.recordingFinished(url: movie) }
            }
        }
    }
}

@available(macOS 15.0, *)
extension ScreenRecorder: SCRecordingOutputDelegate {
    nonisolated func recordingOutput(_ recordingOutput: SCRecordingOutput, didFailWithError error: any Error) {
        Task { @MainActor in Toast.show("Recording failed: \(error.localizedDescription)", systemImage: "exclamationmark.triangle"); self.isRecording = false; self.onStateChange?() }
    }
}

/// Floating pill above the recorded region with the timer and a Stop button.
@MainActor
final class RecordingControls {
    private let panel: NSPanel
    init(recorder: ScreenRecorder, region: CGRect) {
        panel = NSPanel(contentRect: NSRect(x: region.midX - 90, y: max(region.minY - 52, 8), width: 180, height: 40), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isFloatingPanel = true; panel.level = .screenSaver; panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]; panel.isMovableByWindowBackground = true
        panel.contentView = NSHostingView(rootView: ControlsView(recorder: recorder))
    }
    func show() { panel.orderFrontRegardless() }
    func close() { panel.orderOut(nil) }
    private struct ControlsView: View {
        @ObservedObject var recorder: ScreenRecorder
        @State private var tick = 0
        let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        var body: some View {
            HStack(spacing: 10) {
                Circle().fill(Color.red).frame(width: 9, height: 9)
                Text(time).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundStyle(.white)
                Spacer()
                Button { recorder.stop() } label: { Image(systemName: "stop.fill").font(.system(size: 12, weight: .bold)).foregroundStyle(.white).frame(width: 28, height: 28).background(Circle().fill(Color.red)) }
                    .buttonStyle(.plain).help("Stop recording")
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.black.opacity(0.85)))
            .onReceive(timer) { _ in tick += 1 }
        }
        private var time: String { _ = tick; let e = Int(recorder.elapsed); return String(format: "%02d:%02d", e / 60, e % 60) }
    }
}


/// CleanShot's pre-record bar: Video / GIF, mic + system audio toggles, Start.
@MainActor
final class RecordingChooser {
    private let panel: NSPanel
    init(recorder: ScreenRecorder, region: CGRect) {
        panel = NSPanel(contentRect: NSRect(x: region.midX - 250, y: max(region.minY - 60, 8), width: 500, height: 48), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isFloatingPanel = true; panel.level = .screenSaver; panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = true; panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: ChooserView(recorder: recorder))
        frame = NSPanel(contentRect: region.insetBy(dx: -2, dy: -2), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        frame.isOpaque = false; frame.backgroundColor = .clear; frame.hasShadow = false; frame.ignoresMouseEvents = true; frame.level = .screenSaver
        frame.contentView = NSHostingView(rootView: RoundedRectangle(cornerRadius: 3).strokeBorder(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [6, 4])))
    }
    private let frame: NSPanel
    func show() { frame.orderFrontRegardless(); panel.orderFrontRegardless() }
    func close() { panel.orderOut(nil); frame.orderOut(nil) }
    private struct ChooserView: View {
        @ObservedObject var recorder: ScreenRecorder
        @ObservedObject var s = SettingsStore.shared
        var body: some View {
            HStack(spacing: 8) {
                seg("video", "Video", recorder.mode == .video) { recorder.mode = .video }
                seg("photo.on.rectangle", "GIF", recorder.mode == .gif) { recorder.mode = .gif }
                Divider().frame(height: 20).overlay(Color.white.opacity(0.2))
                tog("mic", "Microphone", $s.recordMicrophone)
                tog("speaker.wave.2", "Computer audio", $s.recordComputerAudio, offSymbol: "speaker.slash")
                Spacer()
                Button { recorder.cancelChooser() } label: { Image(systemName: "xmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white).frame(width: 26, height: 26) }.buttonStyle(.plain)
                Button { recorder.begin() } label: {
                    HStack(spacing: 6) { Circle().fill(Color.red).frame(width: 8, height: 8); Text(recorder.mode == .gif ? "Start GIF Recording" : "Start Recording").font(.system(size: 12, weight: .semibold)).lineLimit(1).fixedSize() }
                        .foregroundStyle(.white).padding(.horizontal, 12).frame(height: 30).background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.16, green: 0.42, blue: 1)))
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 10).frame(height: 48)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.black.opacity(0.85)))
        }
        private func seg(_ symbol: String, _ title: String, _ on: Bool, _ run: @escaping () -> Void) -> some View {
            Button(action: run) { HStack(spacing: 5) { Image(systemName: symbol); Text(title) }.font(.system(size: 12, weight: .medium)).foregroundStyle(.white).padding(.horizontal, 10).frame(height: 30).background(RoundedRectangle(cornerRadius: 8).fill(on ? Color.white.opacity(0.22) : .clear)) }.buttonStyle(.plain)
        }
        private func tog(_ symbol: String, _ help: String, _ b: Binding<Bool>, offSymbol: String? = nil) -> some View {
            Button { b.wrappedValue.toggle() } label: { Image(systemName: b.wrappedValue ? symbol : (offSymbol ?? symbol + ".slash")).font(.system(size: 13, weight: .medium)).foregroundStyle(b.wrappedValue ? .white : .white.opacity(0.45)).frame(width: 30, height: 30).background(RoundedRectangle(cornerRadius: 8).fill(b.wrappedValue ? Color.white.opacity(0.18) : .clear)) }.buttonStyle(.plain).help(help)
        }
    }
}

@MainActor
final class GifProgress: ObservableObject {
    @Published var value: Double = 0
    static func panel(_ model: GifProgress, onCancel: @escaping () -> Void) -> NSPanel {
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 300, height: 70), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.isFloatingPanel = true; p.level = .floating; p.isOpaque = false; p.backgroundColor = .clear; p.hasShadow = true
        p.contentView = NSHostingView(rootView: View(model: model, onCancel: onCancel)); p.center(); p.orderFrontRegardless(); return p
    }
    private struct View: SwiftUI.View {
        @ObservedObject var model: GifProgress; let onCancel: () -> Void
        var body: some SwiftUI.View {
            VStack(spacing: 8) {
                HStack { Text("Creating GIF…").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white); Spacer(); Button("Save as video") { onCancel() }.buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(.white.opacity(0.8)) }
                ProgressView(value: model.value).tint(Color(red: 0.16, green: 0.42, blue: 1))
            }.padding(14).background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.black.opacity(0.85)))
        }
    }
}
