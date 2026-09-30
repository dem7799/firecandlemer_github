import Foundation
import AVFoundation
import Combine
import UIKit
import SwiftUI

final class PlayerViewModel: ObservableObject {
    enum State {
        case idle
        case downloading(Double) // 0...1 combined
        case ready
        case error(String)
    }

    // Inputs
    let item: VideoItem

    // Outputs
    @Published var state: State = .idle
    @Published var progressText: String = "0%"
    @Published var overlayVisible: Bool = false
    @Published var isMuted: Bool = false { didSet { updatePlayerVolume() } }
    @Published var orientation: OrientationMode = .auto {
        didSet { OrientationManager.shared.setOrientation(orientation) }
    }

    // Sleep timer
    @Published var sleepTimerSelection: TimeInterval? = nil
    @Published var fadeoutEnabled: Bool = true
    private var sleepTimer: Timer?
    @Published var remainingTimeText: String? = nil
    private var countdownTimer: Timer?
    private var sleepEndDate: Date?
    private var fadeWindow: TimeInterval? = nil
    private var targetVolume: Float = 1.0
    @Published var shouldDismissOnSleep: Bool = false

    // Media
    @Published var videoPlayer: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    // Using only video with embedded audio now

    // Progress helpers
    private var videoProgress: Double = 0 { didSet { updateProgress() } }

    init(item: VideoItem) {
        self.item = item
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        cancelSleepTimer()
    }

    func onAppear() {
        configureAudioSession()
        startPlaybackFlow()
    }

    func onDisappear() {
        stop()
    }

    private func updateProgress() {
        let p = videoProgress
        DispatchQueue.main.async {
            self.state = .downloading(p)
            self.progressText = "\(Int(p * 100))%"
        }
    }

