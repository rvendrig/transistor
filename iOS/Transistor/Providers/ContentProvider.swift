import Foundation

// MARK: - Provider Protocol

protocol ContentProvider {
    var id: String { get }
    var name: String { get }
    var type: ProviderType { get }
    var logo: String? { get }

    func fetchNetworks() async throws -> [Network]
    func fetchChannels() async throws -> [Channel]
    func fetchShows(forChannel channelId: String) async throws -> [Show]
    func fetchSeasons(forShow showId: String) async throws -> [Season]
    func fetchBroadcasts(forShow showId: String) async throws -> [Broadcast]
    func fetchBroadcasts(forChannel channelId: String) async throws -> [Broadcast]
    func fetchSegments(forBroadcast broadcastId: String) async throws -> [Segment]
    func search(_ query: String) async throws -> [any AudioContent]
}

// Default implementations — not every provider has every level
extension ContentProvider {
    func fetchNetworks() async throws -> [Network] { [] }
    func fetchSeasons(forShow showId: String) async throws -> [Season] { [] }
    func fetchBroadcasts(forChannel channelId: String) async throws -> [Broadcast] { [] }
    func fetchSegments(forBroadcast broadcastId: String) async throws -> [Segment] { [] }
}

// MARK: - Provider Types

enum ProviderType: String, Codable {
    case radioNetwork = "radio_network"
    case podcastPlatform = "podcast_platform"
    case broadcaster = "broadcaster"
    case custom = "custom"
}

// MARK: - Audio Content Protocol

protocol AudioContent: Identifiable, Codable {
    var id: String { get }
    var providerId: String { get }
    var title: String { get }
    var duration: Int { get }
    var audioUrl: String? { get }
    var publishDate: Date { get }
    var description: String? { get }
    var image: String? { get }
    var contentType: ContentType { get }
}

// MARK: - Content Types

enum ContentType: String, Codable {
    case broadcast
    case episode
    case segment
    case clip
    case stream
}

// MARK: - Provider Store

class ProviderStore: ObservableObject {
    static let shared = ProviderStore()

    @Published var providers: [String: ContentProvider] = [:]
    @Published var activeProviders: Set<String> = []

    private init() {}

    func registerProvider(_ provider: ContentProvider) {
        providers[provider.id] = provider
        activeProviders.insert(provider.id)
    }

    func provider(byId id: String) -> ContentProvider? {
        return providers[id]
    }

    func allActiveProviders() -> [ContentProvider] {
        activeProviders.compactMap { providers[$0] }
    }

    func setProviderActive(_ id: String, _ active: Bool) {
        if active {
            activeProviders.insert(id)
        } else {
            activeProviders.remove(id)
        }
    }
}
