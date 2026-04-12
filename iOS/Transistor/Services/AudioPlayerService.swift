import Foundation
import AVFoundation

@MainActor
class AudioPlayerService: NSObject, ObservableObject {
    static let shared = AudioPlayerService()

    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isBuffering = false
    @Published var errorMessage: String?
    @Published var currentContent: AudioContent?

    private var player: AVPlayer?
    private var timeObserver: Any?

    override private init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.deferredDeactivationDelay])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
            print("Audio session error: \(error)")
        }
    }

    func play(content: AudioContent) async {
        guard let urlString = content.audioUrl, let url = URL(string: urlString) else {
            errorMessage = "Invalid audio URL"
            return
        }

        currentContent = content
        isPlaying = false
        isBuffering = true

        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            addPeriodicTimeObserver()
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }

        // Update duration when metadata loads
        Task {
            do {
                let duration = try await asset.load(.duration)
                self.duration = duration.seconds
                self.isBuffering = false
                self.player?.play()
                self.isPlaying = true
                errorMessage = nil
            } catch {
                errorMessage = "Failed to load audio: \(error.localizedDescription)"
                isBuffering = false
            }
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        isPlaying = false
        currentTime = 0
        currentContent = nil
    }

    func seek(to seconds: Double) {
        let cmTime = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }

    func setPlaybackRate(_ rate: Float) {
        player?.rate = rate
    }

    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }

    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
    }
}
