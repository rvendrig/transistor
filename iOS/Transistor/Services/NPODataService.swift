import Foundation

class NPODataService {
    static let shared = NPODataService()

    // MARK: - Channels

    func getAllChannels() -> [NPOChannel] {
        return [
            NPOChannel(
                id: "radio1",
                name: "NPO Radio 1",
                description: "Nieuws, sport, cultuur en entertainment",
                logoURL: nil
            ),
            NPOChannel(
                id: "radio2",
                name: "NPO Radio 2",
                description: "Muziek, entertainment en informatieve programma's",
                logoURL: nil
            ),
            NPOChannel(
                id: "3fm",
                name: "NPO 3FM",
                description: "Muziek, hits en alternatieve nummers",
                logoURL: nil
            ),
            NPOChannel(
                id: "radio4",
                name: "NPO Radio 4",
                description: "Klassieke muziek en jazz",
                logoURL: nil
            ),
            NPOChannel(
                id: "radio5",
                name: "NPO Radio 5",
                description: "Documentaires en reportages",
                logoURL: nil
            ),
            NPOChannel(
                id: "radio6",
                name: "NPO Radio 6",
                description: "Muziek en verhalen",
                logoURL: nil
            )
        ]
    }

    // MARK: - Programs

    func getProgramsForChannel(_ channelId: String) -> [NPOProgram] {
        let programs: [NPOProgram] = [
            NPOProgram(
                id: "prog1",
                title: "Ochtendshow",
                description: "De beste muziek en verhalen in de ochtend",
                presenters: ["Gert Jacobs", "Anita Witzier"],
                image: nil,
                genre: "Entertainment",
                channelId: channelId
            ),
            NPOProgram(
                id: "prog2",
                title: "Middagcafé",
                description: "Muziek, gesprekken en gasten",
                presenters: ["Menno Terpstra"],
                image: nil,
                genre: "Talk Show",
                channelId: channelId
            ),
            NPOProgram(
                id: "prog3",
                title: "Nachtshow",
                description: "De beste nummers voor 's avonds",
                presenters: ["Sander de Haan"],
                image: nil,
                genre: "Muziek",
                channelId: channelId
            ),
            NPOProgram(
                id: "prog4",
                title: "Sports Update",
                description: "Alle sportuitslagen en reportages",
                presenters: ["Matthijs van Nieuwkerk"],
                image: nil,
                genre: "Sport",
                channelId: channelId
            ),
            NPOProgram(
                id: "prog5",
                title: "Cultuurclassics",
                description: "Kunst, literatuur en theater",
                presenters: ["Carly Wijs"],
                image: nil,
                genre: "Cultuur",
                channelId: channelId
            )
        ]
        return programs
    }

    // MARK: - Broadcasts

    func getBroadcastsForProgram(_ programId: String) -> [NPOBroadcast] {
        var broadcasts: [NPOBroadcast] = []
        let calendar = Calendar.current
        let now = Date()

        // Create broadcasts for the last 10 days
        for daysAgo in 0..<10 {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) {
                let broadcast = NPOBroadcast(
                    id: "broadcast_\(daysAgo)",
                    title: "Aflevering van \(date.formatted(date: .abbreviated, time: .omitted))",
                    programId: programId,
                    startTime: date,
                    duration: 3600, // 1 hour
                    description: "Deze aflevering bevat interessante onderwerpen en gasten",
                    image: nil
                )
                broadcasts.append(broadcast)
            }
        }

        return broadcasts
    }

    // MARK: - Items

    func getItemsForBroadcast(_ broadcastId: String) -> [NPOItem] {
        return [
            NPOItem(
                id: "item1",
                broadcastId: broadcastId,
                title: "Interview met deskundige",
                description: "Een interessant interview over actuele onderwerpen",
                type: .interview,
                duration: 600,
                guests: ["Prof. Dr. Jan Smit"],
                topics: ["Wetenschap", "Onderzoek"],
                startOffset: 0
            ),
            NPOItem(
                id: "item2",
                broadcastId: broadcastId,
                title: "Muziekkeuze van de dag",
                description: "De mooiste nummers van deze week",
                type: .music,
                duration: 300,
                guests: [],
                topics: ["Muziek"],
                startOffset: 600
            ),
            NPOItem(
                id: "item3",
                broadcastId: broadcastId,
                title: "Nieuwsupdate",
                description: "De belangrijkste nieuwsfeiten van vandaag",
                type: .news,
                duration: 480,
                guests: [],
                topics: ["Nieuws", "Politiek"],
                startOffset: 900
            ),
            NPOItem(
                id: "item4",
                broadcastId: broadcastId,
                title: "Reportage uit het buitenland",
                description: "Een reportage over wat er gebeurt in de wereld",
                type: .report,
                duration: 720,
                guests: ["Correspondent Maria Vos"],
                topics: ["Internationaal", "Politiek"],
                startOffset: 1380
            ),
            NPOItem(
                id: "item5",
                broadcastId: broadcastId,
                title: "Thema van de week",
                description: "Deze week bespreken we het thema duurzaamheid",
                type: .topic,
                duration: 900,
                guests: ["Expert Klimaat", "Minister Milieu"],
                topics: ["Duurzaamheid", "Milieu"],
                startOffset: 2100
            )
        ]
    }

    // MARK: - Search

    func searchPrograms(_ query: String) -> [NPOProgram] {
        let allChannels = getAllChannels()
        var results: [NPOProgram] = []

        for channel in allChannels {
            let programs = getProgramsForChannel(channel.id)
            results.append(contentsOf: programs.filter { program in
                program.title.lowercased().contains(query.lowercased()) ||
                    program.description.lowercased().contains(query.lowercased())
            })
        }

        return results
    }
}
