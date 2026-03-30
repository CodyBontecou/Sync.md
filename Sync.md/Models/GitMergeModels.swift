import Foundation

enum MergeResultKind: String, Codable, Sendable {
    case upToDate
    case fastForwarded
    case mergeCommitted
}

struct MergeResult: Codable, Sendable, Equatable {
    let kind: MergeResultKind
    let sourceBranch: String
    let newCommitSHA: String
}

struct MergeFinalizeResult: Codable, Sendable, Equatable {
    let newCommitSHA: String
}
