import Foundation

struct GitCommitSummary: Identifiable, Codable, Sendable, Equatable {
    let oid: String
    let shortOID: String
    let message: String
    let authorName: String
    let authorEmail: String
    let authoredDate: Date

    var id: String { oid }
}

struct GitCommitFileChange: Codable, Sendable, Equatable {
    let path: String
    let oldPath: String?
    let newPath: String?
    let changeType: GitDiffChangeType
}

struct GitCommitDetail: Codable, Sendable, Equatable {
    let oid: String
    let message: String
    let authorName: String
    let authorEmail: String
    let authoredDate: Date
    let committerName: String
    let committerEmail: String
    let committedDate: Date
    let parentOIDs: [String]
    let changedFiles: [GitCommitFileChange]
}
