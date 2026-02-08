import SwiftUI
import UniformTypeIdentifiers

struct AddRepoView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    // Repo selection
    @State private var selectedRepoURL: String = ""
    @State private var selectedBranch: String = "main"
    @State private var showRepoPicker = false
    @State private var showManualEntry = false

    // Author
    @State private var authorName: String = ""
    @State private var authorEmail: String = ""

    // Vault location
    @State private var vaultName: String = "vault"
    @State private var showFolderPicker = false
    @State private var customVaultURL: URL? = nil
    @State private var customVaultBookmarkData: Data? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Repo selection
                        repoSelectionSection
                            .staggeredAppear(index: 0)

                        if !selectedRepoURL.isEmpty {
                            // Branch & Author
                            configSection
                                .staggeredAppear(index: 1)

                            // Clone location
                            cloneLocationSection
                                .staggeredAppear(index: 2)

                            // Add button
                            addButton
                                .staggeredAppear(index: 3)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Add Repository")
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
            }
            .sheet(isPresented: $showRepoPicker) {
                RepoPickerView(repos: state.gitHubRepos) { repo in
                    selectedRepoURL = repo.htmlURL
                    selectedBranch = repo.defaultBranch
                    vaultName = repo.name
                }
            }
            .fileImporter(
                isPresented: $showFolderPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    handleFolderSelection(url)
                }
            }
            .onAppear {
                authorName = state.defaultAuthorName
                authorEmail = state.defaultAuthorEmail

                // Pre-fetch repos if needed
                if state.gitHubRepos.isEmpty {
                    Task { await state.refreshRepos() }
                }
            }
        }
    }

    // MARK: - Repo Selection

    private var repoSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Repository", systemImage: "book.closed.fill")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 24)

            VStack(spacing: 10) {
                // Pick from GitHub
                Button {
                    showRepoPicker = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(hex: 0x3478F6, alpha: 0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "list.bullet")
                                .font(.system(size: 18))
                                .foregroundStyle(SyncTheme.accent)
                        }

                        if selectedRepoURL.isEmpty || showManualEntry {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pick from GitHub")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(.primary)
                                Text("Select from your repositories")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        } else if let parsed = GitHubService.parseRepoURL(selectedRepoURL) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(parsed.owner)/\(parsed.repo)")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                                Text("Tap to change")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        if state.isLoadingRepos {
                            ProgressView().controlSize(.small)
                        } else if !selectedRepoURL.isEmpty && !showManualEntry {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color(hex: 0x34C759))
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .tint(.primary)

                // Divider
                HStack(spacing: 12) {
                    Capsule().fill(.quaternary).frame(height: 1)
                    Text("or")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                    Capsule().fill(.quaternary).frame(height: 1)
                }

                // Manual URL entry
                if showManualEntry {
                    VStack(spacing: 12) {
                        LiquidTextField(
                            icon: "link",
                            label: "Repository URL",
                            placeholder: "https://github.com/user/repo",
                            text: $selectedRepoURL,
                            disableAutocorrect: true
                        )

                        if !selectedRepoURL.isEmpty && GitHubService.parseRepoURL(selectedRepoURL) == nil {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                Text("Invalid GitHub URL")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .foregroundStyle(.red)
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .onChange(of: selectedRepoURL) { _, newValue in
                        if let parsed = GitHubService.parseRepoURL(newValue) {
                            vaultName = parsed.repo
                        }
                    }
                } else {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            showManualEntry = true
                            selectedRepoURL = ""
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "link")
                                .font(.system(size: 14))
                            Text("Enter URL manually")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(SyncTheme.accent)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Config Section

    private var configSection: some View {
        VStack(spacing: 14) {
            LiquidTextField(
                icon: "arrow.triangle.branch",
                label: "Branch",
                placeholder: "main",
                text: $selectedBranch,
                disableAutocorrect: true
            )

            LiquidTextField(
                icon: "person.fill",
                label: "Author Name",
                placeholder: "Your Name",
                text: $authorName
            )

            LiquidTextField(
                icon: "envelope.fill",
                label: "Author Email",
                placeholder: "you@example.com",
                text: $authorEmail,
                disableAutocorrect: true
            )
        }
    }

    // MARK: - Clone Location

    private var cloneLocationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Clone To", systemImage: "externaldrive.fill")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            if let customURL = customVaultURL {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: 0x007AFF, alpha: 0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "folder.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(SyncTheme.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(customURL.lastPathComponent)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                        Text(customURL.path)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Button {
                        customVaultURL = nil
                        customVaultBookmarkData = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                        TextField("Folder name", text: $vaultName)
                            .font(.system(size: 16, design: .rounded))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    HStack(spacing: 5) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 11))
                        Text("Files › On My iPhone › Sync.md › \(vaultName)")
                            .font(.system(size: 12, design: .rounded))
                    }
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
                }
            }

            Button {
                showFolderPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 13))
                    Text(customVaultURL != nil ? "Change Location…" : "Choose Different Location…")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundStyle(SyncTheme.accent)
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            addAndClone()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.down.fill")
                Text("Add & Clone Repository")
            }
        }
        .buttonStyle(LiquidButtonStyle(gradient: SyncTheme.primaryGradient))
        .disabled(!isValid || state.isSyncing)
        .opacity(!isValid || state.isSyncing ? 0.6 : 1)
        .padding(.horizontal, 24)
    }

    // MARK: - Validation

    private var isValid: Bool {
        GitHubService.parseRepoURL(selectedRepoURL) != nil
            && !authorName.trimmingCharacters(in: .whitespaces).isEmpty
            && !authorEmail.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    private func addAndClone() {
        let config = RepoConfig(
            repoURL: selectedRepoURL,
            branch: selectedBranch.isEmpty ? "main" : selectedBranch,
            authorName: authorName,
            authorEmail: authorEmail,
            vaultFolderName: vaultName.isEmpty ? "vault" : vaultName,
            customVaultBookmarkData: customVaultBookmarkData
        )
        state.addRepo(config)
        Task { await state.clone(repoID: config.id) }
        dismiss()
    }

    private func handleFolderSelection(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }

        guard let bookmark = try? url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else {
            url.stopAccessingSecurityScopedResource()
            return
        }

        url.stopAccessingSecurityScopedResource()
        customVaultBookmarkData = bookmark
        customVaultURL = url
    }
}
