import AppKit
import Foundation

/// Uploads a capture to the CleanShotXIsDead web app and copies the share link.
/// Uses a guest session (no account) kept in the cookie jar.
@MainActor
final class CloudUploader {
    static let shared = CloudUploader()
    private var base: URL { URL(string: SettingsStore.shared.cloudBaseURL) ?? URL(string: "https://yourappisdead.com/cleanshotxisdead")! }

    func upload(_ entry: HistoryEntry) async {
        guard entry.kind == .screenshot else { Toast.show("Recordings can't be uploaded yet", systemImage: "icloud.slash"); return }
        Toast.show("Uploading…", systemImage: "icloud.and.arrow.up", duration: 30)
        do {
            try await ensureSession()
            let link = try await post(entry)
            NSPasteboard.general.clearContents(); NSPasteboard.general.setString(link, forType: .string)
            var updated = entry; updated.cloudURL = link; HistoryStore.shared.update(updated)
            Toast.show("Link copied to clipboard", systemImage: "link", actionLabel: "Open", action: { if let u = URL(string: link) { NSWorkspace.shared.open(u) } })
        } catch { Toast.show("Upload failed: \(error.localizedDescription)", systemImage: "exclamationmark.triangle") }
    }

    private func ensureSession() async throws {
        let cookies = HTTPCookieStorage.shared.cookies(for: base) ?? []
        if cookies.contains(where: { $0.name.contains("guest") || $0.name.contains("session") }) { return }
        var req = URLRequest(url: base.appendingPathComponent("api/session/guest").appending(queryItems: [URLQueryItem(name: "next", value: "/app")]))
        req.httpMethod = "GET"
        _ = try await URLSession.shared.data(for: req)
    }

    private func post(_ entry: HistoryEntry) async throws -> String {
        let data = try Data(contentsOf: entry.fileURL)
        let boundary = "----csx\(UUID().uuidString)"
        var body = Data()
        func add(_ s: String) { body.append(s.data(using: .utf8)!) }
        add("--\(boundary)\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\n\(entry.fileURL.deletingPathExtension().lastPathComponent)\r\n")
        add("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(entry.fileURL.lastPathComponent)\"\r\nContent-Type: image/\(entry.fileURL.pathExtension == "jpg" ? "jpeg" : "png")\r\n\r\n")
        body.append(data); add("\r\n--\(boundary)--\r\n")
        var req = URLRequest(url: base.appendingPathComponent("api/shots"))
        req.httpMethod = "POST"; req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type"); req.httpBody = body
        let (resp, http) = try await URLSession.shared.data(for: req)
        guard let code = (http as? HTTPURLResponse)?.statusCode, (200..<300).contains(code) else {
            let msg = (try? JSONSerialization.jsonObject(with: resp) as? [String: Any])?["error"] as? String
            throw AgentError("HTTP", msg ?? "server returned \((http as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        guard let json = try JSONSerialization.jsonObject(with: resp) as? [String: Any], let path = json["url"] as? String else { throw AgentError("PARSE", "unexpected response") }
        if path.hasPrefix("http") { return path }
        let origin = base.scheme! + "://" + base.host!
        let bp = base.path
        return origin + (path.hasPrefix(bp) ? path : bp + path)
    }
}
