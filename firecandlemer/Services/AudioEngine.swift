import AVFoundation

final class AudioEngine: NSObject, ObservableObject {
    private var player: AVAudioPlayer?
    @Published var isMuted: Bool = false {
        didSet { player?.volume = isMuted ? 0.0 : 1.0 }
    }

    func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    func load(url: URL) throws {
        player = try AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = -1
        player?.prepareToPlay()
        player?.volume = isMuted ? 0.0 : 1.0
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func stop() {
        player?.stop()
        player = nil
    }
}

