//
//  FinishTheLineCountdownView.swift
//  GamesWithFriends
//

import SwiftUI

struct FinishTheLineCountdownView: View {
    @Bindable var viewModel: FinishTheLineViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // The 260pt numeral plate owns the middle of the screen;
                // motifs keep to the top and bottom bands (§7 — nothing within
                // 12pt of the countdown, the generator adds the clearance).
                MotifGroundView(seed: 0xFA11_0E02,
                                exclusions: [CGRect(x: 8,
                                                    y: geo.size.height / 2 - 170,
                                                    width: geo.size.width - 16,
                                                    height: 340)])
            }
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.xl) {
                // ALL CAPS is sanctioned in a Lilita pill label (§4).
                Text("Get ready")
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .textCase(.uppercase)
                    .tracking(3)
                    .retroLozenge()

                countdownNumeral
                    .frame(width: 260, height: 260)

                Text("Shout the missing word")
                    .font(AppTheme.Retro.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .multilineTextAlignment(.center)
                    .retroLozenge()
                    .padding(.horizontal, AppTheme.Spacing.lg)

                if let target = viewModel.scoreToBeat {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(verbatim: "Score to beat: \(target)")
                            .font(AppTheme.Retro.Typography.pillLabel)
                    }
                    // Mustard metal, ink label (§8 — ink passes on mustard).
                    .foregroundColor(FinishTheLineStyle.chipTextColor(on: FinishTheLineStyle.bestColor))
                    .retroLozenge(FinishTheLineStyle.bestColor)
                    .accessibilityLabel("Score to beat: \(target) points")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.countdownValue > 0 ? "Starting in \(viewModel.countdownValue)" : "Go")
    }

    // MARK: - Countdown numeral
    //
    // Chunky framed lettering (Rule 4): cream Lilita letterforms with a hard
    // ink offset, locked inside an ink-outlined plate. Gradients retired (§9).
    // The plate swaps to grass on GO — the sanctioned celebration accent.

    private var countdownNumeral: some View {
        ZStack {
            Circle()
                .fill(plateFill)
            Circle()
                .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)

            // Numeral or GO
            Group {
                if viewModel.countdownValue > 0 {
                    Text("\(viewModel.countdownValue)")
                        .font(AppTheme.Retro.Typography.heading(160, relativeTo: .largeTitle))
                        .foregroundColor(AppTheme.Retro.cream)
                        .shadow(color: AppTheme.Retro.ink, radius: 0, x: 5, y: 5)
                } else {
                    Text("GO")
                        .font(AppTheme.Retro.Typography.heading(110, relativeTo: .largeTitle))
                        .foregroundColor(AppTheme.Retro.cream)
                        .shadow(color: AppTheme.Retro.ink, radius: 0, x: 5, y: 5)
                        .tracking(2)
                }
            }
            .id(viewModel.countdownValue)
            .transition(reduceMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.65), value: viewModel.countdownValue)
        }
        .background(
            Circle()
                .fill(AppTheme.Retro.ink)
                .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
        )
    }

    private var plateFill: Color {
        viewModel.countdownValue > 0
            ? FinishTheLineStyle.accent
            : FinishTheLineStyle.correctColor
    }
}
