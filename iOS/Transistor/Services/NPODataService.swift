import Foundation

class NPODataService {
    static let shared = NPODataService()

    func getAllChannels() -> [NPOChannel] {
        [
            NPOChannel(
                id: "radio1",
                name: "NPO Radio 1",
                description: "Nieuws, informatie en cultuur",
                imageURL: nil,
                streamURL: URL(string: "https://icecast.omroep.nl/radio1-bb-mp3")
            ),
            NPOChannel(
                id: "radio2",
                name: "NPO Radio 2",
                description: "Pop, rock en nostalgie",
                imageURL: nil,
                streamURL: URL(string: "https://icecast.omroep.nl/radio2-bb-mp3")
            ),
            NPOChannel(
                id: "radio3fm",
                name: "3FM",
                description: "Pop, rock en jong talent",
                imageURL: nil,
                streamURL: URL(string: "https://icecast.omroep.nl/3fm-bb-mp3")
            ),
            NPOChannel(
                id: "radio4",
                name: "NPO Radio 4",
                description: "Klassieke muziek",
                imageURL: nil,
                streamURL: URL(string: "https://icecast.omroep.nl/radio4-bb-mp3")
            ),
            NPOChannel(
                id: "radio5",
                name: "NPO Radio 5",
                description: "Wereldmuziek en cultuur",
                imageURL: nil,
                streamURL: URL(string: "https://icecast.omroep.nl/radio5-bb-mp3")
            ),
            NPOChannel(
                id: "radio6",
                name: "NPO Radio 6",
                description: "Jazz en wereldmuziek",
                imageURL: nil,
                streamURL: URL(string: "https://icecast.omroep.nl/radio6-bb-mp3")
            ),
        ]
    }

    func getProgramsForChannel(_ channelId: String) -> [NPOProgram] {
        let programs: [String: [NPOProgram]] = [
            "radio1": [
                NPOProgram(
                    id: "ochtendshow",
                    channelId: "radio1",
                    title: "Ochtendshow",
                    description: "De start van je dag met nieuws, muziek en interviews",
                    imageURL: nil,
                    presenters: ["Jeroen Pauw", "Matthijs van Nieuwkerk"],
                    genres: ["nieuws", "interview", "muziek"]
                ),
                NPOProgram(
                    id: "middag",
                    channelId: "radio1",
                    title: "Middaguren",
                    description: "Actualiteiten en reportages",
                    imageURL: nil,
                    presenters: ["Sybille Beukers"],
                    genres: ["actueel", "reportage"]
                ),
                NPOProgram(
                    id: "avondshow",
                    channelId: "radio1",
                    title: "Avondshow",
                    description: "Diepgravend onderzoek en documentaires",
                    imageURL: nil,
                    presenters: ["Matthijs van Nieuwkerk"],
                    genres: ["documentaire", "onderzoek"]
                ),
                NPOProgram(
                    id: "podcast-eo",
                    channelId: "radio1",
                    title: "Podcast: Eo Verantwoording",
                    description: "Diepgaande interviews en debatten",
                    imageURL: nil,
                    presenters: ["Matthijs van Nieuwkerk"],
                    genres: ["podcast", "interview"]
                ),
            ],
            "radio2": [
                NPOProgram(
                    id: "early-birds",
                    channelId: "radio2",
                    title: "Early Birds",
                    description: "Pop, rock en de beste nummers",
                    imageURL: nil,
                    presenters: ["Menno Schroor"],
                    genres: ["muziek", "pop", "rock"]
                ),
                NPOProgram(
                    id: "midday-hits",
                    channelId: "radio2",
                    title: "Midday Hits",
                    description: "De beste muziek van toen en nu",
                    imageURL: nil,
                    presenters: ["Frank van der Lende"],
                    genres: ["muziek", "nostalgie"]
                ),
                NPOProgram(
                    id: "podcast-luistergoud",
                    channelId: "radio2",
                    title: "Podcast: Luistergoud",
                    description: "De mooiste persoonlijke verhalen",
                    imageURL: nil,
                    presenters: ["Anita Witzier"],
                    genres: ["podcast", "verhalen"]
                ),
            ],
            "radio3fm": [
                NPOProgram(
                    id: "breakfast",
                    channelId: "radio3fm",
                    title: "3FM Breakfast Show",
                    description: "Wake up met de beste muziek",
                    imageURL: nil,
                    presenters: ["Ruud de Wild"],
                    genres: ["muziek", "pop", "rock"]
                ),
                NPOProgram(
                    id: "podcast-funx",
                    channelId: "radio3fm",
                    title: "Podcast: 3FM Funx",
                    description: "Hip hop en R&B nummers",
                    imageURL: nil,
                    presenters: ["Nieuw talent"],
                    genres: ["podcast", "muziek", "hiphop"]
                ),
            ],
            "radio4": [
                NPOProgram(
                    id: "klassiek",
                    channelId: "radio4",
                    title: "Klassieke Avond",
                    description: "Klassieke muziek en opvoeringen",
                    imageURL: nil,
                    presenters: ["Matthijs van Nieuwkerk"],
                    genres: ["klassiek", "muziek"]
                ),
                NPOProgram(
                    id: "podcast-opera",
                    channelId: "radio4",
                    title: "Podcast: De Wereld van Opera",
                    description: "Alles over opera en klassiek",
                    imageURL: nil,
                    presenters: ["Lukas Heideman"],
                    genres: ["podcast", "klassiek"]
                ),
            ],
            "radio5": [
                NPOProgram(
                    id: "wereld",
                    channelId: "radio5",
                    title: "Wereld Muziek Showcase",
                    description: "Muziek uit alle hoeken van de wereld",
                    imageURL: nil,
                    presenters: ["Anita Witzier"],
                    genres: ["wereldmuziek", "cultuur"]
                ),
                NPOProgram(
                    id: "podcast-reizen",
                    channelId: "radio5",
                    title: "Podcast: Reizen Rond de Wereld",
                    description: "Verhalen uit verschillende culturen",
                    imageURL: nil,
                    presenters: ["Reizigers"],
                    genres: ["podcast", "cultuur", "reizen"]
                ),
            ],
            "radio6": [
                NPOProgram(
                    id: "jazz",
                    channelId: "radio6",
                    title: "Jazz Avond",
                    description: "De beste jazz-artiesten",
                    imageURL: nil,
                    presenters: ["Willem Breuker"],
                    genres: ["jazz", "muziek"]
                ),
                NPOProgram(
                    id: "podcast-jazz",
                    channelId: "radio6",
                    title: "Podcast: Jazz Talk",
                    description: "Interviews met jazzmusici",
                    imageURL: nil,
                    presenters: ["Jazz expert"],
                    genres: ["podcast", "jazz", "interview"]
                ),
            ],
        ]

        return programs[channelId] ?? []
    }

