import Foundation

/// Configuration and state for a single managed repository
struct RepoConfig: Codable, Identifiable, Equatable {
    let id: UUID
    var repoURL: String
    var branch: String
    var authorName: String
    var authorEmail: String
    var vaultFolderName: String
    var customVaultBookmarkData: Data?
    /// When `true`, the custom vault bookmark points to a parent directory
    /// and `vaultFolderName` should be appended to form the actual repo path.
    /// This mirrors `git clone` behaviour: clone into `<parent>/<repoName>/`.
    var customLocationIsParent: Bool
    var gitState: GitState

    init(
        id: UUID = UUID(),
        repoURL: String,
        branch: String,
        authorName: String,
        authorEmail: String,
        vaultFolderName: String,
        customVaultBookmarkData: Data? = nil,
        customLocationIsParent: Bool = false,
        gitState: GitState = .empty
    ) {
        self.id = id
        self.repoURL = repoURL
        self.branch = branch
        self.authorName = authorName
        self.authorEmail = authorEmail
        self.vaultFolderName = vaultFolderName
        self.customVaultBookmarkData = customVaultBookmarkData
        self.customLocationIsParent = customLocationIsParent
        self.gitState = gitState
    }

    // MARK: - Codable (backward-compatible)

    private enum CodingKeys: String, CodingKey {
        case id, repoURL, branch, authorName, authorEmail
        case vaultFolderName, customVaultBookmarkData
        case customLocationIsParent, gitState
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                      = try c.decode(UUID.self, forKey: .id)
        repoURL                 = try c.decode(String.self, forKey: .repoURL)
        branch                  = try c.decode(String.self, forKey: .branch)
        authorName              = try c.decode(String.self, forKey: .authorName)
        authorEmail             = try c.decode(String.self, forKey: .authorEmail)
        vaultFolderName         = try c.decode(String.self, forKey: .vaultFolderName)
        customVaultBookmarkData = try c.decodeIfPresent(Data.self, forKey: .customVaultBookmarkData)
        customLocationIsParent  = try c.decodeIfPresent(Bool.self, forKey: .customLocationIsParent) ?? false
        gitState                = try c.decode(GitState.self, forKey: .gitState)
    }

    // MARK: - Computed

    var displayName: String {
        GitHubService.parseRepoURL(repoURL)?.repo ?? vaultFolderName
    }

    var ownerName: String? {
        GitHubService.parseRepoURL(repoURL)?.owner
    }

    var isCloned: Bool {
        !gitState.commitSHA.isEmpty
    }

    var defaultVaultURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(vaultFolderName, isDirectory: true)
    }
}
