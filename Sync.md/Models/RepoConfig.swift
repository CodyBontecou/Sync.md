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
    var gitState: GitState
    var autoSyncEnabled: Bool
    var autoSyncInterval: TimeInterval  // seconds between sync cycles

    init(
        id: UUID = UUID(),
        repoURL: String,
        branch: String,
        authorName: String,
        authorEmail: String,
        vaultFolderName: String,
        customVaultBookmarkData: Data? = nil,
        gitState: GitState = .empty,
        autoSyncEnabled: Bool = false,
        autoSyncInterval: TimeInterval = 300  // default 5 minutes
    ) {
        self.id = id
        self.repoURL = repoURL
        self.branch = branch
        self.authorName = authorName
        self.authorEmail = authorEmail
        self.vaultFolderName = vaultFolderName
        self.customVaultBookmarkData = customVaultBookmarkData
        self.gitState = gitState
        self.autoSyncEnabled = autoSyncEnabled
        self.autoSyncInterval = autoSyncInterval
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
