import Foundation

// Talpa Network Mapping → Transistor Model
// ──────────────────────────────────────
// Talpa              → Network
// Station            → Channel
// (no programme data available via public API)

class TalpaProvider: ContentProvider {
    let id = "talpa"
    let name = "Talpa Radio"
    let type = ProviderType.radioNetwork
    let logo: String? = nil

    // swiftlint:disable:next identifier_name
    private let ams = TimeZone(identifier: "Europe/Amsterdam")!

    // MARK: - Channel Configs

    func channelConfigs() -> [ChannelConfig] {
        let caps: Set<ChannelCapability> = [.liveStream]

        return [
            ChannelConfig(
                id: "radio538", name: "Radio 538",
                description: "Hits en entertainment",
                networkId: "talpa", logo: nil, timezone: ams,
                liveStreamUrl: "https://22593.live.streamtheworld.com/RADIO538.mp3",
                liveStreamFormat: .mp3, capabilities: caps,
                broadcastsApiUrl: nil, tracksApiUrl: nil,
                listenBackBaseUrl: nil, podcastFeedUrl: nil
            ),
            ChannelConfig(
                id: "skyradio", name: "Sky Radio",
                description: "Feel good hits",
                networkId: "talpa", logo: nil, timezone: ams,
                liveStreamUrl: "https://22593.live.streamtheworld.com/SKYRADIO.mp3",
                liveStreamFormat: .mp3, capabilities: caps,
                broadcastsApiUrl: nil, tracksApiUrl: nil,
                listenBackBaseUrl: nil, podcastFeedUrl: nil
            ),
            ChannelConfig(
                id: "radio10", name: "Radio 10",
                description: "De grootste hits aller tijden",
                networkId: "talpa", logo: nil, timezone: ams,
                liveStreamUrl: "https://22593.live.streamtheworld.com/RADIO10.mp3",
                liveStreamFormat: .mp3, capabilities: caps,
                broadcastsApiUrl: nil, tracksApiUrl: nil,
                listenBackBaseUrl: nil, podcastFeedUrl: nil
            ),
            ChannelConfig(
                id: "veronica", name: "Radio Veronica",
                description: "Rock classics",
                networkId: "talpa", logo: nil, timezone: ams,
                liveStreamUrl: "https://25343.live.streamtheworld.com/VERONICA.mp3",
                liveStreamFormat: .mp3, capabilities: caps,
                broadcastsApiUrl: nil, tracksApiUrl: nil,
                listenBackBaseUrl: nil, podcastFeedUrl: nil
            ),
            ChannelConfig(
                id: "slam", name: "SLAM!",
                description: "Dance en urban hits",
                networkId: "talpa", logo: nil, timezone: ams,
                liveStreamUrl: "https://stream.slam.nl/slam_mp3",
                liveStreamFormat: .mp3, capabilities: caps,
                broadcastsApiUrl: nil, tracksApiUrl: nil,
                listenBackBaseUrl: nil, podcastFeedUrl: nil
            ),
        ]
    }

    // MARK: - ContentProvider

    func fetchChannels() async throws -> [Channel] {
        return channelConfigs().map { config in
            Channel(
                id: config.id,
                providerId: id,
                networkId: config.networkId,
                titles: [TitledPeriod(title: config.name)],
                description: config.description,
                logo: config.logo
            )
        }
    }

    func fetchShows(forChannel channelId: String) async throws -> [Show] {
        []
    }

    func fetchBroadcasts(forShow showId: String) async throws -> [Broadcast] {
        []
    }

    func search(_ query: String) async throws -> [any AudioContent] {
        []
    }
}
