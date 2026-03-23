import SwiftUI

struct SavedStartersView: View {
    var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
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
                .foregroundColor(.gray)

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
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height / 2,
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
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
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
                .tint(.red)
            }
        }
        .padding(.vertical, 5)
    }

    private var categoryColor: Color {
        switch starter.category {
        case .wouldYouRather: return GameTheme.conversationStarters.accentColor
        case .hotTakes: return .red
        case .hypotheticals: return .orange
        case .storyTime: return GameTheme.conversationStarters.accentColor
        case .thisOrThat: return .green
        case .deepDive: return .indigo
        }
    }

    private var vibeColor: Color {
        switch starter.vibeLevel {
        case 1: return GameTheme.conversationStarters.accentColor
        case 2: return .green
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return GameTheme.conversationStarters.accentColor
        }
    }
}
