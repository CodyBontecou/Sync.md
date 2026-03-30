import Foundation

enum GitDiffChangeType: String, Codable, Sendable {
    case added
    case modified
    case deleted
    case renamed
    case copied
    case typeChanged
    case unreadable
    case conflicted
    case unknown
}

struct GitFileDiff: Codable, Sendable, Equatable {
    let path: String
    let oldPath: String?
    let newPath: String?
    let changeType: GitDiffChangeType
    let isBinary: Bool
    let patch: String
}

struct UnifiedDiffResult: Codable, Sendable, Equatable {
    let files: [GitFileDiff]
    let rawPatch: String

    static let empty = UnifiedDiffResult(files: [], rawPatch: "")
}
