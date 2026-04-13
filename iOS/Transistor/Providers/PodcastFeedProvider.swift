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
    private var currentDuration = ""
    private var currentEpisodeNumber = ""
    private var currentSeasonNumber = ""
    private var currentEpisodeType = ""
    private var currentImageUrl = ""
    private var episodes: [Episode] = []
    private var feedTitle = ""
    private var feedDescription = ""
    private var feedImage = ""
    private var insideItem = false
    private var insideChannel = true
    private var episodeCounter = 0

    // RFC 2822 date formats used by RSS feeds
    private static let dateFormatters: [DateFormatter] = {
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",      // Sat, 11 Apr 2026 15:45:00 +0200
            "EEE, dd MMM yyyy HH:mm:ss zzz",     // Sat, 11 Apr 2026 15:45:00 CEST
            "EEE, d MMM yyyy HH:mm:ss Z",        // Sat, 1 Apr 2026 15:45:00 +0200
            "dd MMM yyyy HH:mm:ss Z",             // 11 Apr 2026 15:45:00 +0200
            "yyyy-MM-dd'T'HH:mm:ssZ",             // ISO 8601 fallback
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        ]
        return formats.map { format in
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = format
            return f
        }
    }()

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

    private func parseDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        for formatter in Self.dateFormatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }

    private func parseDuration(_ string: String) -> Int {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        // Format: HH:MM:SS or MM:SS or just seconds
        let parts = trimmed.components(separatedBy: ":")
        switch parts.count {
        case 3: // HH:MM:SS
            let h = Int(parts[0]) ?? 0
            let m = Int(parts[1]) ?? 0
            let s = Int(parts[2]) ?? 0
            return h * 3600 + m * 60 + s
        case 2: // MM:SS
            let m = Int(parts[0]) ?? 0
            let s = Int(parts[1]) ?? 0
            return m * 60 + s
        case 1: // seconds
            return Int(parts[0]) ?? 0
        default:
            return 0
        }
    }

    // MARK: - XMLParserDelegate
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName

        if elementName == "item" {
            insideItem = true
            insideChannel = false
        }

        if elementName == "enclosure" {
            currentAudioURL = attributeDict["url"] ?? ""
        }

        // itunes:image can be on channel or item level
        if elementName == "itunes:image" {
            let href = attributeDict["href"] ?? ""
            if insideItem {
                currentImageUrl = href
            } else {
                feedImage = href
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title":
            if insideItem { currentTitle += string } else { feedTitle += string }
        case "description":
            if insideItem { currentDescription += string } else { feedDescription += string }
        case "pubDate":
            currentPublishDate += string
        case "itunes:duration":
            currentDuration += string
        case "itunes:episode":
            currentEpisodeNumber += string
        case "itunes:season":
            currentSeasonNumber += string
        case "itunes:episodeType":
            currentEpisodeType += string
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            episodeCounter += 1

            let pubDate = parseDate(currentPublishDate) ?? Date.distantPast
            let duration = parseDuration(currentDuration)

            // Build title with episode number if available
            let epNum = Int(currentEpisodeNumber.trimmingCharacters(in: .whitespacesAndNewlines))
            let seasonNum = Int(currentSeasonNumber.trimmingCharacters(in: .whitespacesAndNewlines))

            var displayTitle = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            // Prefix with S01E03 style if numbers present but not already in title
            if let s = seasonNum, let e = epNum, !displayTitle.contains("S\(s)") {
                displayTitle = "S\(s)E\(e): \(displayTitle)"
            } else if let e = epNum, !displayTitle.contains("#\(e)") && !displayTitle.contains("Ep \(e)") {
                displayTitle = "#\(e): \(displayTitle)"
            }

            let episode = Episode(
                id: UUID().uuidString,
                providerId: "podcast_feed",
                title: displayTitle,
                showId: nil,
                seasonId: seasonNum.map { "season-\($0)" },
                feedTitle: feedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                publishDate: pubDate,
                duration: duration,
                audioUrl: currentAudioURL.isEmpty ? nil : currentAudioURL,
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                image: currentImageUrl.isEmpty ? (feedImage.isEmpty ? nil : feedImage) : currentImageUrl,
                titleOverride: nil
            )

            episodes.append(episode)

            // Reset item fields
            currentTitle = ""
            currentDescription = ""
            currentAudioURL = ""
            currentPublishDate = ""
            currentDuration = ""
            currentEpisodeNumber = ""
            currentSeasonNumber = ""
            currentEpisodeType = ""
            currentImageUrl = ""
            insideItem = false
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
