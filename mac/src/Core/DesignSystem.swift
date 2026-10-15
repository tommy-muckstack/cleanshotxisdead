import AppKit
import SwiftUI

/// Design tokens. The capture/editor surfaces inherited from My Man read these
/// names; values are retuned to CleanShot X's dark, neutral palette.
enum GellixWeight { case regular, medium, semiBold, bold
    var font: Font.Weight { switch self { case .regular: .regular; case .medium: .medium; case .semiBold: .semibold; case .bold: .bold } }
    var ns: NSFont.Weight { switch self { case .regular: .regular; case .medium: .medium; case .semiBold: .semibold; case .bold: .bold } }
}

enum MM {
    enum Colors {
        private static func dynamic(_ light: NSColor, _ dark: NSColor) -> Color {
            Color(nsColor: NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light })
        }
        static let background = dynamic(NSColor(white: 0.97, alpha: 1), NSColor(white: 0.13, alpha: 1))
        static let surface = dynamic(NSColor(white: 1, alpha: 1), NSColor(white: 0.17, alpha: 1))
        static let textPrimary = dynamic(NSColor(white: 0.08, alpha: 1), NSColor(white: 0.95, alpha: 1))
        static let textSecondary = dynamic(NSColor(white: 0.40, alpha: 1), NSColor(white: 0.66, alpha: 1))
        static let textTertiary = dynamic(NSColor(white: 0.60, alpha: 1), NSColor(white: 0.48, alpha: 1))
        static let border = dynamic(NSColor(white: 0, alpha: 0.10), NSColor(white: 1, alpha: 0.10))
        static let accent = Color(red: 0.16, green: 0.42, blue: 1.0)
        static let onAccent = Color.white
        static let danger = Color(red: 0.94, green: 0.30, blue: 0.27)
        static let flame = accent
    }
    enum Fonts {
        static let tableSize: CGFloat = 13
        static func gellix(_ size: CGFloat, _ weight: GellixWeight = .regular) -> Font { .system(size: size, weight: weight.font) }
        static func native(_ size: CGFloat, _ weight: GellixWeight = .regular, italic: Bool = false) -> NSFont {
            let f = NSFont.systemFont(ofSize: size, weight: weight.ns)
            return italic ? NSFontManager.shared.convert(f, toHaveTrait: .italicFontMask) : f
        }
        static func coreText(_ size: CGFloat, _ weight: GellixWeight = .regular) -> CTFont { native(size, weight) }
        static var title: Font { .system(size: 17, weight: .semibold) }
        static var body: Font { .system(size: 13) }
        static var secondary: Font { .system(size: 12) }
        static var metadata: Font { .system(size: 11) }
        static var hint: Font { .system(size: 11) }
    }
    enum Layout {
        static let padding: CGFloat = 12
        static let paddingLarge: CGFloat = 16
        static let radius: CGFloat = 10
        static let radiusSmall: CGFloat = 6
        static let spacing: CGFloat = 10
    }
    enum Motion {
        static let gentle = Animation.easeInOut(duration: 0.22)
        static let elastic = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let silky = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.28)
    }
}

extension View {
    /// Clickable standard: pointer cursor + a comfortable hit area.
    func clickable(minSize: CGFloat = 24) -> some View {
        frame(minWidth: minSize, minHeight: minSize).contentShape(Rectangle())
            .onHover { inside in inside ? NSCursor.pointingHand.push() : NSCursor.pop() }
    }
}

enum Analytics {
    /// No product analytics in the Mac app. Kept so ported code reads unchanged.
    static func track(_ event: String, _ properties: [String: Any] = [:]) {}
}