    func getBroadcastsForProgram(_ programId: String) -> [NPOBroadcast] {
        var broadcasts: [NPOBroadcast] = []
        let now = Date()

        for i in 0..<10 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: now) ?? now
            let startDate = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? now

            broadcasts.append(
                NPOBroadcast(
                    id: "broadcast-\(programId)-\(i)",
                    programId: programId,
                    title: "\(programId) - \(dateFormatter.string(from: startDate))",
                    description: "Afleveringsinfo",
                    startTime: startDate,
                    endTime: Calendar.current.date(byAdding: .hour, value: 1, to: startDate),
                    duration: 3600,
                    audioURL: URL(string: "https://example.com/audio/\(programId)/\(i).mp3"),
                    imageURL: nil,
                    broadcasterName: "NPO",
                    presenters: [
                        Presenter(id: "presenter1", name: "Jeroen Pauw", bio: "Ervaren presentator", imageURL: nil),
                    ],
                    guests: [
                        Guest(name: "Gast van de dag", role: "Expert", affiliation: "Instituut"),
                    ],
                    topics: ["nieuws", "cultuur", "samenleving"],
                    musicPlayed: [
                        Music(title: "Nummertitel", artist: "Artiestnaam", timestamp: 300),
                    ]
                )
            )
        }

        return broadcasts
    }

    func getItemsForBroadcast(_ broadcastId: String) -> [NPOItem] {
        [
            NPOItem(
                id: "item-\(broadcastId)-1",
                broadcastId: broadcastId,
                title: "Interview met gast",
                description: "Een diepgaand interview",
                type: .interview,
                startTime: 300,
                duration: 900,
                guests: ["Expert in het veld"],
                topics: ["actueel", "diepgang"],
                artist: nil,
                musicTitle: nil,
                imageURL: nil,
                teaserText: "Hoe kijkt deze expert aan tegen het onderwerp?"
            ),
            NPOItem(
                id: "item-\(broadcastId)-2",
                broadcastId: broadcastId,
                title: "Muziek: Populaire nummers",
                description: "Selectie van best draaiende nummers",
                type: .music,
                startTime: 1200,
                duration: 600,
                guests: nil,
                topics: nil,
                artist: "Diverse artiesten",
                musicTitle: "Hit nummers mix",
                imageURL: nil,
                teaserText: nil
            ),
            NPOItem(
                id: "item-\(broadcastId)-3",
                broadcastId: broadcastId,
                title: "Actueel: Belangrijk nieuws",
                description: "Belangrijkste nieuwsitems",
                type: .news,
                startTime: 1800,
                duration: 480,
                guests: nil,
                topics: ["nieuws", "actueel"],
                artist: nil,
                musicTitle: nil,
                imageURL: nil,
                teaserText: "Wat is er vandag belangrijk gebeurd?"
            ),
            NPOItem(
                id: "item-\(broadcastId)-4",
                broadcastId: broadcastId,
                title: "Reportage: Dit moet je weten",
                description: "Diepgaande reportage",
                type: .report,
                startTime: 2280,
                duration: 720,
                guests: nil,
                topics: ["onderzoek", "reportage", "samenleving"],
                artist: nil,
                musicTitle: nil,
                imageURL: nil,
                teaserText: "Wat gebeurt er achter de schermen?"
            ),
            NPOItem(
                id: "item-\(broadcastId)-5",
                broadcastId: broadcastId,
                title: "Thema: Vandaag in focus",
                description: "Het thema van vandaag",
                type: .topic,
                startTime: 3000,
                duration: 600,
                guests: ["Meerdere sprekers"],
                topics: ["thema", "focus"],
                artist: nil,
                musicTitle: nil,
                imageURL: nil,
                teaserText: nil
            ),
        ]
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "nl_NL")
        return formatter
    }()
}
