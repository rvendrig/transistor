import Foundation

// MARK: - NPO Channel Model
struct NPOChannel: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let logoURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case logoURL = "logo_url"
    }
}

// MARK: - NPO Program Model
struct NPOProgram: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let presenters: [String]
    let image: String?
    let genre: String?
    let channelId: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, presenters, image, genre
        case channelId = "channel_id"
    }
}

// MARK: - NPO Broadcast Model
struct NPOBroadcast: Identifiable, Codable {
    let id: String
    let title: String
    let programId: String
    let startTime: Date
    let duration: Int // in seconds
    let description: String?
    let image: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, image, duration
        case programId = "program_id"
        case startTime = "start_time"
    }
}

// MARK: - NPO Item Model
struct NPOItem: Identifiable, Codable {
    let id: String
    let broadcastId: String
    let title: String
    let description: String?
    let type: ItemType
    let duration: Int // in seconds
    let guests: [String]
    let topics: [String]
    let startOffset: Int? // offset from broadcast start in seconds

    enum ItemType: String, Codable {
        case interview
        case music
        case news
        case report
        case segment
        case topic
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, type, duration, guests, topics
        case broadcastId = "broadcast_id"
        case startOffset = "start_offset"
    }
}

// MARK: - Supporting Models
struct Presenter: Identifiable, Codable {
    let id: String
    let name: String
    let bio: String?
}

struct Guest: Identifiable, Codable {
    let id: String
    let name: String
    let role: String?
}

struct Music: Codable {
    let artist: String
    let title: String
    let duration: Int
}

struct PodcastFeed: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let feedURL: String
    let image: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, image
        case feedURL = "feed_url"
    }
}

struct PodcastEpisode: Identifiable, Codable {
    let id: String
    let feedId: String
    let title: String
    let description: String
    let pubDate: Date
    let duration: Int
    let audioURL: String
    let image: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, duration, image
        case feedId = "feed_id"
        case pubDate = "pub_date"
        case audioURL = "audio_url"
    }
}

// MARK: - Search and Filter Models
struct SearchFilter {
    var query: String = ""
    var channelId: String? = nil
    var genre: String? = nil
}

struct Subscription: Identifiable, Codable {
    let id: String
    let userId: String?
    let programId: String
    let subscribedAt: Date
}

// MARK: - Playlist Models
struct Playlist: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let createdAt: Date
    let itemCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case createdAt = "created_at"
        case itemCount = "item_count"
    }
}

struct PlaylistItem: Identifiable, Codable {
    let id: String
    let playlistId: String
    let itemId: String
    let itemType: PlaylistItemType
    let broadcastId: String?
    let programId: String?
    let position: Int
    let addedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, position
        case playlistId = "playlist_id"
        case itemId = "item_id"
        case itemType = "item_type"
        case broadcastId = "broadcast_id"
        case programId = "program_id"
        case addedAt = "added_at"
    }
}

enum PlaylistItemType: String, Codable {
    case npoItem = "npo_item"
    case npoBroadcast = "npo_broadcast"
    case npoProgram = "npo_program"
}

// Note: Generic Marker and Favorite models are now in GenericModels.swift
// These replace the NPO-specific versions for provider-agnostic support
