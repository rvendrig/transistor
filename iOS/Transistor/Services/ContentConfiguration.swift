import Foundation

/// Configuration for content sources and behavior
enum ContentConfiguration {
    /// Use real content from APIs (requires network)
    case realContent

    /// Use mock data (offline, for testing)
    case mockData

    /// Use real APIs with fallback to mock
    case hybrid
}

/// Global content configuration
class ContentConfig {
    static var mode: ContentConfiguration = .hybrid

    // MARK: - Toggle Methods

    static func enableRealContent() {
        Self.mode = .realContent
        print("Real content enabled")
    }

    static func enableMockData() {
        Self.mode = .mockData
        print("Mock data enabled")
    }

    static func enableHybridMode() {
        Self.mode = .hybrid
        print("Hybrid mode enabled (real with fallback)")
    }

    // MARK: - Debug Info

    static func printConfiguration() {
        let channelNames = getAvailableChannels()
        let podcastNames = podcastsAvailable()
        print("""
        ===================================
        TRANSISTOR CONTENT CONFIGURATION
        ===================================
        Mode: \(Self.mode)
        Channels: \(channelNames.count)
        Audio URLs: \(audioURLsAvailable() ? "Real" : "Mock")
        Podcasts: \(podcastNames.count) feeds
        ===================================
        """)
    }

    // MARK: - Content Availability

    static func audioURLsAvailable() -> Bool {
        switch Self.mode {
        case .realContent, .hybrid:
            return true
        case .mockData:
            return false
        }
    }

    /// Returns available channel names from registered providers.
    /// No longer hardcoded to NPO -- pulls from ProviderStore if providers are registered,
    /// otherwise falls back to a sensible default.
    static func getAvailableChannels() -> [String] {
        let store = ProviderStore.shared
        let providers = store.allActiveProviders()

        if providers.isEmpty {
            // Fallback when ProviderStore hasn't been populated yet
            return []
        }

        // Collect channel names synchronously from known local sources
        // Full async channel fetch is done through ContentViewModel
        return providers.map { $0.name }
    }

    static func podcastsAvailable() -> [String] {
        return ContentEnrichmentService.shared.getPopularPodcasts().map { $0.title }
    }
}

// MARK: - Real Content Seeding

/// Helper to seed app with real content for testing
class RealContentSeed {
    static let shared = RealContentSeed()

    /// Get seed data for NPO channels with real streams
    func getNPOChannelsWithRealStreams() -> [(channelId: String, name: String, description: String, audioUrl: String)] {
        let provider = NPOProvider()
        return provider.getRealContent().enumerated().map { index, pair in
            let channelIds = ["radio1", "radio2", "3fm", "radio4", "radio5", "radio6"]
            let descriptions = [
                "Nieuws, sport, cultuur en entertainment",
                "Muziek, entertainment en informatieve programma's",
                "Muziek, hits en alternatieve nummers",
                "Klassieke muziek en jazz",
                "Documentaires en reportages",
                "Muziek en verhalen"
            ]
            let channelId = index < channelIds.count ? channelIds[index] : "radio\(index + 1)"
            let description = index < descriptions.count ? descriptions[index] : pair.channel
            return (channelId: channelId, name: pair.channel, description: description, audioUrl: pair.url)
        }
    }

    /// Get real podcast feeds for seeding
    func getRealPodcasts() -> [(title: String, feedURL: String, description: String)] {
        return ContentEnrichmentService.shared.getPopularPodcasts().prefix(5).map { feed in
            (title: feed.title, feedURL: feed.feedURL, description: feed.description ?? "")
        }
    }

    /// Test URLs that definitely work
    func getTestAudioURLs() -> [String: String] {
        return ContentEnrichmentService.shared.getTestAudioURLs()
    }
}

// MARK: - Debug Helpers

/// Print helpful debugging information
func debugContentSetup() {
    print("""
    TRANSISTOR CONTENT SETUP DEBUG

    Configuration: \(ContentConfig.mode)

    Real Audio URLs Available:
    - NPO Radio 1: https://www.nporadio.nl/live/npo-radio-1/index.m3u8
    - NPO Radio 2: https://www.nporadio.nl/live/npo-radio-2/index.m3u8
    - BBC Radio 4: https://a.files.bbci.co.uk/media/live/manifesto/audio_128kbps/coreuswest/bbc_radio_four_fm.m3u8

    Real Podcast Feeds:
    - BBC Today: https://podcasts.bbc.co.uk/today/rss.xml
    - NPR News: https://feeds.npr.org/500005/podcast.xml
    - Ologies: https://feeds.acast.com/public/shows/ologies

    Test Audio File:
    - Sample MP3: https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3

    Next Steps:
    1. ContentConfig.enableRealContent()
    2. Verify network connection
    3. Run app and test playback
    4. Check logs for any API errors
    """)
}
