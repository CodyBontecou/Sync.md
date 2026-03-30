import Foundation

enum GitTagKind: String, Codable, Sendable, Equatable {
    case lightweight
    case annotated
}

struct GitTag: Identifiable, Codable, Sendable, Equatable {
    let name: String
    let oid: String
    let kind: GitTagKind
    /// For annotated tags only.
    let message: String?
    /// SHA of the commit (or object) the tag points at.
    let targetOID: String

    var id: String { name }
    /// Short name without the refs/tags/ prefix.
    var shortName: String {
        if name.hasPrefix("refs/tags/") {
            return String(name.dropFirst("refs/tags/".count))
        }
        return name
    }
}
