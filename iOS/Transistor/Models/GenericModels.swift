import Foundation

// MARK: - Titled Period (tijdgebonden naamgeving)

struct TitledPeriod: Codable {
    let title: String
    let from: Date?         // nil = altijd geldig geweest
    let until: Date?        // nil = nog steeds geldig (= huidige naam)
    let isOfficial: Bool    // true = officiële naam, false = bijnaam/variant

    init(title: String, from: Date? = nil, until: Date? = nil, isOfficial: Bool = true) {
        self.title = title
        self.from = from
        self.until = until
        self.isOfficial = isOfficial
    }
}

// MARK: - Titled Protocol

protocol Titled {
    var titles: [TitledPeriod] { get }
    var currentTitle: String { get }
}

extension Titled {
    var currentTitle: String {
        titles.first(where: { $0.until == nil })?.title
            ?? titles.last?.title ?? ""
    }

    func title(at date: Date) -> String {
        titles.first(where: {
            ($0.from ?? .distantPast) <= date && date <= ($0.until ?? .distantFuture)
        })?.title ?? currentTitle
    }
}

// MARK: - Network (boeket: NPO, BBC, ...)

struct Network: Identifiable, Codable, Titled {
    let id: String
    let providerId: String
    let titles: [TitledPeriod]
    let description: String
    let logo: String?

    var currentTitle: String {
        titles.first(where: { $0.until == nil })?.title
            ?? titles.last?.title ?? ""
    }
}

// MARK: - Channel (zender/station binnen een network)

struct Channel: Identifiable, Codable, Titled, Hashable {
    static func == (lhs: Channel, rhs: Channel) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: String
    let providerId: String
    let networkId: String
    let titles: [TitledPeriod]
    let description: String
    let logo: String?

    var currentTitle: String {
        titles.first(where: { $0.until == nil })?.title
            ?? titles.last?.title ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case id, description, logo, titles
        case providerId = "provider_id"
        case networkId = "network_id"
    }
}

// MARK: - Show (programma/podcast — onafhankelijk van channel)

struct Show: Identifiable, Codable, Titled, Hashable {
    static func == (lhs: Show, rhs: Show) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: String
    let providerId: String
    let titles: [TitledPeriod]
    let description: String
    let presenters: [String]
    let genre: String?
    let channelIds: [String]?
    let image: String?

    var currentTitle: String {
        titles.first(where: { $0.until == nil })?.title
            ?? titles.last?.title ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case id, description, presenters, genre, image, titles
        case providerId = "provider_id"
        case channelIds = "channel_ids"
    }
}

// MARK: - Season (seizoen binnen een show)

struct Season: Identifiable, Codable, Titled {
    let id: String
    let providerId: String
    let showId: String
    let titles: [TitledPeriod]
    let seasonNumber: Int?
    let description: String?

    var currentTitle: String {
        titles.first(where: { $0.until == nil })?.title
            ?? titles.last?.title ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case id, titles, description
        case providerId = "provider_id"
        case showId = "show_id"
        case seasonNumber = "season_number"
    }
}

// MARK: - Broadcast (uitzending = show + channel + tijdstip)

struct Broadcast: Identifiable, Codable, AudioContent, Hashable {
    static func == (lhs: Broadcast, rhs: Broadcast) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: String
    let providerId: String
    let title: String
    let showId: String?
    let channelId: String?
    let seasonId: String?
    let startTime: Date
    let duration: Int
    let description: String?
    let image: String?
    let audioUrl: String?
    let titleOverride: String?
    let detailUrl: String?

    var displayTitle: String {
        titleOverride ?? title
    }

    // AudioContent conformance
    var publishDate: Date { startTime }
    var contentType: ContentType { .broadcast }

    enum CodingKeys: String, CodingKey {
        case id, title, description, image, duration
        case providerId = "provider_id"
        case showId = "show_id"
        case channelId = "channel_id"
        case seasonId = "season_id"
        case startTime = "start_time"
        case audioUrl = "audio_url"
        case titleOverride = "title_override"
        case detailUrl = "detail_url"
    }
}

// MARK: - Episode (aflevering = show + publicatiedatum, podcast)

struct Episode: Identifiable, Codable, AudioContent {
    let id: String
    let providerId: String
    let title: String
    let showId: String?
    let seasonId: String?
    let feedTitle: String?
    let publishDate: Date
    let duration: Int
    let audioUrl: String?
    let description: String?
    let image: String?
    let titleOverride: String?

    var displayTitle: String {
        titleOverride ?? title
    }

    // AudioContent conformance
    var contentType: ContentType { .episode }

    enum CodingKeys: String, CodingKey {
        case id, title, description, image, duration, feedTitle
        case providerId = "provider_id"
        case showId = "show_id"
        case seasonId = "season_id"
        case publishDate = "publish_date"
        case audioUrl = "audio_url"
        case titleOverride = "title_override"
    }
}

