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
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
            print("Audio session error: \(error)")
        }
    }

    @Published var currentTitle: String?
    @Published var currentImageUrl: String?
    @Published var isLiveStream = false
    @Published var currentSource: String?

    private let dbService = DatabaseService.shared
    private var currentSessionId: String?

    func play(content: AudioContent) async {
        guard let urlString = content.audioUrl else {
            errorMessage = "Geen audio URL"
            return
        }
        currentTitle = content.title
        currentImageUrl = content.image
        currentSource = content.providerId
        isLiveStream = false
        await playURL(urlString)
        startSession(title: content.title, source: content.providerId, contentType: content.contentType, duration: content.duration)
    }

    func playLive(url: String, title: String, imageUrl: String? = nil, source: String = "npo") async {
        currentTitle = title
        currentImageUrl = imageUrl
        currentSource = source
        isLiveStream = true
        await playURL(url)
        startSession(title: title, source: source, contentType: .stream, duration: 0)
    }

    func playOnDemand(url: String, title: String, imageUrl: String? = nil, source: String = "npo") async {
        currentTitle = title
        currentImageUrl = imageUrl
        currentSource = source
        isLiveStream = false
        await playURL(url)
        startSession(title: title, source: source, contentType: .broadcast, duration: Int(duration))
    }

    private func startSession(title: String, source: String, contentType: ContentType, duration: Int) {
        endCurrentSession()
        if let session = dbService.createListeningSession(
            contentId: title,
            contentType: contentType,
            providerId: source,
            title: title,
            source: source,
            duration: duration,
            categories: [],
            topics: [],
            guests: [],
            artists: []
        ) {
            currentSessionId = session.id
        }
    }

    private func endCurrentSession() {
        if let sessionId = currentSessionId {
            _ = dbService.updateListeningSessionProgress(sessionId, progress: Int(currentTime))
            _ = dbService.endListeningSession(sessionId)
            currentSessionId = nil
        }
    }

    private func playURL(_ urlString: String) async {
        guard let url = URL(string: urlString) else {
            errorMessage = "Ongeldige audio URL"
            return
        }

        isPlaying = false
        isBuffering = true
        errorMessage = nil

        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            addPeriodicTimeObserver()
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }

        do {
            let dur = try await asset.load(.duration)
            self.duration = dur.seconds.isNaN ? 0 : dur.seconds
            self.isBuffering = false
            self.player?.play()
            self.isPlaying = true
        } catch {
            // Live streams often can't load duration — that's fine, just play
            self.duration = 0
            self.isBuffering = false
            self.player?.play()
            self.isPlaying = true
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
        endCurrentSession()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        isPlaying = false
        currentTime = 0
        currentContent = nil
        currentTitle = nil
        currentImageUrl = nil
        currentSource = nil
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
