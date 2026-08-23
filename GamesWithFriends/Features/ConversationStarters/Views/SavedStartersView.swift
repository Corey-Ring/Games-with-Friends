import SwiftUI

struct SavedStartersView: View {
    var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Retro.ground.ignoresSafeArea()

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
                            .retroCard()
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .tint(AppTheme.Retro.ink)
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
        VStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle().fill(AppTheme.Retro.panel)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                Image(systemName: "star.slash")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppTheme.Retro.ink.opacity(0.4))
            }
            .frame(width: 80, height: 80)

            Text("No Saved Starters")
                .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title2))
                .foregroundColor(AppTheme.Retro.ink)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroPanel(ConversationStartersStyle.accent)
                .rotationEffect(.degrees(-1))

            Text("Tap the star icon on any conversation starter to save it here")
                .font(AppTheme.Typography.secondary)
                .foregroundColor(AppTheme.Retro.panelText)
                .multilineTextAlignment(.center)
                .retroLozenge()
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
                        .font(AppTheme.Retro.Typography.pillLabel)
                }
                .foregroundColor(ConversationStartersStyle.chipTextColor(on: categoryColor))
                .padding(.horizontal, AppTheme.Spacing.sm + 2)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(Capsule().fill(categoryColor))
                .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))

                Spacer()

                HStack(spacing: 5) {
                    ForEach(1...5, id: \.self) { level in
                        Circle()
                            .fill(level <= starter.vibeLevel ? vibeColor : AppTheme.Retro.ink.opacity(0.15))
                            .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1))
                            .frame(width: 8, height: 8)
                    }
                }
            }

            Text(starter.text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Retro.panelText)

            HStack {
                Button(action: onShare) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(AppTheme.Retro.Typography.pillLabel)
                        .foregroundColor(AppTheme.Retro.ink)
                        .padding(.horizontal, AppTheme.Spacing.sm + 2)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(Capsule().fill(ConversationStartersStyle.accent))
                        .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))
                }

                Spacer()

                Button(action: onRemove) {
                    Label("Remove", systemImage: "trash")
                        .font(AppTheme.Retro.Typography.pillLabel)
                        .foregroundColor(AppTheme.Retro.ink)
                        .padding(.horizontal, AppTheme.Spacing.sm + 2)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(Capsule().fill(AppTheme.Retro.tomato))
                        .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))
                }
            }
        }
    }

    private var categoryColor: Color {
        ConversationStartersStyle.categoryColor(starter.category)
    }

    private var vibeColor: Color {
        ConversationStartersStyle.vibeColor(starter.vibeLevel)
    }
}
