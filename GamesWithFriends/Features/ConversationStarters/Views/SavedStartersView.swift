import SwiftUI

struct SavedStartersView: View {
    var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.savedStarters.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(viewModel.savedStarters) { starter in
                            SavedStarterRow(
                                starter: starter,
                                onRemove: {
                                    viewModel.toggleStar(starter)
                                },
                                onShare: {
                                    shareStarter(starter)
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Saved Starters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Saved Starters")
                .font(AppTheme.Typography.sectionHeader)

            Text("Tap the star icon on any conversation starter to save it here")
                .font(AppTheme.Typography.secondary)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private func shareStarter(_ starter: ConversationStarter) {
        let text = starter.text
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(
                x: rootVC.view.bounds.midX,
                y: rootVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct SavedStarterRow: View {
    let starter: ConversationStarter
    let onRemove: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: starter.category.icon)
                        .font(AppTheme.Typography.caption)
                    Text(starter.category.rawValue)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(categoryColor.opacity(0.2))
                .foregroundColor(categoryColor)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))

                Spacer()

                HStack(spacing: 5) {
                    ForEach(1...5, id: \.self) { level in
                        Circle()
                            .fill(level <= starter.vibeLevel ? vibeColor : AppTheme.mediumGray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }

            Text(starter.text)
                .font(AppTheme.Typography.body)
                .foregroundColor(.primary)

            HStack {
                Button(action: onShare) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(AppTheme.Typography.caption)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(action: onRemove) {
                    Label("Remove", systemImage: "trash")
                        .font(AppTheme.Typography.caption)
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.error)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    private var categoryColor: Color {
        // Mirrors CardView.categoryColor in GameView.swift — keep in sync.
        switch starter.category {
        case .wouldYouRather: return GameTheme.conversationStarters.accentColor
        case .hotTakes: return AppTheme.error
        case .hypotheticals: return AppTheme.warning
        case .storyTime: return GameTheme.conversationStarters.accentColor
        case .thisOrThat: return AppTheme.success
        case .deepDive: return GameTheme.conversationStarters.accentColor
        }
    }

    private var vibeColor: Color {
        switch starter.vibeLevel {
        case 1: return GameTheme.conversationStarters.accentColor
        case 2: return AppTheme.success
        case 3: return AppTheme.medalGold
        case 4: return AppTheme.warning
        case 5: return AppTheme.error
        default: return GameTheme.conversationStarters.accentColor
        }
    }
}
