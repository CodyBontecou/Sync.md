import SwiftUI

struct RepoPickerView: View {
    let repos: [GitHubRepo]
    let onSelect: (GitHubRepo) -> Void

    @State private var searchText = ""
    @State private var appeared = false
    @Environment(\.dismiss) private var dismiss

    var filtered: [GitHubRepo] {
        if searchText.isEmpty { return repos }
        let q = searchText.lowercased()
        return repos.filter {
            $0.name.lowercased().contains(q)
            || $0.fullName.lowercased().contains(q)
            || ($0.description?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, repo in
                            Button {
                                onSelect(repo)
                                dismiss()
                            } label: {
                                repoRow(repo)
                            }
                            .tint(.primary)
                            .staggeredAppear(index: index)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
                .overlay {
                    if filtered.isEmpty && !searchText.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Filter repositories")
            .navigationTitle("Select Repository")
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
        }
    }

    // MARK: - Repo Row

    private func repoRow(_ repo: GitHubRepo) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Visibility icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(repo.isPrivate
                        ? SyncTheme.accent.opacity(0.12)
                        : Color(.systemGray).opacity(0.1)
                    )
                    .frame(width: 38, height: 38)

                Image(systemName: repo.isPrivate ? "lock.fill" : "globe")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(repo.isPrivate ? SyncTheme.accent : .secondary)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(repo.fullName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .lineLimit(1)

                if let desc = repo.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 14) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 10, weight: .semibold))
                        Text(repo.defaultBranch)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }

                    if let updated = repo.relativeDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10, weight: .semibold))
                            Text(updated)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                    }
                }
                .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 12)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Date helper

extension GitHubRepo {
    var relativeDate: String? {
        guard let updatedAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: updatedAt) {
            let relative = RelativeDateTimeFormatter()
            relative.unitsStyle = .abbreviated
            return relative.localizedString(for: date, relativeTo: Date())
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: updatedAt) {
            let relative = RelativeDateTimeFormatter()
            relative.unitsStyle = .abbreviated
            return relative.localizedString(for: date, relativeTo: Date())
        }
        return nil
    }
}
