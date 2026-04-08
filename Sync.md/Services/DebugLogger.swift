import Foundation

/// Severity level for debug log entries.
enum LogLevel: String, Codable, Sendable, CaseIterable {
    case info
    case warning
    case error
}

/// A single timestamped log entry.
struct LogEntry: Identifiable, Codable, Sendable {
    let id: UUID
    let date: Date
    let level: LogLevel
    let category: String   // e.g. "pull", "push", "revert", "clone"
    let message: String
    let detail: String?    // optional extra context (error description, path, etc.)

    init(level: LogLevel, category: String, message: String, detail: String? = nil) {
        self.id = UUID()
        self.date = Date()
        self.level = level
        self.category = category
        self.message = message
        self.detail = detail
    }
}

/// Singleton in-memory log buffer with persistence.
@MainActor
final class DebugLogger {
    static let shared = DebugLogger()

    private(set) var entries: [LogEntry] = []
    private let maxEntries = 500
    private let storageKey = "debug_log_entries"

    private init() {
        load()
    }

    // MARK: - Public API

    func log(_ level: LogLevel, category: String, _ message: String, detail: String? = nil) {
        let entry = LogEntry(level: level, category: category, message: message, detail: detail)
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
        save()
    }

    func info(_ category: String, _ message: String, detail: String? = nil) {
        log(.info, category: category, message, detail: detail)
    }

    func warning(_ category: String, _ message: String, detail: String? = nil) {
        log(.warning, category: category, message, detail: detail)
    }

    func error(_ category: String, _ message: String, detail: String? = nil) {
        log(.error, category: category, message, detail: detail)
    }

    func clear() {
        entries.removeAll()
        save()
    }

    /// Formats all entries (or filtered) as a shareable plain-text string.
    func exportText(filter: LogLevel? = nil) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate, .withFullTime, .withFractionalSeconds]

        let filtered = filter == nil ? entries : entries.filter { $0.level == filter }
        return filtered.map { entry in
            var line = "[\(iso.string(from: entry.date))] [\(entry.level.rawValue.uppercased())] [\(entry.category)] \(entry.message)"
            if let detail = entry.detail {
                line += "\n  → \(detail)"
            }
            return line
        }.joined(separator: "\n")
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([LogEntry].self, from: data) else { return }
        entries = decoded
    }
}
