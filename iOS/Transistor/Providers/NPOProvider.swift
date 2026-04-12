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