    private func downloadIfNeeded() {
        state = .downloading(0)
        Task { @MainActor in
            do {
                let localVideoURL = try await DownloadManager.shared.downloadIfNeeded(url: item.videoURL) { [weak self] progress in
                    self?.videoProgress = progress
                }
                try setupPlayer(videoURL: localVideoURL)
                // state will switch to .ready when playback actually starts
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    private func startPlaybackFlow() {
        Task { @MainActor in
            // 0) Prefer bundled local file in Data/ for development/offline
            if let bundled = locateBundledVideo(forKey: item.videoKey) {
                do {
                    try setupPlayer(videoURL: bundled)
                    return
                } catch {
                    print("[Player] Bundled video failed, fallback to cache/download: \(error)")
                }
            }
            // 1) Cached file?
            let dm = DownloadManager.shared
            if dm.fileExists(for: item.videoURL) {
                let local = dm.cachedFileURL(for: item.videoURL)
                do {
                    try setupPlayer(videoURL: local)
                    return
                } catch {
                    try? FileManager.default.removeItem(at: local)
                }
            }
            // 2) Download
            downloadIfNeeded()
        }
    }

    private var timeStatusObserver: NSKeyValueObservation?

    private func setupPlayer(videoURL: URL) throws {
        let asset = AVAsset(url: videoURL)
        let item = AVPlayerItem(asset: asset)
        // Minimize buffering-induced pause on loop boundary
        item.preferredForwardBufferDuration = 0
        let player = AVQueuePlayer()
        player.automaticallyWaitsToMinimizeStalling = false
        player.actionAtItemEnd = .none
        player.volume = isMuted ? 0 : targetVolume
        self.looper = AVPlayerLooper(player: player, templateItem: item)
        self.videoPlayer = player

        timeStatusObserver = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, _ in
            guard let self = self else { return }
            if player.timeControlStatus == .playing {
                DispatchQueue.main.async { self.state = .ready }
            }
            if player.timeControlStatus == .paused, let current = player.currentItem, current.status == .failed {
                DispatchQueue.main.async { self.state = .error(current.error?.localizedDescription ?? "Playback failed") }
            }
        }
        player.play()
    }

    private func locateBundledVideo(forKey key: String) -> URL? {
        let base = (key as NSString).deletingPathExtension
        let ext = (key as NSString).pathExtension
        if let url = Bundle.main.url(forResource: ext.isEmpty ? base : key, withExtension: ext.isEmpty ? "mp4" : ext, subdirectory: "Data") { return url }
        if let url = Bundle.main.url(forResource: base, withExtension: "mp4") { return url }
        return nil
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            print("[AudioSession] Failed to configure: \(error)")
        }
    }

    func play() {
        videoPlayer?.play()
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }

    func pause() {
        videoPlayer?.pause()
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    func stop() {
        pause()
        videoPlayer?.removeAllItems()
        videoPlayer = nil
        looper = nil
        timeStatusObserver = nil
    }

    @objc private func appDidBecomeActive() {
        if case .ready = state { play() }
    }

    @objc private func appWillResignActive() {
        pause()
    }

    // MARK: - Overlay
    func toggleOverlayAutoHide() {
        withAnimation(.spring()) { overlayVisible.toggle() }
        if overlayVisible {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                withAnimation(.spring()) { self?.overlayVisible = false }
            }
        }
    }

    // MARK: - Sleep Timer
    func scheduleSleep(after interval: TimeInterval?) {
        cancelSleepTimer()
        sleepTimerSelection = interval
        remainingTimeText = nil
        // Reset fade target volume
        targetVolume = 1.0
        updatePlayerVolume()
        fadeWindow = nil
        guard let interval = interval else { return }

        // Set end date and start 1-second countdown updates
        sleepEndDate = Date().addingTimeInterval(interval)
        fadeWindow = min(60, interval)
        updateRemainingText()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateRemainingText()
            // Handle fadeout in the last fadeWindow seconds (or whole duration if < 60s)
            if let end = self.sleepEndDate {
                let remaining = end.timeIntervalSinceNow
                if self.fadeoutEnabled, let window = self.fadeWindow, remaining > 0, remaining <= window {
                    let factor = Float(max(0.0, remaining) / max(1.0, window))
                    if abs(self.targetVolume - factor) > 0.01 {
                        self.targetVolume = factor
                        self.updatePlayerVolume()
                    }
                } else if let window = self.fadeWindow, remaining > window {
                    if abs(self.targetVolume - 1.0) > 0.01 {
                        self.targetVolume = 1.0
                        self.updatePlayerVolume()
                    }
                } else if !self.fadeoutEnabled, abs(self.targetVolume - 1.0) > 0.01 {
                    self.targetVolume = 1.0
                    self.updatePlayerVolume()
                }
            }
            if let end = self.sleepEndDate, Date() >= end {
                self.pause()
                UIApplication.shared.isIdleTimerDisabled = false
                self.cancelSleepTimer()
                self.shouldDismissOnSleep = true
                NotificationCenter.default.post(name: .sleepTimerDidEnd, object: nil)
            }
        }
        // Safety: ensure run loop common modes
        RunLoop.main.add(countdownTimer!, forMode: .common)
    }

    func cancelSleepTimer() {
        sleepTimer?.invalidate(); sleepTimer = nil
        countdownTimer?.invalidate(); countdownTimer = nil
        sleepEndDate = nil
        remainingTimeText = nil
        fadeWindow = nil
        targetVolume = 1.0
        updatePlayerVolume()
    }

    private func updateRemainingText() {
        guard let end = sleepEndDate else { remainingTimeText = nil; return }
        let remaining = max(0, Int(end.timeIntervalSinceNow.rounded()))
        let m = remaining / 60
        let s = remaining % 60
        remainingTimeText = String(format: "%02d:%02d", m, s)
    }

    private func updatePlayerVolume() {
        let vol: Float = isMuted ? 0.0 : targetVolume
        videoPlayer?.volume = vol
    }
}
