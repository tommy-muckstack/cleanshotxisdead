import AppKit
import AVFoundation
import ImageIO
import UniformTypeIdentifiers

/// MP4 → animated GIF at the GIF pane's fps/size/quality. Runs off the main
/// actor; reports progress 0…1.
enum GifExporter {
    static func export(movie: URL, to output: URL, fps: Int, maxWidth: CGFloat, quality: Double, loop: Bool, progress: @escaping @Sendable (Double) -> Void) async throws {
        let asset = AVURLAsset(url: movie)
        let duration = try await asset.load(.duration).seconds
        guard duration > 0 else { throw AgentError("EMPTY", "The recording is empty.") }
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.requestedTimeToleranceBefore = .zero; gen.requestedTimeToleranceAfter = CMTime(value: 1, timescale: Int32(fps * 2))
        if let track = try await asset.loadTracks(withMediaType: .video).first {
            let size = try await track.load(.naturalSize)
            let w = min(maxWidth, size.width)
            gen.maximumSize = CGSize(width: w, height: w * size.height / max(1, size.width))
        }
        let frameCount = max(1, Int(duration * Double(fps)))
        guard let dest = CGImageDestinationCreateWithURL(output as CFURL, UTType.gif.identifier as CFString, frameCount, nil) else { throw AgentError("GIF", "Couldn't create the GIF file.") }
        CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: loop ? 0 : 1]] as CFDictionary)
        let delay = 1.0 / Double(fps)
        let frameProps = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay, kCGImagePropertyGIFUnclampedDelayTime: delay]] as CFDictionary
        for i in 0..<frameCount {
            try Task.checkCancellation()
            let t = CMTime(seconds: Double(i) * delay, preferredTimescale: 600)
            if let cg = try? gen.copyCGImage(at: t, actualTime: nil) {
                CGImageDestinationAddImage(dest, quality < 0.5 ? downsample(cg, factor: 0.75) ?? cg : cg, frameProps)
            }
            if i % 5 == 0 { progress(Double(i) / Double(frameCount)) }
        }
        guard CGImageDestinationFinalize(dest) else { throw AgentError("GIF", "Couldn't finish the GIF.") }
        progress(1)
    }
    private static func downsample(_ cg: CGImage, factor: CGFloat) -> CGImage? {
        let w = Int(CGFloat(cg.width) * factor), h = Int(CGFloat(cg.height) * factor)
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.interpolationQuality = .medium; ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h)); return ctx.makeImage()
    }
}
