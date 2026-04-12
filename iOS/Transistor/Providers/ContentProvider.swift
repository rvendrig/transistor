import Foundation

// MARK: - Provider Protocol
protocol ContentProvider {
    var id: String { get }
    var name: String { get }
    var type: ProviderType { get }
    var logo: String? { get }

    func fetchChannels() async throws -> [Channel]
    func fetchPrograms(forChannel channelId: String) async throws -> [Program]
    func fetchBroadcasts(forProgram programId: String) async throws -> [Broadcast]
    func search(_ query: String) async throws -> [AudioContent]
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
    case broadcast = "broadcast"
    case episode = "episode"
    case stream = "stream"
    case track = "track"
}

// MARK: - Search Results
struct SearchResults: Codable {
    let programs: [Program]
    let broadcasts: [Broadcast]
    let episodes: [Episode]
}

// MARK: - Provider Store
class ProviderStore: ObservableObject {
    static let shared = ProviderStore()

    @Published var providers: [String: ContentProvider] = [:]
    @Published var activeProviders: Set<String> = []

    private init() {
        // Register built-in providers
        registerProvider(NPOProvider())
    }

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
