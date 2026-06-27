//
//  FinishTheLineGameView.swift
//  GamesWithFriends
//

import SwiftUI

struct FinishTheLineGameView: View {
    @Bindable var viewModel: FinishTheLineViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shakeCount: CGFloat = 0
    @State private var showNearMissPip = false
    @State private var showTimeBonusPip = false

    private let theme = GameTheme.finishTheLine

    var body: some View {
        ZStack {
            GameBackground(gameTheme: theme)

            VStack(spacing: AppTheme.Spacing.md) {
                topHUD
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.sm)

                quoteStage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, AppTheme.Spacing.md)

                bottomControls
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.md)
            }
        }
        .onChange(of: viewModel.nearMissCount) { _, _ in
            triggerNearMiss()
        }
        .onChange(of: viewModel.timeBonusCount) { _, _ in
            triggerTimeBonusPip()
        }
    }

    // MARK: - Top HUD

    private var topHUD: some View {
        HStack(alignment: .center) {
            Button {
                viewModel.quitRound()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.deepCharcoal)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(AppTheme.pureWhite.opacity(0.85))
                    )
                    .overlay(
                        Circle()
                            .stroke(theme.accentColor.opacity(0.25), lineWidth: 1)
                    )
            }
            .pressable()
            .accessibilityLabel("Quit round")

            Spacer()

            SpotlightTimerView(
                timeRemaining: viewModel.timeRemaining,
                totalDuration: FinishTheLineViewModel.roundDuration,
                accentColor: theme.accentColor
            )
            .overlay(alignment: .top) {
                if showTimeBonusPip {
                    Text("+2s")
                        .font(AppTheme.Typography.caption.weight(.bold))
                        .foregroundColor(AppTheme.success)
                        .offset(y: -22)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
                }
            }

            Spacer()

            scorePill
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showTimeBonusPip)
    }

    private var scorePill: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "star.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)

            Text("\(viewModel.score)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(theme.accentColor)
        )
        .shadow(color: theme.accentColor.opacity(0.35), radius: 6, x: 0, y: 3)
        .accessibilityLabel("Score: \(viewModel.score) points")
    }

    // MARK: - Stage

    private var quoteStage: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            statusRow

            if viewModel.isEncore {
                encoreBanner
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer(minLength: 0)

            if let quote = viewModel.currentQuote {
                QuoteCardView(
                    quote: quote,
                    accentColor: theme.accentColor,
                    resolution: viewModel.cardResolution,
                    showSource: viewModel.cardResolution != nil || viewModel.hintRevealed,
                    isOnFire: viewModel.isOnFire
                )
                .id(quote.id)
                .transition(reduceMotion ? .opacity : quoteTransition)
                .modifier(FinishTheLineShakeEffect(animatableData: shakeCount))
            }

            Spacer(minLength: 0)

            if showNearMissPip {
                Text("So close — say it again!")
                    .font(AppTheme.Typography.footnote.weight(.semibold))
                    .foregroundColor(AppTheme.warning)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule().fill(AppTheme.warning.opacity(0.12))
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            FinishTheLineWaveformView(
                audioLevel: viewModel.speechManager.audioLevel,
                isListening: viewModel.speechManager.isListening,
                accentColor: theme.accentColor
            )

            heardCaption
                .padding(.bottom, AppTheme.Spacing.sm)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.currentStreak)
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: viewModel.currentQuote?.id)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.isEncore)
        .animation(.easeOut(duration: 0.25), value: showNearMissPip)
    }

    /// Streak badge + pass-the-phone target, floating under the HUD.
    @ViewBuilder
    private var statusRow: some View {
        if viewModel.currentStreak >= 2 || viewModel.scoreToBeat != nil {
            HStack(spacing: AppTheme.Spacing.sm) {
                if viewModel.currentStreak >= 2 {
                    StreakBadge(streak: viewModel.currentStreak, isOnFire: viewModel.isOnFire)
                        .transition(.scale.combined(with: .opacity))
                }

                if viewModel.scoreToBeat != nil {
                    targetChip
                }
            }
        }
    }

    private var targetChip: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: viewModel.hasBeatenTarget ? "crown.fill" : "trophy.fill")
                .font(.system(size: 12, weight: .bold))
            Text(verbatim: viewModel.hasBeatenTarget ? "Beaten!" : "Beat \(viewModel.scoreToBeat ?? 0)")
                .font(AppTheme.Typography.pillLabel)
        }
        .foregroundColor(viewModel.hasBeatenTarget ? .white : theme.accentColor)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule().fill(
                viewModel.hasBeatenTarget
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [AppTheme.medalGold, AppTheme.warmGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    : AnyShapeStyle(theme.accentColor.opacity(0.12))
            )
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: viewModel.hasBeatenTarget)
        .accessibilityLabel(
            viewModel.hasBeatenTarget
                ? "Target beaten!"
                : "Score to beat: \(viewModel.scoreToBeat ?? 0)"
        )
    }

    private var encoreBanner: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 12, weight: .bold))
            Text("ENCORE — 2× POINTS")
                .font(AppTheme.Typography.pillLabel)
                .tracking(1.5)
        }
        .foregroundColor(.white)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule().fill(AppTheme.error)
        )
        .shadow(color: AppTheme.error.opacity(0.4), radius: 8, x: 0, y: 3)
        .accessibilityLabel("Encore: double points for the final seconds")
    }

    private var heardCaption: some View {
        Text(viewModel.heardSnippet.isEmpty ? " " : "Heard: \u{201C}\(viewModel.heardSnippet)\u{201D}")
            .font(AppTheme.Typography.caption)
            .foregroundColor(AppTheme.mediumGray.opacity(0.8))
            .lineLimit(1)
            .accessibilityHidden(viewModel.heardSnippet.isEmpty)
    }

    private var quoteTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    // MARK: - Feedback triggers

    private func triggerNearMiss() {
        if !reduceMotion {
            withAnimation(.linear(duration: 0.35)) {
                shakeCount += 1
            }
        }
        showNearMissPip = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            showNearMissPip = false
        }
    }

    private func triggerTimeBonusPip() {
        showTimeBonusPip = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            showTimeBonusPip = false
        }
    }

    // MARK: - Bottom controls

    private var bottomControls: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Button {
                viewModel.skipCurrentQuote()
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "forward.fill")
                    Text("Skip")
                }
                .font(AppTheme.Typography.buttonLabel)
                .foregroundColor(theme.accentColor)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.accentColor.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.accentColor.opacity(0.3), lineWidth: 1)
                )
            }
            .pressable()
            .accessibilityLabel("Skip this quote. Free, but resets your streak.")
        }
    }
}

// MARK: - Shake effect

/// Quick horizontal jitter for near-miss feedback. Named to avoid colliding
/// with Casting Director's ShakeEffect — game folders stay isolated.
private struct FinishTheLineShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: -6 * sin(animatableData * .pi * 3), y: 0)
        )
    }
}
