import Foundation
import AVKit
import SwiftUI

final class VideoPlayerManager: ObservableObject {
    static let shared = VideoPlayerManager()

    private var playerCache: [String: AVPlayer] = [:]
    private var observers: [String: NSObjectProtocol] = [:]
    private var timers: [String: Timer] = [:]
    private var playingPlayers: Set<String> = []

    private init() {}

    func getPlayer(for videoName: String) -> AVPlayer? {

        if let existingPlayer = playerCache[videoName] {
            return existingPlayer
        }

        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            return nil
        }

        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)

        player.isMuted = true
        player.volume = 0.0
        player.allowsExternalPlayback = false
        player.preventsDisplaySleepDuringVideoPlayback = false

        let observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            player.seek(to: .zero) { _ in
                if self?.playingPlayers.contains(videoName) == true {
                    player.play()
                }
            }
        }

        playerCache[videoName] = player
        observers[videoName] = observer

        return player
    }

    func playVideo(_ videoName: String, completion: ((Bool) -> Void)? = nil) {
        guard let player = getPlayer(for: videoName) else {
            completion?(false)
            return
        }

        playingPlayers.insert(videoName)

        if player.currentItem?.status == .readyToPlay {
            player.play()
            completion?(true)
        } else {

            invalidateTimer(for: videoName)
            let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
                if player.currentItem?.status == .readyToPlay {
                    player.play()
                    completion?(true)
                    self?.invalidateTimer(for: videoName)
                } else if player.currentItem?.status == .failed {
                    self?.invalidateTimer(for: videoName)
                    self?.cleanupPlayer(for: videoName)
                    completion?(false)
                }
            }
            timers[videoName] = timer
        }
    }

    func pauseVideo(_ videoName: String) {
        playingPlayers.remove(videoName)
        playerCache[videoName]?.pause()
        invalidateTimer(for: videoName)
    }

    func cleanupPlayer(for videoName: String) {

        playingPlayers.remove(videoName)

        invalidateTimer(for: videoName)

        if let observer = observers[videoName] {
            NotificationCenter.default.removeObserver(observer)
            observers.removeValue(forKey: videoName)
        }

        if let player = playerCache[videoName] {
            player.pause()
            player.replaceCurrentItem(with: nil)
            playerCache.removeValue(forKey: videoName)
        }
    }

    private func invalidateTimer(for videoName: String) {
        timers[videoName]?.invalidate()
        timers.removeValue(forKey: videoName)
    }

    func cleanupAll() {
        for videoName in Array(playerCache.keys) {
            cleanupPlayer(for: videoName)
        }
    }

    deinit {
        cleanupAll()
    }
}
