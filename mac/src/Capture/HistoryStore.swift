import AppKit
import Foundation

/// Capture History: every capture lands in the app's history folder first; the
/// overlay's Save copies it to the export location. Entries persist as JSON.
struct HistoryEntry: Codable, Identifiable, Equatable {
    enum Kind: String, Codable { case screenshot, recording }
    var id: String
    var path: String
    var kind: Kind
    var createdAt: Date
    var cloudURL: String?
    var fileURL: URL { URL(fileURLWithPath: path) }
}

@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    @Published private(set) var entries: [HistoryEntry] = []
    static let folder: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CleanShotXIsDead", isDirectory: true)
        try? FileManager.default.createDirectory(at: base.appendingPathComponent("History"), withIntermediateDirectories: true)
        return base
    }()
    private var indexURL: URL { Self.folder.appendingPathComponent("history.json") }

    private init() {
        if let data = try? Data(contentsOf: indexURL), let list = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            entries = list.filter { FileManager.default.fileExists(atPath: $0.path) }
        }
    }

    func add(_ entry: HistoryEntry) {
        entries.insert(entry, at: 0)
        if entries.count > 500 { entries.removeLast(entries.count - 500) }
        persist()
    }
    func update(_ entry: HistoryEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) { entries[i] = entry; persist() }
    }
    func remove(_ entry: HistoryEntry, deleteFile: Bool) {
        entries.removeAll { $0.id == entry.id }
        if deleteFile { try? FileManager.default.removeItem(at: entry.fileURL) }
        persist()
    }
    private func persist() {
        if let data = try? JSONEncoder().encode(entries) { try? data.write(to: indexURL, options: .atomic) }
    }

    /// File name from the Advanced pattern, e.g. "CleanShotX 2026-10-15 at 18.14.48".
    static func fileName(for date: Date, ext: String, retina: Bool) -> String {
        let map: [(String, String)] = [("%y", "yyyy"), ("%m", "MM"), ("%d", "dd"), ("%H", "HH"), ("%M", "mm"), ("%S", "ss")]
        var pattern = SettingsStore.shared.fileNamePattern
        for (k, v) in map { pattern = pattern.replacingOccurrences(of: k, with: "'\u{1}" + v + "\u{2}'") }
        // Literal text is quoted; date fields are unquoted.
        pattern = "'" + pattern.replacingOccurrences(of: "'\u{1}", with: "'").replacingOccurrences(of: "\u{2}'", with: "'") + "'"
        pattern = pattern.replacingOccurrences(of: "''", with: "")
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = pattern
        var name = f.string(from: date).replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: ".")
        if retina { name += "@2x" }
        return name + "." + ext
    }
}
