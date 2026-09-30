import SwiftUI
import AVFoundation
import UIKit

struct LoopingBackgroundVideoView: UIViewRepresentable {
    let name: String
    let placeholderImageName: String?

    func makeUIView(context: Context) -> BGPlayerContainerView {
        let view = BGPlayerContainerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.isUserInteractionEnabled = false
        configure(on: view)
        return view
    }

    func updateUIView(_ uiView: BGPlayerContainerView, context: Context) {
        configure(on: uiView)
    }

    private func configure(on container: BGPlayerContainerView) {
        guard let url = Self.locateVideo(named: name) else {
            container.playerLayer.player = nil
            return
        }
        let (player, looper) = PlayerCache.shared.player(for: url)
        container.playerLayer.player = player
        container.looper = looper
        player.isMuted = true
        if player.timeControlStatus != .playing {
            player.play()
        }
    }

    private static func locateVideo(named: String) -> URL? {
        let base = (named as NSString).deletingPathExtension
        let ext = (named as NSString).pathExtension.isEmpty ? nil : (named as NSString).pathExtension

        // 1) Try in bundle subdirectory "Data" only (primary source)
        if let url = Bundle.main.url(forResource: ext == nil ? base : named, withExtension: ext, subdirectory: "Data") {
            #if DEBUG
            print("[BGVideo] Found in Data/: \(url.lastPathComponent)")
            #endif
            return url
        }
        if let url = Bundle.main.url(forResource: base, withExtension: "mp4", subdirectory: "Data") {
            #if DEBUG
            print("[BGVideo] Found mp4 in Data/: \(url.lastPathComponent)")
            #endif
            return url
        }

        // 2) Optional: root bundle fallback
        if let url = Bundle.main.url(forResource: ext == nil ? base : named, withExtension: ext) {
            #if DEBUG
            print("[BGVideo] Found in bundle: \(url.lastPathComponent)")
            #endif
            return url
        }
        if let url = Bundle.main.url(forResource: base, withExtension: "mp4") {
            #if DEBUG
            print("[BGVideo] Found mp4 in bundle: \(url.lastPathComponent)")
            #endif
            return url
        }

        #if DEBUG
        print("[BGVideo] Not found in Data/: \(named)")
        #endif
        return nil
    }

    private static func cachedTempURL(for name: String) -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return caches.appendingPathComponent("bg_\(name).mp4")
    }
}

final class BGPlayerContainerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    // Hold the looper strongly to keep looping working
    var looper: AVPlayerLooper?
}

// MARK: - Lightweight player cache to remove startup delay
private final class PlayerCache {
    static let shared = PlayerCache()
    private var players: [URL: AVQueuePlayer] = [:]
    private var loopers: [URL: AVPlayerLooper] = [:]
    private init() {}

    func player(for url: URL) -> (AVQueuePlayer, AVPlayerLooper) {
        if let p = players[url], let l = loopers[url] {
            return (p, l)
        }
        let asset = AVAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 0
        let player = AVQueuePlayer()
        player.automaticallyWaitsToMinimizeStalling = false
        player.actionAtItemEnd = .none
        let looper = AVPlayerLooper(player: player, templateItem: item)
        players[url] = player
        loopers[url] = looper
        return (player, looper)
    }
}
