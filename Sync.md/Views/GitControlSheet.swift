import SwiftUI

struct GitControlSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    let repoID: UUID

    @State private var commitMessage = ""
    @State private var selectedDiffPath: String? = nil
    @State private var showDiffSheet = false
    @State private var isLoadingDiff = false
    @State private var newBranchName = ""
    @State private var mergeCommitMessage = ""
    @State private var stashMessage = ""
    @State private var newTagName = ""
    @State private var newTagMessage = ""

    private var repo: RepoConfig? { state.repo(id: repoID) }
    private var changeCount: Int { state.changeCounts[repoID] ?? 0 }
    private var statusEntries: [GitStatusEntry] { state.statusEntriesByRepo[repoID] ?? [] }
    private var stagedCount: Int { statusEntries.filter { $0.indexStatus != nil }.count }
    private var isThisRepoSyncing: Bool { state.isSyncing && state.syncingRepoID == repoID }
    private var sortedEntries: [GitStatusEntry] { statusEntries.sorted { $0.path.localizedCaseInsensitiveCompare($1.path) == .orderedAscending } }
    private var branchInventory: BranchInventory { state.branchesByRepo[repoID] ?? .empty }
    private var localBranches: [GitBranchInfo] { branchInventory.local }
    private var currentBranchShortName: String { localBranches.first(where: \.isCurrent)?.shortName ?? (repo?.gitState.branch ?? "-") }
    private var conflictSession: ConflictSession { state.conflictSessionByRepo[repoID] ?? .none }
    private var hasConflictSession: Bool { conflictSession.isActive }
    private var stashes: [GitStashEntry] { state.stashesByRepo[repoID] ?? [] }
    private var tags: [GitTag] { state.tagsByRepo[repoID] ?? [] }

    private var selectedDiffText: String {
        guard let selectedDiffPath,
              let result = state.diffByRepo[repoID] else {
            return ""
        }

        if let file = result.files.first(where: {
            $0.path == selectedDiffPath || $0.newPath == selectedDiffPath || $0.oldPath == selectedDiffPath
        }) {
            return file.patch.isEmpty ? result.rawPatch : file.patch
        }

        return result.rawPatch
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Status Card
                        statusCard
                            .staggeredAppear(index: 0)

                        // Branches Card
                        branchesCard
                            .staggeredAppear(index: 1)

                        if hasConflictSession {
                            conflictCenterCard
                                .staggeredAppear(index: 2)
                        }

                        // Changes Card
                        changesCard
                            .staggeredAppear(index: 3)

                        // Stash Card
                        stashCard
                            .staggeredAppear(index: 4)

                        // Tag Card
                        tagCard
                            .staggeredAppear(index: 5)

                        // Pull Action
                        pullCard
                            .staggeredAppear(index: 6)

                        // Push Action
                        pushCard
                            .staggeredAppear(index: 7)

                        // Progress
                        if isThisRepoSyncing {
                            progressCard
                                .transition(.scale(scale: 0.95).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Git")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                }
            }
            .sheet(isPresented: $showDiffSheet) {
                NavigationStack {
                    Group {
                        if isLoadingDiff {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Loading diff…")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        } else if selectedDiffText.isEmpty {
                            ContentUnavailableView(
                                "No Diff Available",
                                systemImage: "doc.text"
                            )
                        } else {
                            ScrollView {
                                Text(selectedDiffText)
                                    .font(.system(size: 12, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .navigationTitle(selectedDiffPath ?? "Diff")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showDiffSheet = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .task {
                await state.loadBranches(repoID: repoID)
                await state.loadConflictSession(repoID: repoID)
                await state.loadStashes(repoID: repoID)
                await state.loadTags(repoID: repoID)
            }
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(SyncTheme.primaryGradient)
                Text("Repository Status")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Spacer()
            }

            Divider().opacity(0.5)

            VStack(spacing: 12) {
                if let repo = repo {
                    statusRow(icon: "arrow.triangle.branch", label: "Branch", value: repo.gitState.branch, monospaced: true)
                    statusRow(icon: "clock.fill", label: "Last Sync", value: lastSyncText)
                    statusRow(icon: "number", label: "Commit", value: String(repo.gitState.commitSHA.prefix(7)), monospaced: true)
                }

                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text("Local Changes")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if changeCount > 0 {
                        Text("\(changeCount)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(SyncTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(SyncTheme.accent.opacity(0.12), in: Capsule())
                    } else {
                        Text("None")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .glassCard(cornerRadius: 20, padding: 16)
    }

    private var lastSyncText: String {
        guard let repo = repo else { return String(localized: "Never") }
        if repo.gitState.lastSyncDate == .distantPast {
            return String(localized: "Never")
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: repo.gitState.lastSyncDate, relativeTo: Date())
    }

    private func statusRow(icon: String, label: String, value: String, monospaced: Bool = false) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(value)
                .font(monospaced
                    ? .system(size: 14, weight: .medium, design: .monospaced)
                    : .system(size: 14, weight: .medium, design: .rounded)
                )
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Branches Card

    private var branchesCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Branches")
                    .font(.system(size: 17, weight: .bold, design: .rounded))

                Spacer()

                Text(currentBranchShortName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SyncTheme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(SyncTheme.accent.opacity(0.12), in: Capsule())
            }

            HStack(spacing: 8) {
                TextField("new-branch", text: $newBranchName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button("Create") {
                    let name = newBranchName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    Task {
                        await state.createBranch(repoID: repoID, name: name)
                        newBranchName = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(SyncTheme.accent)
                .disabled(newBranchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || state.isSyncing)
            }

            if localBranches.isEmpty {
                Text("No branches available")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(localBranches.enumerated()), id: \.element.id) { index, branch in
                        branchRow(branch)
                        if index < localBranches.count - 1 {
                            Divider().opacity(0.35)
                        }
                    }
                }
            }

            if let detached = branchInventory.detachedHeadOID {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Detached HEAD: \(String(detached.prefix(7)))")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .glassCard(cornerRadius: 20, padding: 16)
    }

    private func branchRow(_ branch: GitBranchInfo) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(branch.shortName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                if let upstream = branch.upstreamShortName {
                    Text(upstream)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if branch.isCurrent {
                Text("Current")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12), in: Capsule())
            } else {
                Button("Switch") {
                    Task { await state.switchBranch(repoID: repoID, name: branch.shortName) }
                }
                .buttonStyle(.bordered)
                .disabled(state.isSyncing)

                Button("Merge") {
                    Task { await state.mergeBranch(repoID: repoID, from: branch.shortName) }
                }
                .buttonStyle(.bordered)
                .disabled(state.isSyncing)

                Button(role: .destructive) {
                    Task { await state.deleteBranch(repoID: repoID, name: branch.shortName) }
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(state.isSyncing)
            }
        }
    }

    // MARK: - Conflict Center Card

    private var conflictCenterCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Conflict Center")
                    .font(.system(size: 17, weight: .bold, design: .rounded))

                Spacer()

                Text(conflictSession.kind.rawValue.capitalized)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.14), in: Capsule())
            }

            if conflictSession.unmergedPaths.isEmpty {
                Text("All conflict files are resolved. You can complete or abort the merge.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(conflictSession.unmergedPaths.enumerated()), id: \.element) { index, path in
                        conflictRow(path: path)
                        if index < conflictSession.unmergedPaths.count - 1 {
                            Divider().opacity(0.35)
                        }
                    }
                }
            }

            if conflictSession.kind == .merge {
                HStack(spacing: 8) {
                    TextField("Merge commit message", text: $mergeCommitMessage)
                        .font(.system(size: 14, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .disabled(state.isSyncing)

                    Button("Complete") {
                        Task {
                            await state.completeMerge(repoID: repoID, message: mergeCommitMessage)
                            mergeCommitMessage = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(!conflictSession.unmergedPaths.isEmpty || state.isSyncing)
                }

                Button(role: .destructive) {
                    Task { await state.abortMerge(repoID: repoID) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                        Text("Abort Merge")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(state.isSyncing)
            } else {
                Text("Resolution actions currently support merge sessions.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .glassCard(cornerRadius: 20, padding: 16)
    }

    private func conflictRow(path: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(path)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .truncationMode(.middle)

            Text("Choose ours/theirs, or edit file externally then tap Manual")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button("Ours") {
                    Task { await state.resolveConflictFile(repoID: repoID, path: path, strategy: .ours) }
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .disabled(state.isSyncing)

                Button("Theirs") {
                    Task { await state.resolveConflictFile(repoID: repoID, path: path, strategy: .theirs) }
                }
                .buttonStyle(.bordered)
                .tint(.purple)
                .disabled(state.isSyncing)

                Button("Manual") {
                    Task { await state.resolveConflictFile(repoID: repoID, path: path, strategy: .manual) }
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .disabled(state.isSyncing)

                Button {
                    openDiff(for: path)
                } label: {
                    Image(systemName: "doc.plaintext")
                }
                .buttonStyle(.bordered)
                .disabled(state.isSyncing)
            }
        }
    }

    // MARK: - Changes Card

    private var changesCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Changes")
                    .font(.system(size: 17, weight: .bold, design: .rounded))

                Spacer()

                if stagedCount > 0 {
                    Text("\(stagedCount) staged")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12), in: Capsule())
                }
            }

            if sortedEntries.isEmpty {
                Text("No local changes")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                        changeRow(entry)

                        if index < sortedEntries.count - 1 {
                            Divider().opacity(0.4)
                        }
                    }
                }
            }
        }
        .glassCard(cornerRadius: 20, padding: 16)
    }

    private func changeRow(_ entry: GitStatusEntry) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.path)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(changeSummary(for: entry))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button {
                Task {
                    if entry.indexStatus != nil {
                        await state.unstageFile(repoID: repoID, path: entry.path)
                    } else {
                        await state.stageFile(repoID: repoID, path: entry.path)
                    }
                }
            } label: {
                Text(entry.indexStatus != nil ? "Unstage" : "Stage")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .buttonStyle(.bordered)
            .tint(entry.indexStatus != nil ? .orange : .green)
            .disabled(state.isSyncing)

            Button {
                openDiff(for: entry.path)
            } label: {
                Image(systemName: "doc.plaintext")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .tint(SyncTheme.blue)
            .disabled(state.isSyncing)
        }
    }

    private func changeSummary(for entry: GitStatusEntry) -> String {
        switch (entry.indexStatus, entry.workTreeStatus) {
        case let (index?, workTree?):
            return "Staged \(statusLabel(index)) · Unstaged \(statusLabel(workTree))"
        case let (index?, nil):
            return "Staged \(statusLabel(index))"
        case let (nil, workTree?):
            return statusLabel(workTree).capitalized
        case (nil, nil):
            return "No status"
        }
    }

    private func statusLabel(_ kind: GitFileStatusKind) -> String {
        switch kind {
        case .added: return "added"
        case .modified: return "modified"
        case .deleted: return "deleted"
        case .renamed: return "renamed"
        case .typeChanged: return "type changed"
        case .untracked: return "untracked"
        case .conflicted: return "conflicted"
        }
    }

    // MARK: - Tag Card

    private var tagCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SyncTheme.primaryGradient)
                Text("Tags")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Spacer()
                if !tags.isEmpty {
                    Text("\(tags.count)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(SyncTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SyncTheme.accent.opacity(0.12), in: Capsule())
                }
            }

            Divider().opacity(0.5)

            // Create tag inputs
            VStack(spacing: 8) {
                TextField("Tag name (e.g. v1.0.0)", text: $newTagName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                HStack(spacing: 8) {
                    TextField("Annotation message (optional)", text: $newTagMessage)
                        .textInputAutocapitalization(.sentences)
                        .font(.system(size: 14, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Button("Create") {
                        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        let msg = newTagMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                        Task {
                            await state.createTag(
                                repoID: repoID,
                                name: name,
                                message: msg.isEmpty ? nil : msg
                            )
                            newTagName = ""
                            newTagMessage = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SyncTheme.accent)
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || state.isSyncing)
                }
            }

            if tags.isEmpty {
                Text("No tags in this repository")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(tags.enumerated()), id: \.element.id) { index, tag in
                        tagRow(tag: tag)
                        if index < tags.count - 1 {
                            Divider().opacity(0.35)
                        }
                    }
                }
            }
        }
        .glassCard(cornerRadius: 20, padding: 16)
    }

    private func tagRow(tag: GitTag) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(tag.shortName)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    Text(tag.kind == .annotated ? "annotated" : "lightweight")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(tag.kind == .annotated ? SyncTheme.accent : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            (tag.kind == .annotated ? SyncTheme.accent : Color.secondary).opacity(0.12),
                            in: Capsule()
                        )
                }
                if let message = tag.message, !message.isEmpty {
                    Text(message)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(String(tag.targetOID.prefix(7)))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 8)

            Button("Push") {
                Task { await state.pushTag(repoID: repoID, name: tag.shortName) }
            }
            .buttonStyle(.bordered)
            .tint(SyncTheme.blue)
            .disabled(state.isSyncing)

            Button(role: .destructive) {
                Task { await state.deleteTag(repoID: repoID, name: tag.shortName) }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(state.isSyncing)
        }
    }

    // MARK: - Stash Card

    private var stashCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "tray.and.arrow.down.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SyncTheme.primaryGradient)
                Text("Stash")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Spacer()
                if !stashes.isEmpty {
                    Text("\(stashes.count)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(SyncTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SyncTheme.accent.opacity(0.12), in: Capsule())
                }
            }

            Divider().opacity(0.5)

            // Save stash row
            HStack(spacing: 8) {
                TextField("Stash message (optional)…", text: $stashMessage)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .font(.system(size: 14, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Button("Save") {
                    let msg = stashMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    Task {
                        await state.saveStash(repoID: repoID, message: msg, includeUntracked: true)
                        stashMessage = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(SyncTheme.accent)
                .disabled(changeCount == 0 || state.isSyncing)
            }

            if changeCount == 0 && stashes.isEmpty {
                Text("No local changes to stash")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Stash list
            if !stashes.isEmpty {
                VStack(spacing: 10) {
                    ForEach(Array(stashes.enumerated()), id: \.element.id) { index, entry in
                        stashRow(entry: entry)
                        if index < stashes.count - 1 {
                            Divider().opacity(0.35)
                        }
                    }
                }
            }
        }
        .glassCard(cornerRadius: 20, padding: 16)
    }

    private func stashRow(entry: GitStashEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("stash@{\(entry.index)}")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(entry.message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button("Apply") {
                    Task { await state.applyStash(repoID: repoID, index: entry.index) }
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .disabled(state.isSyncing)

                Button("Pop") {
                    Task { await state.popStash(repoID: repoID, index: entry.index) }
                }
                .buttonStyle(.bordered)
                .tint(SyncTheme.accent)
                .disabled(state.isSyncing)

                Spacer()

                Button(role: .destructive) {
                    Task { await state.dropStash(repoID: repoID, index: entry.index) }
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(state.isSyncing)
            }
        }
    }

    private func openDiff(for path: String) {
        selectedDiffPath = path
        showDiffSheet = true
        isLoadingDiff = true

        Task {
            await state.loadUnifiedDiff(repoID: repoID, path: path)
            isLoadingDiff = false
        }
    }

    // MARK: - Pull Card

    private var pullCard: some View {
        Button {
            Task {
                await state.pull(repoID: repoID)
                dismiss()
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [SyncTheme.blue.opacity(0.15), SyncTheme.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(SyncTheme.pullGradient)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pull")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Fetch and apply remote changes")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .glassCard(cornerRadius: 18, padding: 14)
        }
        .tint(.primary)
        .disabled(state.isSyncing)
        .opacity(state.isSyncing ? 0.5 : 1)
    }

    // MARK: - Push Card

    private var pushCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [SyncTheme.accent.opacity(0.15), SyncTheme.accent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(SyncTheme.pushGradient)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Commit & Push")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Text("Commit staged changes and push to remote")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Commit message input
            HStack(spacing: 0) {
                TextField("Commit message…", text: $commitMessage, axis: .vertical)
                    .font(.system(size: 15, design: .rounded))
                    .lineLimit(1...4)
                    .padding(14)
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(stagedCount == 1 ? "1 file staged" : "\(stagedCount) files staged")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Push button
            Button {
                Task {
                    await state.push(repoID: repoID, message: commitMessage)
                    commitMessage = ""
                    dismiss()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                    if stagedCount == 1 {
                        Text("Push 1 staged file")
                    } else {
                        Text("Push \(stagedCount) staged files")
                    }
                }
            }
            .buttonStyle(LiquidButtonStyle(gradient: SyncTheme.pushGradient))
            .disabled(stagedCount == 0 || state.isSyncing)
            .opacity(stagedCount == 0 || state.isSyncing ? 0.5 : 1)
        }
        .glassCard(cornerRadius: 20, padding: 16)
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        HStack(spacing: 14) {
            ProgressView()
                .controlSize(.regular)
                .tint(SyncTheme.accent)

            Text(state.syncProgress)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .glassCard(cornerRadius: 16, padding: 16)
    }
}
