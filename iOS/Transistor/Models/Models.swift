import Foundation

// MARK: - NPO Models

struct NPOChannel: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let imageURL: URL?
    let streamURL: URL?
}

struct NPOProgram: Identifiable, Codable {
    let id: String
    let channelId: String
    let title: String
    let description: String
    let imageURL: URL?
    let presenters: [String]
    let genres: [String]
}

struct NPOBroadcast: Identifiable, Codable {
    let id: String
    let programId: String
    let title: String
    let description: String?
    let startTime: Date
    let endTime: Date?
    let duration: Int // seconds
    let audioURL: URL?
    let imageURL: URL?
    let broadcasterName: String
    let presenters: [Presenter]
    let guests: [Guest]
    let topics: [String]
    let musicPlayed: [Music]
    var isFavorite: Bool = false
}

struct NPOItem: Identifiable, Codable {
    enum ItemType: String, Codable {
        case interview
        case music
        case news
        case report
        case segment
        case topic
    }

    let id: String
    let broadcastId: String
    let title: String
    let description: String?
    let type: ItemType
    let startTime: Int // seconds from broadcast start
    let duration: Int // seconds
    let guests: [String]?
    let topics: [String]?
    let artist: String? // for music
    let musicTitle: String? // for music
    let imageURL: URL?
    let teaserText: String?
}

struct Presenter: Identifiable, Codable {
    let id: String
    let name: String
    let bio: String?
    let imageURL: URL?
}

struct Guest: Identifiable, Codable {
    let id = UUID()
    let name: String
    let role: String?
    let affiliation: String?
}

struct Music: Identifiable, Codable {
    let id = UUID()
    let title: String
    let artist: String
    let timestamp: Int
}

// MARK: - Podcast Models

struct PodcastFeed: Identifiable, Codable {
    let id: String
    let url: URL
    let title: String
    let description: String
    let imageURL: URL?
    let author: String?
    let category: String?
    let createdAt: Date
    let lastFetched: Date
}

struct PodcastEpisode: Identifiable, Codable {
    let id: String
    let feedId: String
    let title: String
    let description: String
    let content: String?
    let audioURL: URL
    let imageURL: URL?
    let duration: Int?
    let pubDate: Date
    let guid: String
    let guests: [String]?
    let tags: [String]?
    let explicit: Bool = false
}

// MARK: - App Models

struct Subscription: Identifiable, Codable {
    let id = UUID()
    let feedId: String
    let subscribedAt: Date
    let lastEpisodeRead: Date?
}

struct SearchFilter {
    var query: String = ""
    var category: String?
    var guests: [String] = []
    var tags: [String] = []
    var fromDate: Date?
    var toDate: Date?
}
