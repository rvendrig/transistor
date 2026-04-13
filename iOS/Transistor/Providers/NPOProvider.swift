import Foundation

// ============================================================================
// NPO Provider — Nederlandse Publieke Omroep
// ============================================================================
//
// ## POMS Mapping → Transistor Model
//
// NPO (implicit)         → Network
// Zender                  → Channel        (Radio 1, 3FM, Klassiek, etc.)
// Programma (UMBRELLA)    → Show           (Spraakmakers, Argos, etc.)
// Seizoen (SEASON)        → Season
// Uitzending (BROADCAST)  → Broadcast      (één aflevering op een specifiek tijdstip)
// Item/Fragment           → Segment        (interview, nieuwsblok, muziek)
// Clip (CLIP)             → Clip
//
// ## Databronnen
//
// NPO heeft geen enkele publieke API. Alle data wordt opgehaald via de
// station-websites (Prepr CMS) en HTML-scraping. Geen auth nodig, wel
// User-Agent header vereist (anders 403).
//
// ### 1. Dagprogramma (broadcasts)
//   Bron: GET https://www.{station}.nl/api/broadcasts
//   Geeft: titel, presentatoren, omroep, start/stoptijd, afbeelding
//   Scope: resterende programma's van vandaag (vanaf nu)
//   Gebruikt door: fetchBroadcasts(forChannel:)
//
// ### 2. Gespeelde tracks
//   Bron: GET https://www.{station}.nl/api/tracks
//   Geeft: artiest, titel, start/eindtijd, artwork, Spotify-link
//   Extra velden bij Klassiek: componist, orkest, solist, dirigent, label
//   Scope: recent gespeelde nummers
//
// ### 3. Uitzendingen-lijst (met detail-URLs)
//   Bron: HTML-scrape van https://www.{station}.nl/uitzendingen
//   Geeft: titel, datum, tijden, afbeelding, URL naar detailpagina
//   Scope: ~20 meest recente afgelopen uitzendingen
//   Gebruikt door: fetchBroadcasts(forChannel:) voor detailUrl enrichment
//
// ### 4. Uitzending-detail (rijke metadata)
//   Bron: HTML-scrape van https://www.{station}.nl/uitzendingen/{slug}/{uuid}/{datum}
//   Geeft: volledige beschrijving, presentatoren (array), omroep,
//          terugluister-MP3 (entry.cdn.npoaudio.nl), fragmenten met
//          afbeeldingen, programma-info (naam, URL, recording-status)
//   Koppeling: via detailUrl op Broadcast (gezet bij stap 1+3)
//
// ### 5. Programma-pagina (show-niveau)
//   Bron: HTML-scrape van https://www.{station}.nl/programmas/{slug}
//   Geeft: beschrijving, afbeelding, lijst eerdere uitzendingen,
//          podcast-feed URL (als die bestaat)
//
// ### 6. Live streams
//   Bron: Icecast — https://icecast.omroep.nl/{station-id}-bb-mp3
//   Format: MP3 ~192kbps
//
// ### 7. Terugluisteren (on-demand audio)
//   Bron: https://entry.cdn.npoaudio.nl/handle/{MID}.mp3
//   Beschikbaarheid: tijdelijk (weken/maanden), niet alle uitzendingen
//   Detectie: programme.recording == true op de detailpagina
//
// ### 8. Podcasts
//   Bron: RSS feed — https://podcast.npo.nl/feed/{slug}.xml
//   Beschikbaarheid: permanent, soms bewerkte versie van de uitzending
//   Detectie: podcastFeedUrl veld op de programma-pagina
//   Overzicht: https://www.{station}.nl/podcasts (alle feeds per zender)
//
// ## Enrichment-strategie
//
// Het dagprogramma (/api/broadcasts) bevat geen detail-URL of UUID.
// Om de link naar de detailpagina te leggen:
// 1. Haal dagprogramma op via /api/broadcasts
// 2. Haal uitzendingen-lijst op via /uitzendingen (HTML-scrape)
// 3. Match elke broadcast op titel (case-insensitive) met de uitzendingen-lijst
// 4. Zet de gematchte URL als detailUrl op het Broadcast-object
// 5. Bij het openen van detail: gebruik detailUrl direct (geen title-matching)
//
// Beperking: toekomstige uitzendingen hebben geen detailUrl (staan niet
// op /uitzendingen). De detailpagina is pas beschikbaar na de uitzending.
//
// ## Station URL mapping
//
// radio1  → nporadio1.nl    | radio4 → npoklassiek.nl
// radio2  → nporadio2.nl    | radio5 → nporadio5.nl
// 3fm     → npo3fm.nl       | funx   → funx.nl
// ============================================================================

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

        // Fetch uitzendingen list to match detail URLs
        let broadcastListItems: [NPOBroadcastListItem]
        do {
            broadcastListItems = try await apiService.fetchBroadcastList(forChannel: channelId)
        } catch {
            broadcastListItems = []
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        return apiBroadcasts.compactMap { api in
            guard let startTime = dateFormatter.date(from: api.startdatetime) else { return nil }
            let endTime = dateFormatter.date(from: api.stopdatetime) ?? startTime
            let duration = Int(endTime.timeIntervalSince(startTime))

            // Match by title (case-insensitive) using cascading logic
            let apiTitleLower = api.title.lowercased()
            let detailUrl: String? = broadcastListItems.first(where: {
                $0.title.lowercased() == apiTitleLower
            })?.url ?? broadcastListItems.first(where: {
                $0.title.lowercased().hasPrefix(apiTitleLower) || apiTitleLower.hasPrefix($0.title.lowercased())
            })?.url ?? broadcastListItems.first(where: {
                $0.title.lowercased().contains(apiTitleLower) || apiTitleLower.contains($0.title.lowercased())
            })?.url

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
                titleOverride: nil,
                detailUrl: detailUrl
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
                    titleOverride: nil,
                    detailUrl: nil
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
                    titleOverride: nil,
                    detailUrl: nil
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
                    titleOverride: nil,
                    detailUrl: nil
                )
            }
        } catch {
            print("NPO Search Error: \(error.localizedDescription)")
            return []
        }
    }
}
