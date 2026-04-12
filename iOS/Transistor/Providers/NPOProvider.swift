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

    // MARK: - Channel Fetching
    func fetchChannels() async throws -> [Channel] {
        // Use existing mock data for channels
        let npoChannels = mockDataService.getAllChannels()

        return npoChannels.map { npoChannel in
            Channel(
                id: npoChannel.id,
                providerId: id,
                networkId: "npo",
                titles: [TitledPeriod(title: npoChannel.name)],
                description: npoChannel.description,
                logo: npoChannel.logoURL
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

    // MARK: - Broadcasts Fetching
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

    /// Get audio URL for an NPO broadcast
    func getAudioURL(channelId: String) -> String {
        return "https://www.nporadio.nl/live/\(channelId)/index.m3u8"
    }

    /// Get NPO channel audio stream URL
    func getStreamURL(forChannel channelId: String) -> String {
        let streamMapping: [String: String] = [
            "radio1": "https://www.nporadio.nl/live/npo-radio-1/index.m3u8",
            "radio2": "https://www.nporadio.nl/live/npo-radio-2/index.m3u8",
            "3fm": "https://www.nporadio.nl/live/npo-3fm/index.m3u8",
            "radio4": "https://www.nporadio.nl/live/npo-radio-4/index.m3u8",
            "radio5": "https://www.nporadio.nl/live/npo-radio-5/index.m3u8",
            "radio6": "https://www.nporadio.nl/live/npo-radio-6/index.m3u8"
        ]
        return streamMapping[channelId] ?? "https://www.nporadio.nl/live/npo-radio-1/index.m3u8"
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
        return [
            ("NPO Radio 1", "https://www.nporadio.nl/live/npo-radio-1/index.m3u8"),
            ("NPO Radio 2", "https://www.nporadio.nl/live/npo-radio-2/index.m3u8"),
            ("NPO 3FM", "https://www.nporadio.nl/live/npo-3fm/index.m3u8"),
            ("NPO Radio 4", "https://www.nporadio.nl/live/npo-radio-4/index.m3u8"),
            ("NPO Radio 5", "https://www.nporadio.nl/live/npo-radio-5/index.m3u8"),
            ("NPO Radio 6", "https://www.nporadio.nl/live/npo-radio-6/index.m3u8")
        ]
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
