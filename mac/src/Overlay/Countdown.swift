import AppKit
import SwiftUI

/// Self-timer HUD: a big number in the middle of the screen.
@MainActor
enum Countdown {
    static func run(seconds: Int) async {
        let model = Model(); model.value = seconds
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 160, height: 160), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.isFloatingPanel = true; p.level = .screenSaver; p.isOpaque = false; p.backgroundColor = .clear; p.hasShadow = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.contentView = NSHostingView(rootView: HUD(model: model))
        p.center(); p.orderFrontRegardless()
        for i in stride(from: seconds, to: 0, by: -1) {
            model.value = i
            try? await Task.sleep(for: .seconds(1))
        }
        p.orderOut(nil)
    }
    final class Model: ObservableObject { @Published var value = 0 }
    private struct HUD: View {
        @ObservedObject var model: Model
        var body: some View {
            Text("\(model.value)").font(.system(size: 72, weight: .bold, design: .rounded)).foregroundStyle(.white)
                .frame(width: 140, height: 140)
                .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.black.opacity(0.6)))
                .contentTransition(.numericText(countsDown: true)).animation(.default, value: model.value)
        }
    }
}
