import Foundation

struct GitStashEntry: Identifiable, Codable, Sendable, Equatable {
    let index: Int
    let oid: String
    let message: String

    var id: String { "\(index)-\(oid)" }
}

enum StashApplyResultKind: String, Codable, Sendable {
    case applied
    case conflicts
}

struct StashApplyResult: Codable, Sendable, Equatable {
    let kind: StashApplyResultKind
    let index: Int
}
