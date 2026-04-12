import Foundation

// MARK: - NPO Provider Implementation
class NPOProvider: ContentProvider {
    let id = "npo"
    let name = "NPO Radio"
    let type = ProviderType.radioNetwork
    let logo = "https://www.nporadio.nl/assets/logo.png"

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
                name: npoChannel.name,
                description: npoChannel.description,
                logo: npoChannel.logoURL
            )
        }
    }

    // MARK: - Programs Fetching
    func fetchPrograms(forChannel channelId: String) async throws -> [Program] {
        do {
            // Try to fetch from API first
            let npoPrograms = try await apiService.fetchPrograms(forChannel: channelId)

            return npoPrograms.map { npoProgram in
                Program(
                    id: npoProgram.id,
                    providerId: id,
                    title: npoProgram.title,
                    description: npoProgram.description,
                    presenters: npoProgram.presenters,
                    genre: npoProgram.genre,
                    channelId: channelId,
                    image: npoProgram.image
                )
            }
        } catch {
            // Fallback to mock data
            print("NPO API Error: \(error.localizedDescription)")
            let npoPrograms = mockDataService.getProgramsForChannel(channelId)

            return npoPrograms.map { npoProgram in
                Program(
                    id: npoProgram.id,
                    providerId: id,
                    title: npoProgram.title,
                    description: npoProgram.description,
                    presenters: npoProgram.presenters,
                    genre: npoProgram.genre,
                    channelId: channelId,
                    image: npoProgram.image
                )
            }
        }
    }

    // MARK: - Broadcasts Fetching
    func fetchBroadcasts(forProgram programId: String) async throws -> [Broadcast] {
        do {
            // Try to fetch from API first
            let npoBroadcasts = try await apiService.fetchBroadcasts(forProgram: programId)

            return npoBroadcasts.map { npoBroadcast in
                Broadcast(
                    id: npoBroadcast.id,
                    providerId: id,
                    title: npoBroadcast.title,
                    programId: programId,
                    startTime: npoBroadcast.startTime,
                    duration: npoBroadcast.duration,
                    description: npoBroadcast.description,
                    image: npoBroadcast.image,
                    audioUrl: npoBroadcast.audioUrl
                )
            }
        } catch {
            // Fallback to mock data
            print("NPO API Error: \(error.localizedDescription)")
            let npoBroadcasts = mockDataService.getBroadcastsForProgram(programId)

            return npoBroadcasts.map { npoBroadcast in
                Broadcast(
                    id: npoBroadcast.id,
                    providerId: id,
                    title: npoBroadcast.title,
                    programId: programId,
                    startTime: npoBroadcast.startTime,
                    duration: npoBroadcast.duration,
                    description: npoBroadcast.description,
                    image: npoBroadcast.image,
                    audioUrl: nil
                )
            }
        }
    }

    // MARK: - Search
    func search(_ query: String) async throws -> [AudioContent] {
        do {
            let npoPrograms = try await apiService.searchPrograms(query)

            return npoPrograms.map { npoProgram in
                Program(
                    id: npoProgram.id,
                    providerId: id,
                    title: npoProgram.title,
                    description: npoProgram.description,
                    presenters: npoProgram.presenters,
                    genre: npoProgram.genre,
                    channelId: npoProgram.channelId,
                    image: npoProgram.image
                )
            }
        } catch {
            print("NPO Search Error: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - NPOBroadcast Extension for Audio URL
extension NPOBroadcast {
    var audioUrl: String? {
        // NPO broadcasts typically have audio streams available
        // This would be populated from the API response
        return nil // Placeholder - actual implementation depends on NPO API
    }
}
