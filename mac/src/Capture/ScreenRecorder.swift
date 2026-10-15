import AppKit
import AVFoundation
import ScreenCaptureKit
import SwiftUI

/// Region screen recording to .mp4 via ScreenCaptureKit's recording output.
@MainActor
final class ScreenRecorder: NSObject, ObservableObject {
    static let shared = ScreenRecorder()
    @Published private(set) var isRecording = false
    @Published private(set) var startedAt: Date?
    private var stream: SCStream?
    private var output: Any?
    private var outputURL: URL?
    private var controls: RecordingControls?
    var onStateChange: (() -> Void)?

    func toggle() { isRecording ? stop() : CaptureController.shared.captureArea(.record) }

    func start(region: CGRect) {
        guard #available(macOS 15.0, *) else { Toast.show("Screen recording needs macOS 15 or newer", systemImage: "video.slash"); return }
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
                cfg.minimumFrameInterval = CMTime(value: 1, timescale: 60)
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
                if s.playSounds { CaptureSoundPlayer.shared.play() }
            } catch { Toast.show("Couldn't start recording: \(error.localizedDescription)", systemImage: "exclamationmark.triangle") }
        }
    }

    func stop() {
        guard isRecording, let stream else { return }
        isRecording = false; onStateChange?()
        controls?.close(); controls = nil
        Task { @MainActor in
            try? await stream.stopCapture()
            self.stream = nil; self.output = nil
            if let url = outputURL { outputURL = nil; try? await Task.sleep(for: .milliseconds(300)); CaptureController.shared.recordingFinished(url: url) }
        }
    }
    var elapsed: TimeInterval { startedAt.map { Date().timeIntervalSince($0) } ?? 0 }
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
