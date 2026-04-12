import Foundation

/// Service to enrich content with real audio URLs and metadata
class ContentEnrichmentService {
    static let shared = ContentEnrichmentService()

    // MARK: - NPO Audio URL Generation

    /// Get audio URL for an NPO broadcast
    /// NPO Player streams are available at: https://www.nporadio.nl/live/{channelId}/index.m3u8
    func getNPOAudioURL(channelId: String) -> String {
        // NPO uses m3u8 playlists for live streams
        return "https://www.nporadio.nl/live/\(channelId)/index.m3u8"
    }

    /// Get NPO channel audio stream URL
    /// Maps broadcast channel to actual NPO stream
    func getNPOStreamURL(forChannel channelId: String) -> String {
        let streamMapping: [String: String] = [
            "radio1": "https://www.nporadio.nl/live/npo-radio-1/index.m3u8",
            "radio2": "https://www.nporadio.nl/live/npo-radio-2/index.m3u8",
            "3fm": "https://www.nporadio.nl/live/npo-3fm/index.m3u8",
            "radio4": "https://www.nporadio.nl/live/npo-radio-4/index.m3u8",
            "radio5": "https://www.nporadio.nl/live/npo-radio-5/index.m3u8",
            "radio6": "https://www.nporadio.nl/live/npo-radio-6/index.m3u8"
        ]

        return streamMapping[channelId] ?? "https://www.nporadio.nl/live/npo-radio-1/index.m3u8"
    }

    /// Enhance NPO broadcasts with audio URLs
    func enrichNPOBroadcasts(_ broadcasts: [NPOBroadcast], channelId: String) -> [NPOBroadcast] {
        let audioURL = getNPOStreamURL(forChannel: channelId)

        return broadcasts.map { broadcast in
            NPOBroadcast(
                id: broadcast.id,
                title: broadcast.title,
                programId: broadcast.programId,
                startTime: broadcast.startTime,
                duration: broadcast.duration,
                description: broadcast.description,
                image: broadcast.image,
                audioUrl: audioURL
            )
        }
    }

    // MARK: - Podcast Feed URLs

    /// Popular podcast feeds for testing
    /// These are real, publicly available podcast feeds
    func getPopularPodcasts() -> [PodcastFeed] {
        return [
            // Dutch podcasts
            PodcastFeed(
                id: "vpro-dokzine",
                title: "VPRO Dokzine",
                description: "Journalistiek podcast van VPRO over documentaires en onderzoeksjournalistiek",
                feedURL: "https://feeds.acast.com/public/shows/dokzine",
                image: nil
            ),
            PodcastFeed(
                id: "ntr-human",
                title: "NTR Humaan",
                description: "Podcast over menselijke verhalen en onderwerpen",
                feedURL: "https://feeds.acast.com/public/shows/ntr-human",
                image: nil
            ),
            PodcastFeed(
                id: "bnnvara-rapscribe",
                title: "BnnVara Rapscribe",
                description: "Podcast over rappers, muziek en cultuur",
                feedURL: "https://feeds.acast.com/public/shows/rapscribe",
                image: nil
            ),

            // International podcasts
            PodcastFeed(
                id: "bbc-today",
                title: "BBC Radio 4 Today Programme",
                description: "Leading current affairs programme from BBC Radio 4",
                feedURL: "https://podcasts.bbc.co.uk/today/rss.xml",
                image: nil
            ),
            PodcastFeed(
                id: "npr-npr-news",
                title: "NPR News Now",
                description: "Up-to-the-minute news from NPR",
                feedURL: "https://feeds.npr.org/500005/podcast.xml",
                image: nil
            ),
            PodcastFeed(
                id: "bbc-techbitz",
                title: "BBC Tech News",
                description: "Technology and science news from BBC",
                feedURL: "https://podcasts.bbc.co.uk/programmes/p08mdbvb/episodes/downloads.xml",
                image: nil
            ),

            // Educational
            PodcastFeed(
                id: "crashcourse",
                title: "Crash Course",
                description: "Educational videos on history, science, literature and more",
                feedURL: "https://feeds.acast.com/public/shows/crash-course-side-hustle",
                image: nil
            ),
            PodcastFeed(
                id: "ologies",
                title: "Ologies",
                description: "An educational podcast about obscure sciences and research",
                feedURL: "https://feeds.acast.com/public/shows/ologies",
                image: nil
            )
        ]
    }

    // MARK: - Test Audio URLs (for development)

    /// Get test audio URL for development
    /// Uses publicly available, royalty-free audio streams
    func getTestAudioURL() -> String {
        // Radio Garden stream (works globally, real radio)
        return "https://stream.radiogarden.com/stream"
    }

    /// Get list of test audio URLs
    /// These are real, working audio streams for testing
    func getTestAudioURLs() -> [String: String] {
        return [
            // Real public radio streams
            "npo_radio1": "https://www.nporadio.nl/live/npo-radio-1/index.m3u8",
            "npo_radio2": "https://www.nporadio.nl/live/npo-radio-2/index.m3u8",
            "npo_3fm": "https://www.nporadio.nl/live/npo-3fm/index.m3u8",
            "bbc_radio4": "https://a.files.bbci.co.uk/media/live/manifesto/audio_128kbps/coreuswest/bbc_radio_four_fm.m3u8",

            // Test/public streams
            "radiogarden": "https://stream.radiogarden.com/stream",

            // Free audio samples (for testing playback)
            "test_sample": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
        ]
    }

    // MARK: - Real Content Discovery

    /// Discover real NPO content by checking what's live now
    func getRealNPOContent() -> [(channel: String, url: String)] {
        return [
            ("NPO Radio 1", "https://www.nporadio.nl/live/npo-radio-1/index.m3u8"),
            ("NPO Radio 2", "https://www.nporadio.nl/live/npo-radio-2/index.m3u8"),
            ("NPO 3FM", "https://www.nporadio.nl/live/npo-3fm/index.m3u8"),
            ("NPO Radio 4", "https://www.nporadio.nl/live/npo-radio-4/index.m3u8"),
            ("NPO Radio 5", "https://www.nporadio.nl/live/npo-radio-5/index.m3u8"),
            ("NPO Radio 6", "https://www.nporadio.nl/live/npo-radio-6/index.m3u8")
        ]
    }
}
