import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    @State private var customTimerMinutes: Int = 1
    @State private var customTimerSeconds: Int = 0

    var body: some View {
        NavigationView {
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
                } footer: {
                    Text("Add a time limit to each conversation starter")
                }

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
                                            .foregroundColor(.blue)
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
                                        .foregroundColor(.blue)
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
                        }
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.blue)
                        Text("Sound alerts when timer expires")
                        Spacer()
                        Toggle("", isOn: $viewModel.settings.soundEnabled)
                            .labelsHidden()
                    }

                    HStack {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .foregroundColor(.purple)
                        Text("Haptic feedback")
                        Spacer()
                        Toggle("", isOn: $viewModel.settings.hapticEnabled)
                            .labelsHidden()
                    }
                } header: {
                    Text("Notifications")
                }

                Section {
                    HStack {
                        Text("Current Timer")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(timeString(from: viewModel.settings.timerDuration))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                }
            }
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
