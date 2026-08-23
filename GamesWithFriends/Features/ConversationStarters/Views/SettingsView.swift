import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    @State private var customTimerMinutes: Int = 1
    @State private var customTimerSeconds: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Timer", isOn: $viewModel.settings.timerEnabled)
                        .onChange(of: viewModel.settings.timerEnabled) { oldValue, newValue in
                            if newValue {
                                viewModel.resetTimer()
                            } else {
                                viewModel.pauseTimer()
                            }
                        }
                } header: {
                    Text("Timer")
                        .foregroundColor(AppTheme.Retro.cocoa)
                } footer: {
                    Text("Add a time limit to each conversation starter")
                        .foregroundColor(AppTheme.Retro.cocoa)
                }
                .listRowBackground(AppTheme.Retro.panel)

                if viewModel.settings.timerEnabled {
                    Section("Timer Duration") {
                        ForEach(TimerPreset.allCases.filter { $0 != .custom }, id: \.self) { preset in
                            Button(action: {
                                viewModel.settings.timerDuration = preset.duration
                                viewModel.resetTimer()
                            }) {
                                HStack {
                                    Text(preset.rawValue)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if abs(viewModel.settings.timerDuration - preset.duration) < 1 {
                                        Image(systemName: "checkmark")
                                            .fontWeight(.bold)
                                            .foregroundColor(AppTheme.Retro.ink)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Custom")
                                    .foregroundColor(.primary)
                                Spacer()
                                if !TimerPreset.allCases.dropLast().contains(where: { abs(viewModel.settings.timerDuration - $0.duration) < 1 }) {
                                    Image(systemName: "checkmark")
                                        .fontWeight(.bold)
                                        .foregroundColor(AppTheme.Retro.ink)
                                }
                            }

                            HStack {
                                Picker("Minutes", selection: $customTimerMinutes) {
                                    ForEach(0...10, id: \.self) { min in
                                        Text("\(min)m").tag(min)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(maxWidth: .infinity)

                                Picker("Seconds", selection: $customTimerSeconds) {
                                    ForEach([0, 15, 30, 45], id: \.self) { sec in
                                        Text("\(sec)s").tag(sec)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(maxWidth: .infinity)
                            }
                            .frame(height: 120)

                            Button("Set Custom Timer") {
                                let totalSeconds = TimeInterval(customTimerMinutes * 60 + customTimerSeconds)
                                if totalSeconds > 0 {
                                    viewModel.settings.timerDuration = totalSeconds
                                    viewModel.resetTimer()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.borderedProminent)
                            .foregroundColor(AppTheme.Retro.ink)
                            .fontWeight(.semibold)
                        }
                    }
                    .listRowBackground(AppTheme.Retro.panel)
                }

                Section {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(AppTheme.Retro.ink)
                        Text("Sound alerts when timer expires")
                        Spacer()
                        Toggle("", isOn: $viewModel.settings.soundEnabled)
                            .labelsHidden()
                    }

                    HStack {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .foregroundColor(AppTheme.Retro.ink)
                        Text("Haptic feedback")
                        Spacer()
                        Toggle("", isOn: $viewModel.settings.hapticEnabled)
                            .labelsHidden()
                    }
                } header: {
                    Text("Notifications")
                        .foregroundColor(AppTheme.Retro.cocoa)
                }
                .listRowBackground(AppTheme.Retro.panel)

                Section {
                    HStack {
                        Text("Current Timer")
                            .foregroundColor(AppTheme.Retro.cocoa)
                        Spacer()
                        Text(timeString(from: viewModel.settings.timerDuration))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                }
                .listRowBackground(AppTheme.Retro.panel)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Retro.ground.ignoresSafeArea())
            .tint(ConversationStartersStyle.accent)
            .navigationTitle("Settings")
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

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
