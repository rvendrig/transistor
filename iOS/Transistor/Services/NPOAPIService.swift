import Foundation

class NPOAPIService {
    static let shared = NPOAPIService()

    // Per-station base URLs (Prepr CMS powered)
    static let stationURLs: [String: String] = [
        "radio1": "https://www.nporadio1.nl",
        "radio2": "https://www.nporadio2.nl",
        "3fm": "https://www.npo3fm.nl",
        "radio4": "https://www.npoklassiek.nl",
        "radio5": "https://www.nporadio5.nl",
        "funx": "https://www.funx.nl"
    ]

    // Live audio stream URLs (Icecast)
    static let streamURLs: [String: String] = [
        "radio1": "https://icecast.omroep.nl/radio1-bb-mp3",
        "radio2": "https://icecast.omroep.nl/radio2-bb-mp3",
        "3fm": "https://icecast.omroep.nl/3fm-bb-mp3",
        "radio4": "https://icecast.omroep.nl/radio4-bb-mp3",
        "radio5": "https://icecast.omroep.nl/radio5-bb-mp3",
        "funx": "https://icecast.omroep.nl/funx-bb-mp3"
    ]

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Transistor/1.0 (iOS)"
        ]
        self.session = URLSession(configuration: config)
    }

    // MARK: - Fetch Broadcasts (today's schedule for a channel)

    func fetchBroadcasts(forChannel channelId: String) async throws -> [NPOBroadcastAPI] {
        guard let baseURL = Self.stationURLs[channelId] else {
            throw NPOAPIError.invalidURL
        }

        guard let url = URL(string: "\(baseURL)/api/broadcasts") else {
            throw NPOAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NPOAPIError.invalidResponse
        }

        let apiResponse = try JSONDecoder().decode(NPOBroadcastsAPIResponse.self, from: data)
        return apiResponse.data
    }

    // MARK: - Fetch Tracks (currently/recently played)

    func fetchTracks(forChannel channelId: String) async throws -> [NPOTrackAPI] {
        guard let baseURL = Self.stationURLs[channelId] else {
            throw NPOAPIError.invalidURL
        }

        guard let url = URL(string: "\(baseURL)/api/tracks") else {
            throw NPOAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NPOAPIError.invalidResponse
        }

        let apiResponse = try JSONDecoder().decode(NPOTracksAPIResponse.self, from: data)
        return apiResponse.data
    }

    // MARK: - Fetch Broadcasts for all channels

    func fetchAllBroadcasts() async throws -> [String: [NPOBroadcastAPI]] {
        var result: [String: [NPOBroadcastAPI]] = [:]

        for channelId in Self.stationURLs.keys {
            do {
                let broadcasts = try await fetchBroadcasts(forChannel: channelId)
                result[channelId] = broadcasts
            } catch {
                print("Error fetching broadcasts for \(channelId): \(error)")
            }
        }

        return result
    }

    // MARK: - Legacy compatibility (used by NPOViewModel)

    func fetchPrograms(forChannel channelId: String) async throws -> [NPOProgram] {
        let broadcasts = try await fetchBroadcasts(forChannel: channelId)

        // Extract unique shows from broadcasts
        var seen = Set<String>()
        var programs: [NPOProgram] = []

        for broadcast in broadcasts {
            let title = broadcast.title
            if !seen.contains(title) {
                seen.insert(title)
                programs.append(NPOProgram(
                    id: title.lowercased().replacingOccurrences(of: " ", with: "-"),
                    title: title,
                    description: [broadcast.presenters, broadcast.broadcaster].compactMap { $0 }.joined(separator: " — "),
                    presenters: broadcast.presenters.map { [$0] } ?? [],
                    image: broadcast.image_url_400x400 ?? broadcast.image_url,
                    genre: nil,
                    channelId: channelId
                ))
            }
        }

        return programs
    }

    func fetchBroadcasts(forProgram programId: String) async throws -> [NPOBroadcast] {
        // programId is used as channelId in the new API since we fetch per channel
        // This is a compatibility shim — the real data comes from fetchBroadcasts(forChannel:)
        let channels = NPODataService.shared.getAllChannels()

        for channel in channels {
            do {
                let apiBroadcasts = try await fetchBroadcasts(forChannel: channel.id)
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                let fallbackFormatter = DateFormatter()
                fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

                let matching = apiBroadcasts.compactMap { api -> NPOBroadcast? in
                    let id = api.title.lowercased().replacingOccurrences(of: " ", with: "-")
                    guard id == programId || api.title == programId else { return nil }

                    let startTime = dateFormatter.date(from: api.startdatetime)
                        ?? fallbackFormatter.date(from: api.startdatetime)
                        ?? Date()
                    let endTime = dateFormatter.date(from: api.stopdatetime)
                        ?? fallbackFormatter.date(from: api.stopdatetime)
                        ?? startTime
                    let duration = Int(endTime.timeIntervalSince(startTime))

                    return NPOBroadcast(
                        id: "\(channel.id)-\(api.startdatetime)",
                        title: api.title,
                        programId: id,
                        startTime: startTime,
                        duration: duration,
                        description: api.presenters,
                        image: api.image_url_400x400 ?? api.image_url,
                        audioUrl: Self.streamURLs[channel.id]
                    )
                }

                if !matching.isEmpty {
                    return matching
                }
            } catch {
                continue
            }
        }

        return []
    }

    func searchPrograms(_ query: String) async throws -> [NPOProgram] {
        // Search across all channels' broadcasts
        var results: [NPOProgram] = []
        let lowercaseQuery = query.lowercased()

        for channelId in Self.stationURLs.keys {
            do {
                let broadcasts = try await fetchBroadcasts(forChannel: channelId)
                for broadcast in broadcasts {
                    if broadcast.title.lowercased().contains(lowercaseQuery) ||
                       (broadcast.presenters?.lowercased().contains(lowercaseQuery) ?? false) {
                        results.append(NPOProgram(
                            id: broadcast.title.lowercased().replacingOccurrences(of: " ", with: "-"),
                            title: broadcast.title,
                            description: [broadcast.presenters, broadcast.broadcaster].compactMap { $0 }.joined(separator: " — "),
                            presenters: broadcast.presenters.map { [$0] } ?? [],
                            image: broadcast.image_url_400x400 ?? broadcast.image_url,
                            genre: nil,
                            channelId: channelId
                        ))
                    }
                }
            } catch {
                continue
            }
        }

        return results
    }

    func fetchAllPrograms() async throws -> [NPOProgram] {
        var allPrograms: [NPOProgram] = []

        for channelId in Self.stationURLs.keys {
            do {
                let programs = try await fetchPrograms(forChannel: channelId)
                allPrograms.append(contentsOf: programs)
            } catch {
                print("Error fetching programs for \(channelId): \(error)")
            }
        }

        return allPrograms
    }
}

// MARK: - API Response Models

struct NPOBroadcastsAPIResponse: Codable {
    let data: [NPOBroadcastAPI]
    let success: Bool?
}

struct NPOBroadcastAPI: Codable {
    let title: String
    let presenters: String?
    let broadcaster: String?
    let startdatetime: String
    let stopdatetime: String
    let image: String?
    let image_url: String?
    let image_url_400x400: String?
}

struct NPOTracksAPIResponse: Codable {
    let data: [NPOTrackAPI]
    let success: Bool?
}

struct NPOTrackAPI: Codable {
    let artist: String?
    let title: String?
    let startdatetime: String?
    let enddatetime: String?
    let image_url_200x200: String?
    let spotify_url: String?
}

// MARK: - Error Handling

enum NPOAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .decodingError(let error): return "Failed to decode: \(error.localizedDescription)"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        }
    }
}
