import AppKit
import Carbon

struct HotkeyCombo: Codable, Equatable {
    var keyCode: UInt32
    var carbonModifiers: UInt32
    var displayString: String {
        var parts = ""
        if carbonModifiers & UInt32(controlKey) != 0 { parts += "⌃" }
        if carbonModifiers & UInt32(optionKey) != 0 { parts += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { parts += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { parts += "⌘" }
        return parts + " " + Self.keyName(keyCode)
    }
    var menuKeyEquivalent: (String, NSEvent.ModifierFlags) {
        var flags: NSEvent.ModifierFlags = []
        if carbonModifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        if carbonModifiers & UInt32(optionKey) != 0 { flags.insert(.option) }
        if carbonModifiers & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        if carbonModifiers & UInt32(cmdKey) != 0 { flags.insert(.command) }
        return (Self.keyName(keyCode).lowercased(), flags)
    }
    static func from(event: NSEvent) -> HotkeyCombo? {
        var mods: UInt32 = 0
        if event.modifierFlags.contains(.command) { mods |= UInt32(cmdKey) }
        if event.modifierFlags.contains(.option) { mods |= UInt32(optionKey) }
        if event.modifierFlags.contains(.shift) { mods |= UInt32(shiftKey) }
        if event.modifierFlags.contains(.control) { mods |= UInt32(controlKey) }
        guard mods != 0 || functionKeys[UInt32(event.keyCode)] != nil else { return nil }
        return HotkeyCombo(keyCode: UInt32(event.keyCode), carbonModifiers: mods)
    }
    private static let functionKeys: [UInt32: String] = [
        UInt32(kVK_F1): "F1", UInt32(kVK_F2): "F2", UInt32(kVK_F3): "F3", UInt32(kVK_F4): "F4", UInt32(kVK_F5): "F5", UInt32(kVK_F6): "F6",
        UInt32(kVK_F7): "F7", UInt32(kVK_F8): "F8", UInt32(kVK_F9): "F9", UInt32(kVK_F10): "F10", UInt32(kVK_F11): "F11", UInt32(kVK_F12): "F12",
    ]
    static func keyName(_ code: UInt32) -> String {
        let names: [UInt32: String] = [
            UInt32(kVK_Space): "Space", UInt32(kVK_Return): "↩", UInt32(kVK_Tab): "⇥", UInt32(kVK_Escape): "⎋", UInt32(kVK_Delete): "⌫",
            UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C", UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
            UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H", UInt32(kVK_ANSI_I): "I", UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
            UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O", UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
            UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T", UInt32(kVK_ANSI_U): "U", UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
            UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z", UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2", UInt32(kVK_ANSI_3): "3",
            UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5", UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8", UInt32(kVK_ANSI_9): "9",
            UInt32(kVK_ANSI_Grave): "`", UInt32(kVK_ANSI_Minus): "-", UInt32(kVK_ANSI_Equal): "=", UInt32(kVK_ANSI_LeftBracket): "[", UInt32(kVK_ANSI_RightBracket): "]",
            UInt32(kVK_ANSI_Backslash): "\\", UInt32(kVK_ANSI_Semicolon): ";", UInt32(kVK_ANSI_Quote): "'", UInt32(kVK_ANSI_Comma): ",", UInt32(kVK_ANSI_Period): ".", UInt32(kVK_ANSI_Slash): "/",
            UInt32(kVK_LeftArrow): "←", UInt32(kVK_RightArrow): "→", UInt32(kVK_UpArrow): "↑", UInt32(kVK_DownArrow): "↓",
        ].merging(functionKeys) { a, _ in a }
        return names[code] ?? "key\(code)"
    }
}

enum HotkeyAction: String, CaseIterable, Identifiable {
    case allInOne, toggleDesktopIcons, openHistory, restoreLastCapture
    case captureArea, capturePreviousArea, captureFullscreen, captureWindow, scrollingCapture, selfTimer, captureAreaCopy, captureAreaSave, captureAreaUpload, captureAreaAnnotate, captureAreaPin
    case captureText, recordScreen, openAnnotate, openFromClipboard, pinLast, annotateLast
    var id: String { rawValue }
    var section: String {
        switch self {
        case .allInOne, .toggleDesktopIcons, .openHistory, .restoreLastCapture: "General"
        case .captureText: "OCR"
        case .recordScreen: "Recording"
        case .openAnnotate, .openFromClipboard, .pinLast, .annotateLast: "Annotate & Pin"
        default: "Screenshots"
        }
    }
    var label: String {
        switch self {
        case .allInOne: "All-In-One"; case .toggleDesktopIcons: "Toggle Desktop Icons"; case .openHistory: "Open Capture History"; case .restoreLastCapture: "Restore Last Capture"
        case .captureArea: "Capture Area"; case .capturePreviousArea: "Capture Previous Area"; case .scrollingCapture: "Scrolling Capture"; case .captureFullscreen: "Capture Fullscreen"; case .captureWindow: "Capture Window"
        case .selfTimer: "Self-Timer"; case .captureAreaCopy: "Capture Area & Copy to Clipboard"; case .captureAreaSave: "Capture Area & Save"; case .captureAreaUpload: "Capture Area & Upload to Cloud"
        case .captureAreaAnnotate: "Capture Area & Annotate"; case .captureAreaPin: "Capture Area & Pin to the Screen"; case .captureText: "Capture Text"; case .recordScreen: "Record Screen / Stop Recording"
        case .openAnnotate: "Open Annotate tool"; case .openFromClipboard: "Open from Clipboard"; case .pinLast: "Pin Last Screenshot"; case .annotateLast: "Annotate Last Screenshot"
        }
    }
    var defaultCombo: HotkeyCombo? {
        let cs = UInt32(cmdKey | shiftKey)
        switch self {
        case .allInOne: return HotkeyCombo(keyCode: UInt32(kVK_ANSI_5), carbonModifiers: cs)
        case .captureArea: return HotkeyCombo(keyCode: UInt32(kVK_ANSI_4), carbonModifiers: cs)
        case .captureFullscreen: return HotkeyCombo(keyCode: UInt32(kVK_ANSI_3), carbonModifiers: cs)
        case .captureWindow: return HotkeyCombo(keyCode: UInt32(kVK_ANSI_2), carbonModifiers: cs)
        case .captureText: return HotkeyCombo(keyCode: UInt32(kVK_ANSI_1), carbonModifiers: cs)
        case .recordScreen: return HotkeyCombo(keyCode: UInt32(kVK_ANSI_6), carbonModifiers: cs)
        case .openFromClipboard: return HotkeyCombo(keyCode: UInt32(kVK_ANSI_V), carbonModifiers: UInt32(cmdKey | shiftKey | optionKey))
        default: return nil
        }
    }
}

/// Persisted hotkey map + live Carbon registration.
@MainActor
final class Hotkeys: ObservableObject {
    static let shared = Hotkeys()
    @Published private(set) var combos: [HotkeyAction: HotkeyCombo?] = [:]
    private var ids: [UInt32] = []
    var perform: ((HotkeyAction) -> Void)?

    private init() {
        for a in HotkeyAction.allCases {
            if let data = UserDefaults.standard.data(forKey: "hotkey." + a.rawValue) {
                combos[a] = try? JSONDecoder().decode(HotkeyCombo?.self, from: data)
            } else { combos[a] = a.defaultCombo }
        }
    }
    func combo(_ a: HotkeyAction) -> HotkeyCombo? { combos[a] ?? nil }
    func set(_ combo: HotkeyCombo?, for a: HotkeyAction) {
        combos[a] = combo
        UserDefaults.standard.set(try? JSONEncoder().encode(combo), forKey: "hotkey." + a.rawValue)
        registerAll()
    }
    func restoreDefaults() {
        for a in HotkeyAction.allCases { combos[a] = a.defaultCombo; UserDefaults.standard.removeObject(forKey: "hotkey." + a.rawValue) }
        registerAll()
    }
    func registerAll() {
        ids.forEach { HotkeyCenter.shared.unregister($0) }; ids = []
        for a in HotkeyAction.allCases {
            guard let c = combo(a) else { continue }
            if case .success(let id) = HotkeyCenter.shared.register(.init(keyCode: c.keyCode, modifiers: c.carbonModifiers), handler: { [weak self] in
                Task { @MainActor in self?.perform?(a) }
            }) { ids.append(id) }
        }
    }
}
