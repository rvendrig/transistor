import Foundation

// MARK: - Generic Channel
struct Channel: Identifiable, Codable {
    let id: String
    let providerId: String
    let name: String
    let description: String
    let logo: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case providerId = "provider_id"
        case logo = "logo_url"
    }

    /// Unique key combining provider and channel ID
    var uniqueKey: String {
        "\(providerId):\(id)"
    }
}

// MARK: - Generic Program (Series)
struct Program: Identifiable, Codable {
    let id: String
    let providerId: String
    let title: String
    let description: String
    let presenters: [String]
    let genre: String?
    let channelId: String?
    let image: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, presenters, genre, image
        case providerId = "provider_id"
        case channelId = "channel_id"
    }

    var uniqueKey: String {
        "\(providerId):\(id)"
    }
}

// MARK: - Generic Broadcast (Radio/TV episode)
struct Broadcast: Identifiable, Codable, AudioContent {
    let id: String
    let providerId: String
    let title: String
    let programId: String?
    let startTime: Date
    let duration: Int // in seconds
    let description: String?
    let image: String?
    let audioUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, image, duration
        case providerId = "provider_id"
        case programId = "program_id"
        case startTime = "start_time"
        case audioUrl = "audio_url"
    }

    // AudioContent conformance
    var publishDate: Date { startTime }
    var contentType: ContentType { .broadcast }

    var uniqueKey: String {
        "\(providerId):\(id)"
    }
}

// MARK: - Generic Episode (Podcast)
struct Episode: Identifiable, Codable, AudioContent {
    let id: String
    let providerId: String
    let title: String
    let feedId: String?
    let feedTitle: String?
    let publishDate: Date
    let duration: Int // in seconds
    let audioUrl: String?
    let description: String?
    let image: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, image, duration, feedTitle
        case providerId = "provider_id"
        case feedId = "feed_id"
        case publishDate = "publish_date"
        case audioUrl = "audio_url"
    }

    // AudioContent conformance
    var contentType: ContentType { .episode }

    var uniqueKey: String {
        "\(providerId):\(id)"
    }
}

// MARK: - Generic Marker
struct Marker: Identifiable, Codable {
    let id: String
    let contentId: String
    let contentType: ContentType
    let providerId: String
    let timestamp: Int // offset from start in seconds
    let tags: [String]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, timestamp, tags
        case contentId = "content_id"
        case contentType = "content_type"
        case providerId = "provider_id"
        case createdAt = "created_at"
    }

    var uniqueKey: String {
        "\(providerId):\(contentId):\(timestamp)"
    }
}

// MARK: - Generic Favorite
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

    var uniqueKey: String {
        "\(providerId):\(contentId)"
    }
}

// MARK: - Update Playlist Models for Provider Support
struct PlaylistItem: Identifiable, Codable {
    let id: String
    let playlistId: String
    let itemId: String
    let itemType: PlaylistItemType
    let contentType: ContentType?
    let broadcastId: String?
    let programId: String?
    let providerId: String?
    let position: Int
    let addedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, position
        case playlistId = "playlist_id"
        case itemId = "item_id"
        case itemType = "item_type"
        case contentType = "content_type"
        case broadcastId = "broadcast_id"
        case programId = "program_id"
        case providerId = "provider_id"
        case addedAt = "added_at"
    }
}

enum PlaylistItemType: String, Codable {
    case npoItem = "npo_item"
    case npoBroadcast = "npo_broadcast"
    case npoProgram = "npo_program"
    case episode = "episode"
    case podcast = "podcast"
}

// MARK: - Listening Session (for logging and history)
struct ListeningSession: Identifiable, Codable {
    let id: String
    let contentId: String
    let contentType: ContentType
    let providerId: String
    let title: String
    let source: String
    let startTime: Date
    var endTime: Date?
    let duration: Int // total duration in seconds
    var progress: Int // in seconds
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

    // Computed properties
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

// MARK: - Content Category for Listening History
enum ContentCategory: String, Codable, CaseIterable {
    case news
    case music
    case interview
    case sports
    case education
    case entertainment
    case podcast
    case documentary
    case comedy
    case other

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
    let programs: [Program]
    let broadcasts: [Broadcast]
    let episodes: [Episode]

    var totalResults: Int {
        programs.count + broadcasts.count + episodes.count
    }
}
