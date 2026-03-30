import Foundation

enum RevertResultKind: String, Codable, Sendable {
    case reverted
    case conflicts
}

struct RevertResult: Codable, Sendable, Equatable {
    let kind: RevertResultKind
    let targetOID: String
    let newCommitSHA: String?
}
