import Foundation

// NPO POMS Mapping -> Transistor Model
// -------------------------------------
// NPO (implicit)       -> Network
// Zender               -> Channel
// Programma (UMBRELLA) -> Show
// Seizoen (SEASON)     -> Season
// Uitzending (BROADCAST) -> Broadcast
// Item/Fragment        -> Segment
// Clip (CLIP)          -> Clip

// MARK: - NPO Provider Implementation
class NPOProvider: ContentProvider {
    let id = "npo"
    let name = "NPO Radio"
    let type = ProviderType.radioNetwork
    let logo: String? = "https://www.nporadio.nl/assets/logo.png"

    private let apiService = NPOAPIService.shared
    private let mockDataService = NPODataService.shared

    // swiftlint:disable:next identifier_name
    private let ams = TimeZone(identifier: "Europe/Amsterdam")!

    // MARK: - Channel Configs

    func channelConfigs() -> [ChannelConfig] {
        let fullCapabilities: Set<ChannelCapability> = [.liveStream, .schedule, .listenBack, .fragments, .tracks, .podcast]

        return [
            ChannelConfig(
                id: "radio1", name: "NPO Radio 1",
                description: "Nieuws, sport en achtergronden",
                networkId: "npo", logo: nil, timezone: ams,
                liveStreamUrl: "https://icecast.omroep.nl/radio1-bb-mp3",
                liveStreamFormat: .mp3, capabilities: fullCapabilities,
                broadcastsApiUrl: "https://www.nporadio1.nl/api/broadcasts",
                tracksApiUrl: "https://www.nporadio1.nl/api/tracks",
                listenBackBaseUrl: nil, podcastFeedUrl: nil
            ),
            ChannelConfig(
                id: "radio2", name: "NPO Radio 2",
                description: "Het beste van popmuziek",
                networkId: "npo", logo: nil, timezone: ams,
                liveStreamUrl: "https://icecast.omroep.nl/radio2-bb-mp3",
                liveStreamFormat: .mp3, capabilities: fullCapabilities,
                broadcastsApiUrl: "https://www.nporadio2.nl/api/broadcasts",
                tracksApiUrl: "https://www.nporadio2.nl/api/tracks",
                listenBackBaseUrl: nil, podcastFeedUrl: nil
            ),
            ChannelConfig(
                id: "3fm", name: "NPO 3FM",
                description: "De nieuwste muziek",
                networkId: "npo", logo: nil, timezone: ams,
                liveStreamUrl: "https://icecast.omroep.nl/3fm-bb-mp3",
                liveStreamFormat: .mp3, capabilities: fullCapabilities,
                broadcastsApiUrl: "https://www.npo3fm.nl/api/broadcasts",
                tracksApiUrl: "https://www.npo3fm.nl/api/tracks",
                listenBackBaseUrl: nil, podcastFeedUrl: nil
            ),
            ChannelConfig(
                id: "radio4", name: "NPO Klassiek",
                description: "Klassieke muziek",
                networkId: "npo", logo: nil, timezone: ams,
                liveStreamUrl: "https://icecast.omroep.nl/radio4-bb-mp3",
                liveStreamFormat: .mp3, capabilities: fullCapabilities,
                broadcastsApiUrl: "https://www.npoklassiek.nl/api/broadcasts",
                tracksApiUrl: "https://www.npoklassiek.nl/api/tracks",
                listenBackBaseUrl: nil, podcastFeedUrl: nil
            ),
            ChannelConfig(
                id: "radio5", name: "NPO Radio 5",
                description: "Muziek uit de jaren 60, 70 en 80",
                networkId: "npo", logo: nil, timezone: ams,
                liveStreamUrl: "https://icecast.omroep.nl/radio5-bb-mp3",
                liveStreamFormat: .mp3, capabilities: fullCapabilities,
                broadcastsApiUrl: "https://www.nporadio5.nl/api/broadcasts",
                tracksApiUrl: "https://www.nporadio5.nl/api/tracks",
                listenBackBaseUrl: nil, podcastFeedUrl: nil
            ),
            ChannelConfig(
                id: "funx", name: "FunX",
                description: "Urban, hiphop, R&B en dance",
                networkId: "npo", logo: nil, timezone: ams,
                liveStreamUrl: "https://icecast.omroep.nl/funx-bb-mp3",
                liveStreamFormat: .mp3, capabilities: fullCapabilities,
                broadcastsApiUrl: "https://www.funx.nl/api/broadcasts",
                tracksApiUrl: "https://www.funx.nl/api/tracks",
                listenBackBaseUrl: nil, podcastFeedUrl: nil
            ),
            ChannelConfig(
                id: "soulnjazz", name: "NPO Soul & Jazz",
                description: "Soul, jazz en funk",
                networkId: "npo", logo: nil, timezone: ams,
                liveStreamUrl: nil,
                liveStreamFormat: .mp3, capabilities: [.schedule],
                broadcastsApiUrl: nil,
                tracksApiUrl: nil,
                listenBackBaseUrl: nil, podcastFeedUrl: nil
            ),
        ]
    }

    // MARK: - Channel Fetching
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

