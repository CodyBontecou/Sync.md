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