// MARK: - Segment (structureel format-onderdeel: interview, nieuwsblok, muziek)

struct Segment: Identifiable, Codable {
    let id: String
    let providerId: String
    let parentId: String
    let parentType: ContentType
    let title: String
    let description: String?
    let startOffset: Int
    let duration: Int
    let segmentType: SegmentType
    let persons: [String]
    let topics: [String]
    let image: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, duration, persons, topics, image
        case providerId = "provider_id"
        case parentId = "parent_id"
        case parentType = "parent_type"
        case startOffset = "start_offset"
        case segmentType = "segment_type"
    }
}

enum SegmentType: String, Codable {
    case interview
    case music
    case news
    case report
    case chapter
    case discussion
    case other
}

// MARK: - Clip (willekeurig gekozen fragment, onafhankelijk adresseerbaar)

struct Clip: Identifiable, Codable {
    let id: String
    let providerId: String
    let sourceId: String
    let sourceType: ContentType
    let title: String
    let description: String?
    let startOffset: Int
    let duration: Int
    let audioUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, duration
        case providerId = "provider_id"
        case sourceId = "source_id"
        case sourceType = "source_type"
        case startOffset = "start_offset"
        case audioUrl = "audio_url"
    }
}

// MARK: - Marker (gebruiker-geplaatst tijdstip)

struct Marker: Identifiable, Codable {
    let id: String
    let contentId: String
    let contentType: ContentType
    let providerId: String
    let timestamp: Int
    let tags: [String]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, timestamp, tags
        case contentId = "content_id"
        case contentType = "content_type"
        case providerId = "provider_id"
        case createdAt = "created_at"
    }
}

// MARK: - Favorite

struct Favorite: Identifiable, Codable {
    let id: String
    let contentId: String
    let contentType: ContentType
    let providerId: String
    let addedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contentId = "content_id"
        case contentType = "content_type"
        case providerId = "provider_id"
        case addedAt = "added_at"
    }
}

// MARK: - Playlist Item

struct PlaylistItem: Identifiable, Codable {
    let id: String
    let playlistId: String
    let itemId: String
    let itemType: PlaylistItemType
    let contentType: ContentType?
    let showId: String?
    let providerId: String?
    let position: Int
    let addedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, position
        case playlistId = "playlist_id"
        case itemId = "item_id"
        case itemType = "item_type"
        case contentType = "content_type"
        case showId = "show_id"
        case providerId = "provider_id"
        case addedAt = "added_at"
    }
}

enum PlaylistItemType: String, Codable {
    case show
    case broadcast
    case episode
    case segment
    case clip
}

// MARK: - Listening Session

struct ListeningSession: Identifiable, Codable {
    let id: String
    let contentId: String
    let contentType: ContentType
    let providerId: String
    let title: String
    let source: String
    let startTime: Date
    var endTime: Date?
    let duration: Int
    var progress: Int
    let categories: [ContentCategory]
    let topics: [String]
    let guests: [String]
    let artists: [String]
    var notes: String?
    var isFavorited: Bool
    let markerCount: Int

    enum CodingKeys: String, CodingKey {
        case id, title, source, duration, progress, categories, topics, guests, artists, notes
        case contentId = "content_id"
        case contentType = "content_type"
        case providerId = "provider_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case isFavorited = "is_favorited"
        case markerCount = "marker_count"
    }

    var percentage: Int {
        guard duration > 0 else { return 0 }
        return Int((Double(progress) / Double(duration)) * 100)
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(startTime)
        let minutes = Int(interval / 60)
        let hours = minutes / 60
        let days = hours / 24

        if days > 0 {
            return "\(days) day\(days > 1 ? "s" : "") ago"
        } else if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        } else if minutes > 0 {
            return "\(minutes) minute\(minutes > 1 ? "s" : "") ago"
        } else {
            return "just now"
        }
    }
}

// MARK: - Content Category

enum ContentCategory: String, Codable, CaseIterable {
    case news, music, interview, sports, education
    case entertainment, podcast, documentary, comedy, other

    var displayName: String {
        switch self {
        case .news: return "News"
        case .music: return "Music"
        case .interview: return "Interview"
        case .sports: return "Sports"
        case .education: return "Education"
        case .entertainment: return "Entertainment"
        case .podcast: return "Podcast"
        case .documentary: return "Documentary"
        case .comedy: return "Comedy"
        case .other: return "Other"
        }
    }
}

// MARK: - Unified Search Result

struct UnifiedSearchResult: Codable {
    let shows: [Show]
    let broadcasts: [Broadcast]
    let episodes: [Episode]

    var totalResults: Int {
        shows.count + broadcasts.count + episodes.count
    }
}
