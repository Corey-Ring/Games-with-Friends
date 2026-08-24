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

    var body: some View {
        ZStack {
            // Plain ground, no motif field: the live waveform and the timer
            // dial both animate here, and §7 keeps decoration ≥12pt clear of
            // interactive/visualization areas — which is the whole column.
            AppTheme.Retro.ground
                .ignoresSafeArea()

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
            // Round-nav button (§3 recipe): ink glyph on a cream disc, hard
            // shadow from the raised style rather than a soft ring.
            Button {
                viewModel.quitRound()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.Retro.panelText)
                    .frame(width: 44, height: 44)
                    .retroPanel(AppTheme.Retro.panel, cornerRadius: 999)
            }
            .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))
            .accessibilityLabel("Quit round")

            Spacer()

            SpotlightTimerView(
                timeRemaining: viewModel.timeRemaining,
                totalDuration: FinishTheLineViewModel.roundDuration,
                accentColor: FinishTheLineStyle.accent
            )
            .overlay(alignment: .top) {
                if showTimeBonusPip {
                    // §8: grass can't be small text on cream — grass-filled chip, ink label.
                    Text("+2s")
                        .font(AppTheme.Retro.Typography.pillLabel)
                        .foregroundColor(AppTheme.Retro.ink)
                        .retroLozenge(FinishTheLineStyle.correctColor)
                        .offset(y: -26)
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

            Text("\(viewModel.score)")
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        // §8 plum rule: cream label on the plum fill, never ink.
        .foregroundColor(FinishTheLineStyle.chipTextColor(on: FinishTheLineStyle.accent))
        .retroLozenge(FinishTheLineStyle.accent)
        .background(
            Capsule()
                .fill(AppTheme.Retro.ink)
                .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
        )
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
                    accentColor: FinishTheLineStyle.accent,
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
                // §8: tangerine can't be small text on cream — tangerine chip, ink label.
                Text("So close — say it again!")
                    .font(AppTheme.Typography.footnote.weight(.semibold))
                    .foregroundColor(AppTheme.Retro.ink)
                    .retroLozenge(FinishTheLineStyle.skippedColor)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            FinishTheLineWaveformView(
                audioLevel: viewModel.speechManager.audioLevel,
                isListening: viewModel.speechManager.isListening,
                accentColor: FinishTheLineStyle.accent
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
                .font(AppTheme.Retro.Typography.pillLabel)
        }
        // Beaten: the mustard metal lights up (ink label passes on mustard).
        // Not yet: plain cream lozenge, ink label. Gradient retired (§9).
        .foregroundColor(viewModel.hasBeatenTarget
                         ? FinishTheLineStyle.chipTextColor(on: FinishTheLineStyle.bestColor)
                         : AppTheme.Retro.panelText)
        .retroLozenge(viewModel.hasBeatenTarget ? FinishTheLineStyle.bestColor : AppTheme.Retro.panel)
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
                .font(.system(size: 14, weight: .bold))
            Text("ENCORE — 2× POINTS")
                .font(AppTheme.Retro.Typography.heading(17))
                .tracking(1.5)
        }
        // §8: on tomato, cream is display-only — Lilita at 17pt clears the bar.
        .foregroundColor(AppTheme.Retro.cream)
        .retroLozenge(FinishTheLineStyle.dangerColor)
        .background(
            Capsule()
                .fill(AppTheme.Retro.ink)
                .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
        )
        .accessibilityLabel("Encore: double points for the final seconds")
    }

    private var heardCaption: some View {
        // The blank-space fallback keeps the row's height reserved; the
        // lozenge just fades out with it so no empty pill sits on the ground.
        Text(viewModel.heardSnippet.isEmpty ? " " : "Heard: \u{201C}\(viewModel.heardSnippet)\u{201D}")
            .font(AppTheme.Typography.caption)
            .foregroundColor(AppTheme.Retro.panelText)
            .lineLimit(1)
            .retroLozenge()
            .opacity(viewModel.heardSnippet.isEmpty ? 0 : 1)
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
            // Secondary action: cream panel + ink label, the house pattern for
            // the non-accent button (one game accent per screen, §3.2).
            RetroPrimaryButton(
                title: "Skip",
                icon: "forward.fill",
                accent: AppTheme.Retro.panel,
                textColor: AppTheme.Retro.panelText
            ) {
                viewModel.skipCurrentQuote()
            }
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
