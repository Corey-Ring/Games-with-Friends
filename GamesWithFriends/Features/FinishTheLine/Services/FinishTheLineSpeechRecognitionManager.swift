//
//  FinishTheLineSpeechRecognitionManager.swift
//  GamesWithFriends
//
//  TODO: CONSOLIDATION — This manager is duplicated in BorderBlitz,
//  FinishTheLine and CountryLetterGame. Extract the common logic to
//  Core/Services/SpeechRecognitionManager.swift with a generic match
//  callback. See FinishTheLine_PRD.md §6 and DECISIONS.md.
//
//  Behaviorally identical to BorderBlitzSpeechRecognitionManager — the only
//  difference is the class name and enum prefix. The `matchHandler` callback
//  is already generic (`(String) -> Void`), so the quote-matching logic lives
//  in FinishTheLineViewModel rather than here.
//

import Speech
import AVFoundation

enum FinishTheLineSpeechPermissionStatus {
    case notDetermined
    case authorized
    case denied
}

@MainActor
@Observable
class FinishTheLineSpeechRecognitionManager {
    // MARK: - Properties
    var audioLevel: Float = 0.0
    var recognizedText: String = ""
    var isListening: Bool = false
    var permissionStatus: FinishTheLineSpeechPermissionStatus = .notDetermined

    var matchHandler: ((String) -> Void)?

    // MARK: - Private Properties
    @ObservationIgnored private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @ObservationIgnored private let audioEngine = AVAudioEngine()
    @ObservationIgnored private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: - Permissions

    /// Checks current permission status without prompting. Safe to call on view appear.
    func checkPermissionStatus() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()

        let micGranted: Bool
        let micUndetermined: Bool
        if #available(iOS 17.0, *) {
            let p = AVAudioApplication.shared.recordPermission
            micGranted = (p == .granted)
            micUndetermined = (p == .undetermined)
        } else {
            let p = AVAudioSession.sharedInstance().recordPermission
            micGranted = (p == .granted)
            micUndetermined = (p == .undetermined)
        }

        if speechStatus == .notDetermined || micUndetermined {
            permissionStatus = .notDetermined
        } else if speechStatus == .authorized && micGranted {
            permissionStatus = .authorized
        } else {
            permissionStatus = .denied
        }
    }

    /// Requests permissions, showing system dialogs if not yet determined.
    func requestPermissions() async {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            permissionStatus = .denied
            return
        }

        let micGranted: Bool
        if #available(iOS 17.0, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        permissionStatus = micGranted ? .authorized : .denied
    }

    // MARK: - Listening

    func startListening() {
        guard permissionStatus == .authorized else { return }
        guard speechRecognizer?.isAvailable == true else { return }

        stopListening()

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }

        startRecognitionTask()

        guard installAudioTap() else {
            cleanupRecognition()
            return
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
        } catch {
            cleanupRecognition()
        }
    }

    func stopListening() {
        guard isListening else {
            // Still clean up recognition state even if not fully listening.
            // A start that installed the tap and then failed in engine.start()
            // leaves the tap behind; installing a second one crashes.
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
            recognitionRequest = nil
            recognitionTask?.cancel()
            recognitionTask = nil
            return
        }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
        audioLevel = 0.0

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Private

    private func startRecognitionTask() {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let result {
                    let transcription = result.bestTranscription.formattedString
                    self.recognizedText = transcription
                    self.matchHandler?(transcription)

                    if result.isFinal {
                        self.restartRecognition()
                    }
                }

                if let error = error as? NSError {
                    // Code 1110 = no speech detected; code 301 = task cancelled
                    // Auto-restart on timeout/no-speech errors, ignore cancellations
                    let recoverableCodes = [1110, 301]
                    if recoverableCodes.contains(error.code) {
                        self.restartRecognition()
                    }
                }
            }
        }
    }

    private func restartRecognition() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognizedText = ""

        guard isListening else { return }
        startRecognitionTask()
    }

    @discardableResult
    private func installAudioTap() -> Bool {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            return false
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Compute RMS audio level
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else { return }

            var sumOfSquares: Float = 0.0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sumOfSquares += sample * sample
            }
            let rms = sqrtf(sumOfSquares / Float(frameLength))
            let normalizedLevel = min(rms * 3.0, 1.0)

            Task { @MainActor [weak self] in
                guard let self else { return }
                self.audioLevel = self.audioLevel * 0.3 + normalizedLevel * 0.7
            }
        }
        return true
    }

    private func cleanupRecognition() {
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
        audioLevel = 0.0
    }
}
