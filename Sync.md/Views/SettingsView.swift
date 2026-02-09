import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    let repoID: UUID

    @State private var branch: String = ""
    @State private var authorName: String = ""
    @State private var authorEmail: String = ""
    @State private var vaultName: String = ""
    @State private var autoSyncEnabled: Bool = false
    @State private var autoSyncInterval: TimeInterval = 300
    @State private var showRemoveConfirm = false
    @State private var showFolderPicker = false

    private static let intervalOptions: [(String, TimeInterval)] = [
        ("1 minute", 60),
        ("5 minutes", 300),
        ("15 minutes", 900),
        ("30 minutes", 1800),
        ("1 hour", 3600),
    ]

    private var repo: RepoConfig? { state.repo(id: repoID) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Repository Section
                        settingsSection(title: "Repository", icon: "book.closed.fill", iconColor: SyncTheme.accent) {
                            VStack(spacing: 14) {
                                settingsRow(label: "URL") {
                                    Text(repo?.repoURL ?? "")
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }

                                Divider().opacity(0.3)

                                settingsRow(label: "Branch") {
                                    TextField("main", text: $branch)
                                        .font(.system(size: 15, design: .rounded))
                                        .multilineTextAlignment(.trailing)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                }
                            }
                        }
                        .staggeredAppear(index: 0)

                        // Git Author Section
                        settingsSection(title: "Git Author", icon: "person.fill", iconColor: SyncTheme.accent) {
                            VStack(spacing: 14) {
                                settingsRow(label: "Name") {
                                    TextField("Your Name", text: $authorName)
                                        .font(.system(size: 15, design: .rounded))
                                        .multilineTextAlignment(.trailing)
                                }

                                Divider().opacity(0.3)

                                settingsRow(label: "Email") {
                                    TextField("you@example.com", text: $authorEmail)
                                        .font(.system(size: 15, design: .rounded))
                                        .multilineTextAlignment(.trailing)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                }
                            }
                        }
                        .staggeredAppear(index: 1)

                        // Storage Section
                        settingsSection(title: "Storage", icon: "externaldrive.fill", iconColor: SyncTheme.accent) {
                            VStack(spacing: 14) {
                                if state.isUsingCustomLocation(for: repoID) {
                                    settingsRow(label: "Location") {
                                        Text(state.vaultURL(for: repoID).lastPathComponent)
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }

                                    Divider().opacity(0.3)

                                    settingsRow(label: "Path") {
                                        Text(state.vaultDisplayPath(for: repoID))
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                } else {
                                    settingsRow(label: "Folder") {
                                        Text(vaultName)
                                            .font(.system(size: 15, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }

                                    Divider().opacity(0.3)

                                    settingsRow(label: "Path") {
                                        Text("On My iPhone › Sync.md › \(vaultName)")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .staggeredAppear(index: 2)

                        // Auto-Sync Section
                        if let repo = repo, repo.isCloned {
                            settingsSection(title: "Auto-Sync", icon: "arrow.triangle.2.circlepath", iconColor: SyncTheme.accent) {
                                VStack(spacing: 14) {
                                    HStack {
                                        Text("Enabled")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Toggle("", isOn: $autoSyncEnabled)
                                            .labelsHidden()
                                            .tint(SyncTheme.accent)
                                    }

                                    if autoSyncEnabled {
                                        Divider().opacity(0.3)

                                        HStack {
                                            Text("Interval")
                                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Menu {
                                                ForEach(Self.intervalOptions, id: \.1) { label, value in
                                                    Button {
                                                        autoSyncInterval = value
                                                    } label: {
                                                        HStack {
                                                            Text(label)
                                                            if autoSyncInterval == value {
                                                                Image(systemName: "checkmark")
                                                            }
                                                        }
                                                    }
                                                }
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Text(intervalLabel(for: autoSyncInterval))
                                                        .font(.system(size: 15, design: .rounded))
                                                        .foregroundStyle(.primary)
                                                    Image(systemName: "chevron.up.chevron.down")
                                                        .font(.system(size: 10, weight: .semibold))
                                                        .foregroundStyle(.tertiary)
                                                }
                                            }
                                        }

                                        Divider().opacity(0.3)

                                        HStack(spacing: 8) {
                                            Image(systemName: "info.circle")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.tertiary)
                                            Text("Automatically pulls remote changes and pushes local edits on a timer.")
                                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }
                            }
                            .staggeredAppear(index: 3)
                        }

                        // Vault Info Section
                        if let repo = repo, repo.isCloned {
                            settingsSection(title: "Sync Info", icon: "info.circle.fill", iconColor: .secondary) {

                                VStack(spacing: 14) {
                                    settingsRow(label: "Last Sync") {
                                        if repo.gitState.lastSyncDate == .distantPast {
                                            Text("Never")
                                                .font(.system(size: 14, design: .rounded))
                                                .foregroundStyle(.tertiary)
                                        } else {
                                            Text(relativeDate(repo.gitState.lastSyncDate))
                                                .font(.system(size: 14, design: .rounded))
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Divider().opacity(0.3)

                                    settingsRow(label: "Commit SHA") {
                                        Text(String(repo.gitState.commitSHA.prefix(7)))
                                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }

                                    Divider().opacity(0.3)

                                    settingsRow(label: "Files") {
                                        Text("\(repo.gitState.blobSHAs.count)")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .staggeredAppear(index: 4)
                        }

                        // Actions
                        VStack(spacing: 12) {
                            Button {
                                showRemoveConfirm = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 15, weight: .medium))
                                    Text("Remove Repository")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 20)
                        .staggeredAppear(index: 5)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveChanges()
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                }
            }
            .onAppear {
                if let repo = repo {
                    branch = repo.branch
                    authorName = repo.authorName
                    authorEmail = repo.authorEmail
                    vaultName = repo.vaultFolderName
                    autoSyncEnabled = repo.autoSyncEnabled
                    autoSyncInterval = repo.autoSyncInterval
                }
            }
            .alert("Remove Repository?", isPresented: $showRemoveConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    state.removeRepo(id: repoID)
                    dismiss()
                }
            } message: {
                Text("This will delete all local files for this repository. This cannot be undone.")
            }
        }
    }

    // MARK: - Settings Section

    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.horizontal, 4)

            content()
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
    }

    private func settingsRow<Content: View>(label: String, @ViewBuilder value: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            value()
        }
    }

    // MARK: - Helpers

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Helpers (Auto-Sync)

    private func intervalLabel(for interval: TimeInterval) -> String {
        Self.intervalOptions.first { $0.1 == interval }?.0 ?? "\(Int(interval / 60)) min"
    }

    // MARK: - Save

    private func saveChanges() {
        state.updateRepo(id: repoID) { repo in
            repo.branch = branch
            repo.authorName = authorName
            repo.authorEmail = authorEmail
            repo.autoSyncEnabled = autoSyncEnabled
            repo.autoSyncInterval = autoSyncInterval
        }
    }
}
