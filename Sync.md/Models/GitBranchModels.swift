import Foundation

enum GitBranchScope: String, Codable, Sendable {
    case local
    case remote
}

struct GitBranchInfo: Identifiable, Codable, Sendable, Equatable {
    let name: String
    let shortName: String
    let scope: GitBranchScope
    let isCurrent: Bool
    let upstreamShortName: String?
    let aheadBy: Int?
    let behindBy: Int?

    var id: String { "\(scope.rawValue):\(name)" }
}

struct BranchInventory: Codable, Sendable, Equatable {
    let local: [GitBranchInfo]
    let remote: [GitBranchInfo]
    let detachedHeadOID: String?

    static let empty = BranchInventory(local: [], remote: [], detachedHeadOID: nil)
}
