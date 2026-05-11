import SwiftUI
import AVKit

enum RockyVideo: String, CaseIterable {
    case wave = "rocky-wave"
    case celebrate = "rocky-celebrate"
    case think = "rocky-think"
}

struct RockyVideoView: View {
    let video: RockyVideo
    let loop: Bool

    @State private var player: AVPlayer?
    @State private var videoLoaded = false
    @State private var loopObserver: NSObjectProtocol?

    init(_ video: RockyVideo, loop: Bool = true) {
        self.video = video
        self.loop = loop
    }

    var body: some View {
        Group {
            if let player, videoLoaded {
                VideoPlayer(player: player)
                    .disabled(true)
                    .allowsHitTesting(false)
                    .aspectRatio(contentMode: .fit)
                    .onAppear { player.play() }
            } else {
                // Fallback placeholder while video loads or if video is missing
                Circle()
                    .fill(ColorToken.secondary)
                    .overlay(
                        Text("🐾")
                            .font(.system(size: 20))
                    )
            }
        }
        .onAppear {
            loadVideo()
        }
        .onDisappear {
            player?.pause()
            if let loopObserver {
                NotificationCenter.default.removeObserver(loopObserver)
            }
            loopObserver = nil
        }
    }

    private func loadVideo() {
        guard let url = Bundle.main.url(forResource: video.rawValue, withExtension: "mp4") else {
            // Video file not bundled — placeholder stays visible
            return
        }
        let p = AVPlayer(url: url)
        let shouldLoop = loop && video != .celebrate
        if shouldLoop {
            p.actionAtItemEnd = .none
            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: p.currentItem,
                queue: .main
            ) { _ in
                p.seek(to: .zero)
                p.play()
            }
        }
        self.player = p
        // Small delay to let the player buffer, then show video
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            videoLoaded = true
            p.play()
        }
    }
}
