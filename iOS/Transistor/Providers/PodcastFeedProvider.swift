import Foundation

// MARK: - Podcast Feed Provider
class PodcastFeedProvider: ContentProvider, ObservableObject {
    let id = "podcast_feed"
    let name = "Podcast Feeds"
    let type = ProviderType.podcastPlatform
    let logo: String? = nil

    @Published var feeds: [PodcastFeed] = []

    init() {
        loadFeeds()
    }

    private func loadFeeds() {
        // In production, this would load from user preferences/database
        feeds = []
    }

    // MARK: - Add Custom Feed
    func addFeed(_ url: String) async throws {
        let feed = try await parseFeed(url)
        feeds.append(feed)
    }

    // MARK: - ContentProvider Protocol Implementation
    func fetchChannels() async throws -> [Channel] {
        return feeds.map { feed in
            Channel(
                id: feed.id,
                providerId: id,
                networkId: "podcast_feed",
                titles: [TitledPeriod(title: feed.title)],
                description: feed.description,
                logo: feed.image
            )
        }
    }

    func fetchShows(forChannel channelId: String) async throws -> [Show] {
        // For podcast feeds, each feed is a "channel" and contains episodes
        // This returns an empty array since podcasts don't have shows/series
        return []
    }

    func fetchBroadcasts(forShow showId: String) async throws -> [Broadcast] {
        // Not applicable for podcast feeds
        return []
    }

    func search(_ query: String) async throws -> [any AudioContent] {
        var results: [any AudioContent] = []

        for feed in feeds {
            // Search in feed metadata
            if feed.title.lowercased().contains(query.lowercased()) ||
               feed.description.lowercased().contains(query.lowercased()) {
                for episode in feed.episodes {
                    if episode.title.lowercased().contains(query.lowercased()) ||
                       (episode.description?.lowercased().contains(query.lowercased()) ?? false) {
                        results.append(episode)
                    }
                }
            }
        }

        return results
    }

    // MARK: - Private Methods
    private func parseFeed(_ urlString: String) async throws -> PodcastFeed {
        guard let url = URL(string: urlString) else {
            throw PodcastParseError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let parser = RSSFeedParser()
        return try parser.parse(data)
    }

    func getEpisodes(forFeed feedId: String) -> [Episode] {
        guard let feed = feeds.first(where: { $0.id == feedId }) else {
            return []
        }
        return feed.episodes
    }
}

// MARK: - Podcast Feed Model
struct PodcastFeed: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let feedURL: String
    let image: String?
    var episodes: [Episode]

    enum CodingKeys: String, CodingKey {
        case id, title, description, image, episodes
        case feedURL = "feed_url"
    }
}

// MARK: - RSS Feed Parser
class RSSFeedParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentAudioURL = ""
    private var currentPublishDate = ""
    private var episodes: [Episode] = []
    private var feedTitle = ""
    private var feedDescription = ""
    private var feedImage = ""

    func parse(_ data: Data) throws -> PodcastFeed {
        let parser = XMLParser(data: data)
        parser.delegate = self

        guard parser.parse() else {
            throw PodcastParseError.parseError
        }

        return PodcastFeed(
            id: UUID().uuidString,
            title: feedTitle,
            description: feedDescription,
            feedURL: "",
            image: feedImage.isEmpty ? nil : feedImage,
            episodes: episodes
        )
    }

    // MARK: - XMLParserDelegate
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName

        if elementName == "enclosure" {
            currentAudioURL = attributeDict["url"] ?? ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespaces)

        switch currentElement {
        case "title":
            currentTitle += trimmedString
        case "description":
            currentDescription += trimmedString
        case "pubDate":
            currentPublishDate += trimmedString
        case "image":
            feedImage += trimmedString
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            // Create episode
            let dateFormatter = ISO8601DateFormatter()
            let pubDate = dateFormatter.date(from: currentPublishDate) ?? Date()

            let episode = Episode(
                id: UUID().uuidString,
                providerId: "podcast_feed",
                title: currentTitle,
                showId: nil,
                seasonId: nil,
                feedTitle: feedTitle,
                publishDate: pubDate,
                duration: 0, // Would need to be parsed from media:duration or similar
                audioUrl: currentAudioURL.isEmpty ? nil : currentAudioURL,
                description: currentDescription.isEmpty ? nil : currentDescription,
                image: feedImage.isEmpty ? nil : feedImage,
                titleOverride: nil
            )

            episodes.append(episode)

            // Reset
            currentTitle = ""
            currentDescription = ""
            currentAudioURL = ""
            currentPublishDate = ""
        }

        currentElement = ""
    }
}

// MARK: - Errors
enum PodcastParseError: LocalizedError {
    case invalidURL
    case parseError
    case invalidFeed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid feed URL"
        case .parseError:
            return "Failed to parse feed"
        case .invalidFeed:
            return "Invalid feed format"
        }
    }
}
