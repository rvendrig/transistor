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
        print("✅ Real content enabled")
    }

    static func enableMockData() {
        Self.mode = .mockData
        print("📋 Mock data enabled")
    }

    static func enableHybridMode() {
        Self.mode = .hybrid
        print("🔄 Hybrid mode enabled (real with fallback)")
    }

    // MARK: - Debug Info

    static func printConfiguration() {
        print("""
        ═══════════════════════════════════
        📡 TRANSISTOR CONTENT CONFIGURATION
        ═══════════════════════════════════
        Mode: \(Self.mode)
        Channels: \(Self.getAvailableChannels().count)
        Audio URLs: \(Self.audioURLsAvailable() ? "✅ Real" : "ℹ️ Mock")
        Podcasts: \(Self.podcastsAvailable().count) feeds
        ═══════════════════════════════════
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

    static func getAvailableChannels() -> [String] {
        return [
            "NPO Radio 1",
            "NPO Radio 2",
            "NPO 3FM",
            "NPO Radio 4",
            "NPO Radio 5",
            "NPO Radio 6"
        ]
    }

    static func podcastsAvailable() -> [String] {
        return [
            "VPRO Dokzine",
            "NTR Humaan",
            "BnnVara Rapscribe",
            "BBC Radio 4 Today",
            "NPR News Now",
            "BBC Tech News",
            "Crash Course",
            "Ologies"
        ]
    }
}

// MARK: - Real Content Seeding

/// Helper to seed app with real content for testing
class RealContentSeed {
    static let shared = RealContentSeed()

    /// Get seed data for NPO channels with real streams
    func getNPOChannelsWithRealStreams() -> [(channelId: String, name: String, description: String, audioUrl: String)] {
        return [
            ("radio1", "NPO Radio 1", "Nieuws, sport, cultuur en entertainment", "https://www.nporadio.nl/live/npo-radio-1/index.m3u8"),
            ("radio2", "NPO Radio 2", "Muziek, entertainment en informatieve programma's", "https://www.nporadio.nl/live/npo-radio-2/index.m3u8"),
            ("3fm", "NPO 3FM", "Muziek, hits en alternatieve nummers", "https://www.nporadio.nl/live/npo-3fm/index.m3u8"),
            ("radio4", "NPO Radio 4", "Klassieke muziek en jazz", "https://www.nporadio.nl/live/npo-radio-4/index.m3u8"),
            ("radio5", "NPO Radio 5", "Documentaires en reportages", "https://www.nporadio.nl/live/npo-radio-5/index.m3u8"),
            ("radio6", "NPO Radio 6", "Muziek en verhalen", "https://www.nporadio.nl/live/npo-radio-6/index.m3u8")
        ]
    }

    /// Get real podcast feeds for seeding
    func getRealPodcasts() -> [(title: String, feedURL: String, description: String)] {
        return [
            ("BBC Radio 4 Today", "https://podcasts.bbc.co.uk/today/rss.xml", "Leading current affairs from BBC Radio 4"),
            ("NPR News Now", "https://feeds.npr.org/500005/podcast.xml", "Up-to-the-minute news from NPR"),
            ("Ologies", "https://feeds.acast.com/public/shows/ologies", "Educational podcast about sciences"),
            ("VPRO Dokzine", "https://feeds.acast.com/public/shows/dokzine", "Journalistiek podcast van VPRO"),
            ("Crash Course", "https://feeds.acast.com/public/shows/crash-course-side-hustle", "Educational videos on various topics")
        ]
    }

    /// Test URLs that definitely work
    func getTestAudioURLs() -> [String: String] {
        return [
            "npo_radio1": "https://www.nporadio.nl/live/npo-radio-1/index.m3u8",
            "bbc_radio4": "https://a.files.bbci.co.uk/media/live/manifesto/audio_128kbps/coreuswest/bbc_radio_four_fm.m3u8",
            "sample": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
        ]
    }
}

// MARK: - Debug Helpers

/// Print helpful debugging information
func debugContentSetup() {
    print("""
    🔧 TRANSISTOR CONTENT SETUP DEBUG

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
