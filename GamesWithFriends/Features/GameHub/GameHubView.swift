import SwiftUI

// Phase-2 migrated screen (ART_DIRECTION §10.2): motif ground, Shrikhand
// lockup, candy shelf cards. The Option C artboard is the spec; deviations
// are logged in DECISIONS.md (tagline omitted, descriptions panelled).
struct GameHubView: View {
    let games = GameRegistry.allGames()

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geo in
                    // Motifs live in the gutters and top corners. Exclusions
                    // cover the header lockup and the card column; the layout
                    // generator adds its own 12pt clearance (§7), which keeps
                    // even 18pt sparkles from poking out behind card corners.
                    MotifGroundView(exclusions: [
                        CGRect(x: 60, y: 40, width: geo.size.width - 120, height: 160),
                        CGRect(x: 28, y: 150,
                               width: geo.size.width - 56,
                               height: geo.size.height - 150)
                    ])
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        RetroHubHeader()
                            .padding(.top, AppTheme.Spacing.lg)
                            .padding(.bottom, AppTheme.Spacing.lg)

                        // 20pt gap from the artboard; 28pt gutters give edge
                        // motifs room to breathe clear of the cards.
                        VStack(spacing: 20) {
                            ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                                NavigationLink(destination: game.makeRootView()) {
                                    RetroHubGameCard(game: game)
                                }
                                .buttonStyle(RetroRaisedButtonStyle())
                                .rotationEffect(.degrees(index.isMultiple(of: 2) ? -0.6 : 0.6))
                                .accessibilityLabel("\(game.name). \(game.description)")
                                .accessibilityHint("Double tap to play")
                                .staggeredAppear(index: index)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, AppTheme.Spacing.xl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Header lockup (Rule 4: chunky framed lettering)

private struct RetroHubHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("GAMES")
                .font(AppTheme.Retro.Typography.logo)
                .foregroundColor(.white)
                .shadow(color: AppTheme.Retro.tomato, radius: 0, x: 3, y: 3)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroPanel(AppTheme.Retro.bubblegum)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                        .fill(AppTheme.Retro.ink)
                        .offset(x: AppTheme.Retro.shadowOffset,
                                y: AppTheme.Retro.shadowOffset)
                )
                .rotationEffect(.degrees(-1.5))

            // Tomato on cream ≈ 3.2:1 — passes as large text (20px heavy face).
            Text("with friends")
                .font(AppTheme.Retro.Typography.heading(15, relativeTo: .subheadline))
                .foregroundColor(AppTheme.Retro.tomato)
                .retroLozenge()
                .rotationEffect(.degrees(1))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Games with Friends")
    }
}

// MARK: - Candy shelf card (§5 card anatomy)

struct RetroHubGameCard: View {
    let game: AnyGameDefinition

    private var accent: Color {
        AppTheme.Retro.accent(forGameID: game.id) ?? AppTheme.Retro.tangerine
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                // Title lozenge — ink-on-cream, always safe (§8).
                Text(game.name)
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(AppTheme.Retro.panel))
                    .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))

                // Description mini-panel — §8: body copy never sits naked on
                // a saturated accent.
                Text(game.description)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                            .fill(AppTheme.Retro.panel)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                            .stroke(AppTheme.Retro.ink, lineWidth: 2)
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 66pt cream circle plate with the game's spot illustration.
            ZStack {
                Circle().fill(AppTheme.Retro.panel)
                Circle().stroke(AppTheme.Retro.ink,
                                lineWidth: AppTheme.Retro.strokeWidth)
                if let kind = RetroSpotKind(gameID: game.id) {
                    RetroSpotIllustration(kind: kind)
                        .frame(width: 52, height: 52)
                } else {
                    Image(systemName: game.iconName)
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundColor(accent)
                }
            }
            .frame(width: 66, height: 66)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .retroPanel(accent)
    }
}

#Preview {
    GameHubView()
        .modelContainer(for: FinishTheLineRoundResult.self, inMemory: true)
}
