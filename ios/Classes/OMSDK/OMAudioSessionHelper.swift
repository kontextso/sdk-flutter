import AVFoundation

/// Manages AVAudioSession for OMID device volume change tracking in HTML video ads.
///
/// The OMID native SDK automatically detects device volume changes, but requires
/// an active audio session with `.mixWithOthers` to observe `outputVolume` via KVO.
/// Without this, device volume change events are not delivered to verification scripts.
///
/// Reference: IAB OMSDK demo WebViewVideoController.swift
final class OMAudioSessionHelper {
    /// Shared helper used by all web views in the process.
    static let shared = OMAudioSessionHelper()

    private init() {}

    /// Number of active OM video sessions currently holding the shared audio session.
    ///
    /// Multiple web views can host HTML video ads at the same time. The counter keeps
    /// the shared AVAudioSession active until the last tracked video session is released.
    private var activeVideoSessionCount = 0
    private var isAudioSessionActive = false

    /// Records a video session that needs OMID device volume change tracking.
    ///
    /// Activates the shared audio session on the first acquisition.
    func acquireVideoSession() {
        activeVideoSessionCount += 1
        activateAudioSessionIfNeeded()
    }

    /// Releases a previously tracked video session.
    ///
    /// Deactivates the shared audio session only after the last tracked session ends.
    func releaseVideoSession() {
        guard activeVideoSessionCount > 0 else {
            return
        }

        activeVideoSessionCount -= 1

        guard activeVideoSessionCount == 0 else {
            return
        }

        deactivateAudioSessionIfNeeded()
    }

    private func activateAudioSessionIfNeeded() {
        guard !isAudioSessionActive else {
            return
        }

        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            isAudioSessionActive = true
        } catch {
            NSLog("[OM] Failed to activate audio session: \(error)")
        }
    }

    private func deactivateAudioSessionIfNeeded() {
        guard isAudioSessionActive else {
            return
        }

        let session = AVAudioSession.sharedInstance()

        do {
            try session.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            NSLog("[OM] Failed to deactivate audio session: \(error)")
        }

        isAudioSessionActive = false
    }
}
