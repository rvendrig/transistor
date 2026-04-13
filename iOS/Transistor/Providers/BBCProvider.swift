import Foundation

// BBC Sounds Mapping → Transistor Model
// ──────────────────────────────────────
// BBC                → Network
// Service (Radio 4)  → Channel
// Brand              → Show
// Series             → Season
// Episode            → Broadcast / Episode
// Segment            → Segment
// Clip               → Clip

class BBCProvider: ContentProvider {
    let id = "bbc"
    let name = "BBC Sounds"
    let type = ProviderType.radioNetwork
    let logo: String? = "https://sounds.files.bbci.co.uk/3.4.1/networks/bbc_radio_fourfm/images/logo_304x304.png"

    private let session: URLSession

    static let channels: [(id: String, name: String, description: String)] = [
        ("bbc_radio_one", "BBC Radio 1", "New music and entertainment"),
        ("bbc_radio_two", "BBC Radio 2", "Great music, for the young at heart"),
        ("bbc_radio_three", "BBC Radio 3", "Classical, jazz and world music"),
        ("bbc_radio_fourfm", "BBC Radio 4", "Intelligent speech radio"),
        ("bbc_radio_five_live", "BBC Radio 5 Live", "Live news and sport"),
        ("bbc_6music", "BBC 6 Music", "Alternative music")
    ]

    static let streamURLs: [String: String] = [
        "bbc_radio_one": "https://stream.live.vc.bbcmedia.co.uk/bbc_radio_one",
        "bbc_radio_two": "https://stream.live.vc.bbcmedia.co.uk/bbc_radio_two",
        "bbc_radio_three": "https://stream.live.vc.bbcmedia.co.uk/bbc_radio_three",
        "bbc_radio_fourfm": "https://stream.live.vc.bbcmedia.co.uk/bbc_radio_fourfm",
        "bbc_radio_five_live": "https://stream.live.vc.bbcmedia.co.uk/bbc_radio_five_live",
        "bbc_6music": "https://stream.live.vc.bbcmedia.co.uk/bbc_6music"
    ]

    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "Transistor/1.0 (iOS)"]
        self.session = URLSession(configuration: config)
    }

    // MARK: - Channels

    func fetchChannels() async throws -> [Channel] {
        Self.channels.map { ch in
            Channel(
                id: ch.id,
                providerId: id,
                networkId: "bbc",
                titles: [TitledPeriod(title: ch.name)],
                description: ch.description,
                logo: nil
            )
        }
    }

    // MARK: - Shows (from schedule)

    func fetchShows(forChannel channelId: String) async throws -> [Show] {
        let broadcasts = try await fetchBroadcasts(forChannel: channelId)
        var seen = Set<String>()
        var shows: [Show] = []

        for broadcast in broadcasts {
            let title = broadcast.title
            if !seen.contains(title) {
                seen.insert(title)
                shows.append(Show(
                    id: title.lowercased().replacingOccurrences(of: " ", with: "-"),
                    providerId: id,
                    titles: [TitledPeriod(title: title)],
                    description: broadcast.description ?? "",
                    presenters: [],
                    genre: nil,
                    channelIds: [channelId],
                    image: broadcast.image
                ))
            }
        }

        return shows
    }

    // MARK: - Broadcasts (schedule)

    func fetchBroadcasts(forShow showId: String) async throws -> [Broadcast] {
        [] // Not implemented yet — would need to search across channels
    }

    func fetchBroadcasts(forChannel channelId: String) async throws -> [Broadcast] {
        let urlString = "https://rms.api.bbc.co.uk/v2/experience/inline/schedules/\(channelId)"
        guard let url = URL(string: urlString) else { return [] }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return [] }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let scheduleModule = dataArray.first(where: { $0["id"] as? String == "schedule_items" }),
              let items = scheduleModule["data"] as? [[String: Any]] else {
            return []
        }

        let dateFormatter = ISO8601DateFormatter()

        return items.compactMap { item -> Broadcast? in
            guard let startStr = item["start"] as? String,
                  let endStr = item["end"] as? String,
                  let startTime = dateFormatter.date(from: startStr),
                  let endTime = dateFormatter.date(from: endStr) else { return nil }

            let titles = item["titles"] as? [String: Any]
            let primaryTitle = titles?["primary"] as? String ?? "Unknown"
            let secondaryTitle = titles?["secondary"] as? String

            let duration = Int(endTime.timeIntervalSince(startTime))

            let network = item["network"] as? [String: Any]
            let logoUrl = network?["logo_url"] as? String

            let synopses = item["synopses"] as? [String: Any]
            let synopsis = synopses?["short"] as? String ?? synopses?["medium"] as? String

            let displayTitle = [primaryTitle, secondaryTitle].compactMap { $0 }.joined(separator: ": ")

            return Broadcast(
                id: item["id"] as? String ?? UUID().uuidString,
                providerId: id,
                title: displayTitle,
                showId: nil,
                channelId: channelId,
                seasonId: nil,
                startTime: startTime,
                duration: duration,
                description: synopsis,
                image: logoUrl,
                audioUrl: Self.streamURLs[channelId],
                titleOverride: nil
            )
        }
    }

    // MARK: - Search

    func search(_ query: String) async throws -> [any AudioContent] {
        []
    }
}
