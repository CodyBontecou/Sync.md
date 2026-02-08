import Foundation

/// Configuration and state for a single managed repository
struct RepoConfig: Codable, Identifiable {
    let id: UUID
    var repoURL: String
    var branch: String
    var authorName: String
    var authorEmail: String
    var vaultFolderName: String
    var customVaultBookmarkData: Data?
    var gitState: GitState

    init(
        id: UUID = UUID(),
        repoURL: String,
        branch: String,
        authorName: String,
        authorEmail: String,
        vaultFolderName: String,
        customVaultBookmarkData: Data? = nil,
        gitState: GitState = .empty
    ) {
        self.id = id
        self.repoURL = repoURL
        self.branch = branch
        self.authorName = authorName
        self.authorEmail = authorEmail
        self.vaultFolderName = vaultFolderName
        self.customVaultBookmarkData = customVaultBookmarkData
        self.gitState = gitState
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
