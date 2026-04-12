import Foundation

/// Service to enrich content with audio URLs and metadata.
/// NPO-specific enrichment has moved to NPOProvider.
class ContentEnrichmentService {
    static let shared = ContentEnrichmentService()

    // MARK: - NPO Audio URL Generation (delegating to NPOProvider)

    /// Get audio URL for an NPO broadcast — delegates to NPOProvider
    func getNPOAudioURL(channelId: String) -> String {
        return NPOProvider().getAudioURL(channelId: channelId)
    }

    /// Get NPO channel audio stream URL — delegates to NPOProvider
    func getNPOStreamURL(forChannel channelId: String) -> String {
        return NPOProvider().getStreamURL(forChannel: channelId)
    }

    /// Enhance NPO broadcasts with audio URLs — delegates to NPOProvider
    func enrichNPOBroadcasts(_ broadcasts: [NPOBroadcast], channelId: String) -> [NPOBroadcast] {
        return NPOProvider().enrichBroadcasts(broadcasts, channelId: channelId)
    }

    /// Discover real NPO content — delegates to NPOProvider
    func getRealNPOContent() -> [(channel: String, url: String)] {
        return NPOProvider().getRealContent()
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
                image: nil,
                episodes: []
            ),
            PodcastFeed(
                id: "ntr-human",
                title: "NTR Humaan",
                description: "Podcast over menselijke verhalen en onderwerpen",
                feedURL: "https://feeds.acast.com/public/shows/ntr-human",
                image: nil,
                episodes: []
            ),
            PodcastFeed(
                id: "bnnvara-rapscribe",
                title: "BnnVara Rapscribe",
                description: "Podcast over rappers, muziek en cultuur",
                feedURL: "https://feeds.acast.com/public/shows/rapscribe",
                image: nil,
                episodes: []
            ),

            // International podcasts
            PodcastFeed(
                id: "bbc-today",
                title: "BBC Radio 4 Today Programme",
                description: "Leading current affairs programme from BBC Radio 4",
                feedURL: "https://podcasts.bbc.co.uk/today/rss.xml",
                image: nil,
                episodes: []
            ),
            PodcastFeed(
                id: "npr-npr-news",
                title: "NPR News Now",
                description: "Up-to-the-minute news from NPR",
                feedURL: "https://feeds.npr.org/500005/podcast.xml",
                image: nil,
                episodes: []
            ),
            PodcastFeed(
                id: "bbc-techbitz",
                title: "BBC Tech News",
                description: "Technology and science news from BBC",
                feedURL: "https://podcasts.bbc.co.uk/programmes/p08mdbvb/episodes/downloads.xml",
                image: nil,
                episodes: []
            ),

            // Educational
            PodcastFeed(
                id: "crashcourse",
                title: "Crash Course",
                description: "Educational videos on history, science, literature and more",
                feedURL: "https://feeds.acast.com/public/shows/crash-course-side-hustle",
                image: nil,
                episodes: []
            ),
            PodcastFeed(
                id: "ologies",
                title: "Ologies",
                description: "An educational podcast about obscure sciences and research",
                feedURL: "https://feeds.acast.com/public/shows/ologies",
                image: nil,
                episodes: []
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
}
