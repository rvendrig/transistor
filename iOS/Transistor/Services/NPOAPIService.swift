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

    // MARK: - Resolve listen-back URL
    // entry.cdn.npoaudio.nl returns JSON with a redirect URL, not audio directly.
    // This resolves the redirect to the actual streamable MP3 URL.

    func resolveListenBackURL(_ entryUrl: String) async throws -> String {
        guard let url = URL(string: entryUrl) else { return entryUrl }

        let (data, _) = try await session.data(from: url)

        // Check if response is JSON with redirect
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let body = json["body"] as? String {
            // Extract URL from "Redirecting to <url> for ..."
            if let range = body.range(of: "Redirecting to "),
               let endRange = body[range.upperBound...].range(of: " for ") {
                return String(body[range.upperBound..<endRange.lowerBound])
            } else if let range = body.range(of: "Redirecting to ") {
                return String(body[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // If not JSON, the URL itself might work (or already resolved)
        return entryUrl
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

    // MARK: - Fetch broadcast detail (uitzendingen page scrape)

    func fetchBroadcastDetail(forChannel channelId: String, broadcastUrl: String) async throws -> NPOBroadcastDetail? {
        guard let baseURL = Self.stationURLs[channelId] else {
            throw NPOAPIError.invalidURL
        }

        guard let url = URL(string: "\(baseURL)\(broadcastUrl)") else {
            throw NPOAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NPOAPIError.invalidResponse
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw NPOAPIError.invalidResponse
        }

        return parseBroadcastDetail(html: html)
    }

    // MARK: - Fetch uitzendingen list (with URLs for detail pages)

    func fetchBroadcastList(forChannel channelId: String) async throws -> [NPOBroadcastListItem] {
        guard let baseURL = Self.stationURLs[channelId] else {
            throw NPOAPIError.invalidURL
        }

        guard let url = URL(string: "\(baseURL)/uitzendingen") else {
            throw NPOAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NPOAPIError.invalidResponse
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw NPOAPIError.invalidResponse
        }

        return parseBroadcastList(html: html)
    }

    // MARK: - HTML Parsing helpers

    private func parseBroadcastDetail(html: String) -> NPOBroadcastDetail? {
        guard let jsonRange = html.range(of: "\"application/json\""),
              let scriptStart = html[jsonRange.upperBound...].range(of: ">"),
              let scriptEnd = html[scriptStart.upperBound...].range(of: "</script>") else {
            return nil
        }

        let jsonString = String(html[scriptStart.upperBound..<scriptEnd.lowerBound])

        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let props = (json["props"] as? [String: Any])?["pageProps"] as? [String: Any],
              let rb = props["radioBroadcast"] as? [String: Any] else {
            return nil
        }

        let description = rb["description"] as? String
        let name = rb["name"] as? String
        let presenters = rb["presenters"] as? [String] ?? []
        let imageUrl = rb["imageUrl"] as? String

        // Extract programme info
        let prog = rb["programme"] as? [String: Any]
        let programmeName = prog?["name"] as? String
        let programmeUrl = prog?["url"] as? String
        let recording = prog?["recording"] as? Bool ?? false
        let formattedDate = rb["formattedDate"] as? String

        // Extract listen-back MP3 URL from showAssets
        var listenBackUrl: String?
        if let assets = rb["showAssets"] as? [[String: Any]], let first = assets.first,
           let player = first["player"] as? [String: Any],
           let params = player["parameters"] as? [[String: Any]] {
            for param in params {
                if param["name"] as? String == "progressive" {
                    listenBackUrl = param["value"] as? String
                }
            }
        }

        // Extract fragments
        var fragments: [NPOFragment] = []
        if let fs = props["fragmentsSection"] as? [String: Any],
           let frags = fs["fragments"] as? [[String: Any]] {
            for frag in frags {
                fragments.append(NPOFragment(
                    id: frag["id"] as? String ?? "",
                    name: frag["name"] as? String ?? "",
                    imageUrl: frag["imageUrl"] as? String,
                    type: frag["type"] as? String,
                    url: frag["url"] as? String
                ))
            }
        }

        // Clean HTML from description
        let cleanDescription = description?
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return NPOBroadcastDetail(
            name: name ?? "",
            description: cleanDescription,
            formattedDate: formattedDate,
            presenters: presenters,
            imageUrl: imageUrl,
            programmeName: programmeName,
            programmeUrl: programmeUrl,
            isRecording: recording,
            listenBackUrl: listenBackUrl,
            fragments: fragments
        )
    }

    private func parseBroadcastList(html: String) -> [NPOBroadcastListItem] {
        // Find the __NEXT_DATA__ JSON
        guard let jsonRange = html.range(of: "\"application/json\""),
              let scriptStart = html[jsonRange.upperBound...].range(of: ">"),
              let scriptEnd = html[scriptStart.upperBound...].range(of: "</script>") else {
            return []
        }

        let jsonString = String(html[scriptStart.upperBound..<scriptEnd.lowerBound])

        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let props = (json["props"] as? [String: Any])?["pageProps"] as? [String: Any],
              let broadcasts = props["broadcasts"] as? [[String: Any]] else {
            return []
        }

        return broadcasts.compactMap { b in
            guard let title = b["title"] as? String,
                  let url = b["url"] as? String else { return nil }
            return NPOBroadcastListItem(
                title: title,
                url: url,
                time: b["time"] as? String,
                date: b["date"] as? String,
                imageUrl: b["imageUrl"] as? String
            )
        }
    }

    // MARK: - Fetch programme page (show level)

    func fetchShowPage(forChannel channelId: String, programmeUrl: String) async throws -> NPOShowPage? {
        guard let baseURL = Self.stationURLs[channelId] else {
            throw NPOAPIError.invalidURL
        }

        guard let url = URL(string: "\(baseURL)\(programmeUrl)") else {
            throw NPOAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NPOAPIError.invalidResponse
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw NPOAPIError.invalidResponse
        }

        return parseShowPage(html: html)
    }

    private func parseShowPage(html: String) -> NPOShowPage? {
        guard let jsonRange = html.range(of: "\"application/json\""),
              let scriptStart = html[jsonRange.upperBound...].range(of: ">"),
              let scriptEnd = html[scriptStart.upperBound...].range(of: "</script>") else {
            return nil
        }

        let jsonString = String(html[scriptStart.upperBound..<scriptEnd.lowerBound])

        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let props = (json["props"] as? [String: Any])?["pageProps"] as? [String: Any] else {
            return nil
        }

        let prog = props["programme"] as? [String: Any]
        let description = (prog?["description"] as? String)?
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let imageUrl = prog?["imageUrl"] as? String
        let name = props["pageHeaderTitle"] as? String ?? prog?["name"] as? String ?? ""

        var broadcasts: [NPOBroadcastListItem] = []
        if let bs = props["broadcastsSection"] as? [String: Any],
           let bcs = bs["broadcasts"] as? [[String: Any]] {
            for b in bcs {
                if let title = b["title"] as? String, let url = b["url"] as? String {
                    broadcasts.append(NPOBroadcastListItem(
                        title: title,
                        url: url,
                        time: b["formattedTimes"] as? String,
                        date: b["formattedDate"] as? String,
                        imageUrl: b["imageUrl"] as? String
                    ))
                }
            }
        }

        return NPOShowPage(
            name: name,
            description: description,
            imageUrl: imageUrl,
            broadcasts: broadcasts
        )
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
    let stopdatetime: String?
    let image_url_200x200: String?
    let image_url_400x400: String?
    let spotify_url: String?
    // Klassiek extra velden
    let composer: String?
    let composer_name: String?
    let soloistsEnsemble: String?
    let orchestra: String?
    let director: String?
    let label: String?
    let labelcatalognr: String?
    let description: String?

    var isClassical: Bool {
        composer != nil || orchestra != nil || director != nil
    }
}

// MARK: - Broadcast Detail (scraped from uitzendingen pages)

struct NPOBroadcastDetail {
    let name: String
    let description: String?
    let formattedDate: String?
    let presenters: [String]
    let imageUrl: String?
    let programmeName: String?
    let programmeUrl: String?
    let isRecording: Bool
    let listenBackUrl: String?
    let fragments: [NPOFragment]
}

struct NPOFragment {
    let id: String
    let name: String
    let imageUrl: String?
    let type: String?
    let url: String?
}

struct NPOBroadcastListItem {
    let title: String
    let url: String
    let time: String?
    let date: String?
    let imageUrl: String?
}

// MARK: - Show Page (scraped from programma pages)

struct NPOShowPage {
    let name: String
    let description: String?
    let imageUrl: String?
    let broadcasts: [NPOBroadcastListItem]
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
