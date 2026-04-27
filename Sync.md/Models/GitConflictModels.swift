import Foundation

enum ConflictSessionKind: String, Codable, Sendable {
    case none
    case merge
    case rebase
    case cherryPick
    case revert
    case applyMailbox
    case unknown
}

enum ConflictResolutionStrategy: String, Codable, Sendable, CaseIterable {
    case ours
    case theirs
    case manual
}

struct ConflictSession: Codable, Sendable, Equatable {
    let kind: ConflictSessionKind
    let unmergedPaths: [String]

    var hasConflicts: Bool { !unmergedPaths.isEmpty }
    var isActive: Bool { kind != .none || hasConflicts }

    static let none = ConflictSession(kind: .none, unmergedPaths: [])
}

/// One side of a 3-way merge conflict (ancestor / ours / theirs).
struct ConflictFileSide: Sendable, Equatable {
    let path: String
    let oid: String
    let isBinary: Bool
    let content: Data?
}

/// Full conflict information for one logical conflict, gathered from libgit2's
/// 3-stage index. For rename/rename conflicts the sides have different `path`s.
struct ConflictFileDetail: Sendable, Equatable {
    let lookupPath: String
    let ancestor: ConflictFileSide?
    let ours: ConflictFileSide?
    let theirs: ConflictFileSide?

    /// Both sides exist with different paths — same ancestor file renamed two ways.
    var isRenameRename: Bool {
        guard let ours, let theirs else { return false }
        return ours.path != theirs.path
    }

    /// Both sides exist at the same path — classic content conflict.
    var isContentConflict: Bool {
        guard let ours, let theirs else { return false }
        return ours.path == theirs.path
    }

    /// One side deleted while the other modified.
    var isDeleteModify: Bool {
        ancestor != nil && (ours == nil || theirs == nil)
    }

    /// All paths involved in this conflict (used for cleanup when resolving).
    var allPaths: [String] {
        var paths: [String] = []
        if let ancestor { paths.append(ancestor.path) }
        if let ours { paths.append(ours.path) }
        if let theirs { paths.append(theirs.path) }
        var seen = Set<String>()
        return paths.filter { seen.insert($0).inserted }
    }
}