    // MARK: - Shows Fetching
    func fetchShows(forChannel channelId: String) async throws -> [Show] {
        do {
            // Try to fetch from API first
            let npoPrograms = try await apiService.fetchPrograms(forChannel: channelId)

            return npoPrograms.map { npoProgram in
                Show(
                    id: npoProgram.id,
                    providerId: id,
                    titles: [TitledPeriod(title: npoProgram.title)],
                    description: npoProgram.description,
                    presenters: npoProgram.presenters,
                    genre: npoProgram.genre,
                    channelIds: channelId.isEmpty ? nil : [channelId],
                    image: npoProgram.image
                )
            }
        } catch {
            // Fallback to mock data
            print("NPO API Error: \(error.localizedDescription)")
            let npoPrograms = mockDataService.getProgramsForChannel(channelId)

            return npoPrograms.map { npoProgram in
                Show(
                    id: npoProgram.id,
                    providerId: id,
                    titles: [TitledPeriod(title: npoProgram.title)],
                    description: npoProgram.description,
                    presenters: npoProgram.presenters,
                    genre: npoProgram.genre,
                    channelIds: channelId.isEmpty ? nil : [channelId],
                    image: npoProgram.image
                )
            }
        }
    }

    // MARK: - Broadcasts by Channel (dagprogramma)
    func fetchBroadcasts(forChannel channelId: String) async throws -> [Broadcast] {
        let apiBroadcasts = try await apiService.fetchBroadcasts(forChannel: channelId)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        return apiBroadcasts.compactMap { api in
            guard let startTime = dateFormatter.date(from: api.startdatetime) else { return nil }
            let endTime = dateFormatter.date(from: api.stopdatetime) ?? startTime
            let duration = Int(endTime.timeIntervalSince(startTime))

            return Broadcast(
                id: "\(channelId)-\(api.startdatetime)",
                providerId: id,
                title: api.title,
                showId: nil,
                channelId: channelId,
                seasonId: nil,
                startTime: startTime,
                duration: duration,
                description: api.presenters,
                image: api.image_url_400x400 ?? api.image_url,
                audioUrl: NPOAPIService.streamURLs[channelId],
                titleOverride: nil
            )
        }.sorted { $0.startTime < $1.startTime }
    }

    // MARK: - Broadcasts by Show
    func fetchBroadcasts(forShow showId: String) async throws -> [Broadcast] {
        do {
            // Try to fetch from API first
            let npoBroadcasts = try await apiService.fetchBroadcasts(forProgram: showId)

            return npoBroadcasts.map { npoBroadcast in
                Broadcast(
                    id: npoBroadcast.id,
                    providerId: id,
                    title: npoBroadcast.title,
                    showId: showId,
                    channelId: nil,
                    seasonId: nil,
                    startTime: npoBroadcast.startTime,
                    duration: npoBroadcast.duration,
                    description: npoBroadcast.description,
                    image: npoBroadcast.image,
                    audioUrl: npoBroadcast.audioUrl,
                    titleOverride: nil
                )
            }
        } catch {
            // Fallback to mock data
            print("NPO API Error: \(error.localizedDescription)")
            let npoBroadcasts = mockDataService.getBroadcastsForProgram(showId)

            return npoBroadcasts.map { npoBroadcast in
                Broadcast(
                    id: npoBroadcast.id,
                    providerId: id,
                    title: npoBroadcast.title,
                    showId: showId,
                    channelId: nil,
                    seasonId: nil,
                    startTime: npoBroadcast.startTime,
                    duration: npoBroadcast.duration,
                    description: npoBroadcast.description,
                    image: npoBroadcast.image,
                    audioUrl: nil,
                    titleOverride: nil
                )
            }
        }
    }

    // MARK: - Audio URL Helpers

    /// Get live audio stream URL for a channel
    func getStreamURL(forChannel channelId: String) -> String {
        return NPOAPIService.streamURLs[channelId]
            ?? "https://icecast.omroep.nl/radio1-bb-mp3"
    }

    /// Enhance NPO broadcasts with audio URLs
    func enrichBroadcasts(_ broadcasts: [NPOBroadcast], channelId: String) -> [NPOBroadcast] {
        let audioURL = getStreamURL(forChannel: channelId)

        return broadcasts.map { broadcast in
            NPOBroadcast(
                id: broadcast.id,
                title: broadcast.title,
                programId: broadcast.programId,
                startTime: broadcast.startTime,
                duration: broadcast.duration,
                description: broadcast.description,
                image: broadcast.image,
                audioUrl: audioURL
            )
        }
    }

    /// Discover real NPO content channels and their stream URLs
    func getRealContent() -> [(channel: String, url: String)] {
        NPOAPIService.streamURLs.map { (key, value) in
            let name = NPODataService.shared.getAllChannels().first { $0.id == key }?.name ?? key
            return (name, value)
        }
    }

    // MARK: - Search
    func search(_ query: String) async throws -> [any AudioContent] {
        do {
            let npoBroadcasts = try await apiService.fetchBroadcasts(forProgram: query)

            return npoBroadcasts.map { npoBroadcast in
                Broadcast(
                    id: npoBroadcast.id,
                    providerId: id,
                    title: npoBroadcast.title,
                    showId: npoBroadcast.programId,
                    channelId: nil,
                    seasonId: nil,
                    startTime: npoBroadcast.startTime,
                    duration: npoBroadcast.duration,
                    description: npoBroadcast.description,
                    image: npoBroadcast.image,
                    audioUrl: nil,
                    titleOverride: nil
                )
            }
        } catch {
            print("NPO Search Error: \(error.localizedDescription)")
            return []
        }
    }
}
