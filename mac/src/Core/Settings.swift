import AppKit
import Foundation

/// Settings backing every preference pane. Keys are stable UserDefaults names.
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    private let d = UserDefaults.standard

    @Published var screenshotFolderPath: String { didSet { d.set(screenshotFolderPath, forKey: "exportLocation") } }
    @Published var playSounds: Bool { didSet { d.set(playSounds, forKey: "playSounds") } }
    @Published var captureSound: CaptureSound { didSet { d.set(captureSound.rawValue, forKey: "captureSound") } }
    @Published var showMenuBarIcon: Bool { didSet { d.set(showMenuBarIcon, forKey: "showMenuBarIcon") } }
    @Published var hideDesktopIconsWhileCapturing: Bool { didSet { d.set(hideDesktopIconsWhileCapturing, forKey: "hideDesktopIconsWhileCapturing") } }
    // After capture
    @Published var afterShotOverlay: Bool { didSet { d.set(afterShotOverlay, forKey: "afterShotOverlay") } }
    @Published var afterShotCopy: Bool { didSet { d.set(afterShotCopy, forKey: "afterShotCopy") } }
    @Published var afterShotSave: Bool { didSet { d.set(afterShotSave, forKey: "afterShotSave") } }
    @Published var afterShotUpload: Bool { didSet { d.set(afterShotUpload, forKey: "afterShotUpload") } }
    @Published var afterShotAnnotate: Bool { didSet { d.set(afterShotAnnotate, forKey: "afterShotAnnotate") } }
    @Published var afterShotPin: Bool { didSet { d.set(afterShotPin, forKey: "afterShotPin") } }
    @Published var afterRecOverlay: Bool { didSet { d.set(afterRecOverlay, forKey: "afterRecOverlay") } }
    @Published var afterRecCopy: Bool { didSet { d.set(afterRecCopy, forKey: "afterRecCopy") } }
    @Published var afterRecSave: Bool { didSet { d.set(afterRecSave, forKey: "afterRecSave") } }
    @Published var afterRecUpload: Bool { didSet { d.set(afterRecUpload, forKey: "afterRecUpload") } }
    // Quick Access
    @Published var overlayPosition: String { didSet { d.set(overlayPosition, forKey: "overlayPosition") } } // Left / Right
    @Published var overlayMoveToActiveScreen: Bool { didSet { d.set(overlayMoveToActiveScreen, forKey: "overlayMoveToActiveScreen") } }
    @Published var overlaySize: Double { didSet { d.set(overlaySize, forKey: "overlaySize") } } // 0...1
    @Published var overlayAutoClose: Bool { didSet { d.set(overlayAutoClose, forKey: "overlayAutoClose") } }
    @Published var overlayAutoCloseAction: String { didSet { d.set(overlayAutoCloseAction, forKey: "overlayAutoCloseAction") } }
    @Published var overlayAutoCloseSeconds: Int { didSet { d.set(overlayAutoCloseSeconds, forKey: "overlayAutoCloseSeconds") } }
    @Published var overlayCloseAfterDrag: Bool { didSet { d.set(overlayCloseAfterDrag, forKey: "overlayCloseAfterDrag") } }
    @Published var overlayCloseAfterUpload: Bool { didSet { d.set(overlayCloseAfterUpload, forKey: "overlayCloseAfterUpload") } }
    // Screenshots
    @Published var fileFormat: String { didSet { d.set(fileFormat, forKey: "fileFormat") } } // PNG / JPG
    @Published var scaleRetinaTo1x: Bool { didSet { d.set(scaleRetinaTo1x, forKey: "scaleRetinaTo1x") } }
    @Published var convertToSRGB: Bool { didSet { d.set(convertToSRGB, forKey: "convertToSRGB") } }
    @Published var addBorder: Bool { didSet { d.set(addBorder, forKey: "addBorder") } }
    @Published var selfTimerSeconds: Int { didSet { d.set(selfTimerSeconds, forKey: "selfTimerSeconds") } }
    @Published var showCursorOnScreenshots: Bool { didSet { d.set(showCursorOnScreenshots, forKey: "showCursorOnScreenshots") } }
    @Published var freezeScreen: Bool { didSet { d.set(freezeScreen, forKey: "freezeScreen") } }
    @Published var crosshairMode: String { didSet { d.set(crosshairMode, forKey: "crosshairMode") } }
    @Published var showMagnifier: Bool { didSet { d.set(showMagnifier, forKey: "showMagnifier") } }
    // Recording
    @Published var showRecordingControls: Bool { didSet { d.set(showRecordingControls, forKey: "showRecordingControls") } }
    @Published var menuBarRecordingTime: Bool { didSet { d.set(menuBarRecordingTime, forKey: "menuBarRecordingTime") } }
    @Published var scaleRetinaVideos: Bool { didSet { d.set(scaleRetinaVideos, forKey: "scaleRetinaVideos") } }
    @Published var dndWhileRecording: Bool { didSet { d.set(dndWhileRecording, forKey: "dndWhileRecording") } }
    @Published var showCursorInRecordings: Bool { didSet { d.set(showCursorInRecordings, forKey: "showCursorInRecordings") } }
    @Published var cursorEffects: Bool { didSet { d.set(cursorEffects, forKey: "highlightClicks") } }
    @Published var showKeystrokes: Bool { didSet { d.set(showKeystrokes, forKey: "showKeystrokes") } }
    @Published var rememberLastSelection: Bool { didSet { d.set(rememberLastSelection, forKey: "rememberLastSelection") } }
    @Published var dimWhileRecording: Bool { didSet { d.set(dimWhileRecording, forKey: "dimWhileRecording") } }
    @Published var showCountdown: Bool { didSet { d.set(showCountdown, forKey: "showCountdown") } }
    @Published var recordMicrophone: Bool { didSet { d.set(recordMicrophone, forKey: "recordMicrophone") } }
    @Published var recordComputerAudio: Bool { didSet { d.set(recordComputerAudio, forKey: "recordComputerAudio") } }
    // Annotate
    @Published var inverseArrow: Bool { didSet { d.set(inverseArrow, forKey: "inverseArrow") } }
    @Published var smoothPencil: Bool { didSet { d.set(smoothPencil, forKey: "smoothPencil") } }
    @Published var drawShadowOnObjects: Bool { didSet { d.set(drawShadowOnObjects, forKey: "drawShadowOnObjects") } }
    @Published var annotateAlwaysOnTop: Bool { didSet { d.set(annotateAlwaysOnTop, forKey: "annotateAlwaysOnTop") } }
    @Published var annotateShowDockIcon: Bool { didSet { d.set(annotateShowDockIcon, forKey: "annotateShowDockIcon") } }
    // Cloud
    @Published var cloudBaseURL: String { didSet { d.set(cloudBaseURL, forKey: "cloudBaseURL") } }
    @Published var cloudCopyLinkAfterUpload: Bool { didSet { d.set(cloudCopyLinkAfterUpload, forKey: "cloudCopyLinkAfterUpload") } }
    // Advanced
    @Published var fileNamePattern: String { didSet { d.set(fileNamePattern, forKey: "fileNamePattern") } }
    @Published var captureHistoryEnabled: Bool { didSet { d.set(captureHistoryEnabled, forKey: "captureHistoryEnabled") } }

    /// Kept for the ported recorder: cursor is always composited by ScreenCaptureKit here.
    var recordCursorSeparately: Bool { false }

    var screenshotFolderURL: URL {
        let url = URL(fileURLWithPath: (screenshotFolderPath as NSString).expandingTildeInPath)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private init() {
        let d = UserDefaults.standard
        func b(_ k: String, _ def: Bool) -> Bool { d.object(forKey: k) == nil ? def : d.bool(forKey: k) }
        func s(_ k: String, _ def: String) -> String { d.string(forKey: k) ?? def }
        func i(_ k: String, _ def: Int) -> Int { d.object(forKey: k) == nil ? def : d.integer(forKey: k) }
        screenshotFolderPath = s("exportLocation", ("~/Desktop" as NSString).expandingTildeInPath)
        playSounds = b("playSounds", true)
        captureSound = CaptureSound(rawValue: s("captureSound", "bloop")) ?? .bloop
        showMenuBarIcon = b("showMenuBarIcon", true)
        hideDesktopIconsWhileCapturing = b("hideDesktopIconsWhileCapturing", false)
        afterShotOverlay = b("afterShotOverlay", true); afterShotCopy = b("afterShotCopy", true); afterShotSave = b("afterShotSave", false)
        afterShotUpload = b("afterShotUpload", false); afterShotAnnotate = b("afterShotAnnotate", false); afterShotPin = b("afterShotPin", false)
        afterRecOverlay = b("afterRecOverlay", true); afterRecCopy = b("afterRecCopy", false); afterRecSave = b("afterRecSave", false); afterRecUpload = b("afterRecUpload", false)
        overlayPosition = s("overlayPosition", "Left"); overlayMoveToActiveScreen = b("overlayMoveToActiveScreen", true)
        overlaySize = d.object(forKey: "overlaySize") == nil ? 0.5 : d.double(forKey: "overlaySize")
        overlayAutoClose = b("overlayAutoClose", true); overlayAutoCloseAction = s("overlayAutoCloseAction", "Save and Close"); overlayAutoCloseSeconds = i("overlayAutoCloseSeconds", 10)
        overlayCloseAfterDrag = b("overlayCloseAfterDrag", true); overlayCloseAfterUpload = b("overlayCloseAfterUpload", true)
        fileFormat = s("fileFormat", "PNG"); scaleRetinaTo1x = b("scaleRetinaTo1x", false); convertToSRGB = b("convertToSRGB", false); addBorder = b("addBorder", false)
        selfTimerSeconds = i("selfTimerSeconds", 5); showCursorOnScreenshots = b("showCursorOnScreenshots", false); freezeScreen = b("freezeScreen", true)
        crosshairMode = s("crosshairMode", "Disabled"); showMagnifier = b("showMagnifier", true)
        showRecordingControls = b("showRecordingControls", true); menuBarRecordingTime = b("menuBarRecordingTime", false); scaleRetinaVideos = b("scaleRetinaVideos", false)
        dndWhileRecording = b("dndWhileRecording", false); showCursorInRecordings = b("showCursorInRecordings", true); cursorEffects = b("highlightClicks", false)
        showKeystrokes = b("showKeystrokes", false); rememberLastSelection = b("rememberLastSelection", false); dimWhileRecording = b("dimWhileRecording", true); showCountdown = b("showCountdown", false)
        recordMicrophone = b("recordMicrophone", false); recordComputerAudio = b("recordComputerAudio", false)
        inverseArrow = b("inverseArrow", false); smoothPencil = b("smoothPencil", true); drawShadowOnObjects = b("drawShadowOnObjects", true)
        annotateAlwaysOnTop = b("annotateAlwaysOnTop", false); annotateShowDockIcon = b("annotateShowDockIcon", true)
        cloudBaseURL = s("cloudBaseURL", "https://yourappisdead.com/cleanshotxisdead"); cloudCopyLinkAfterUpload = b("cloudCopyLinkAfterUpload", true)
        fileNamePattern = s("fileNamePattern", "CleanShotX %y-%m-%d at %H.%M.%S"); captureHistoryEnabled = b("captureHistoryEnabled", true)
    }
}
