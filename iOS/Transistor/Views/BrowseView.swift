import SwiftUI

struct BrowseView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: Radio sectie
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Radio")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        if viewModel.isLoadingChannels {
                            HStack {
                                ProgressView().tint(.transistorGreen)
                                Text("Laden...").foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(Array(viewModel.channels.enumerated()), id: \.element.id) { index, channel in
                                NavigationLink(value: channel) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(channel.currentTitle)
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Text(channel.description)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(2)
                                        Spacer()
                                    }
                                    .frame(height: 100)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hue: Double(index) / max(Double(viewModel.channels.count), 1), saturation: 0.7, brightness: 0.5),
                                                Color(hue: Double(index) / max(Double(viewModel.channels.count), 1), saturation: 0.7, brightness: 0.3),
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // MARK: Podcasts sectie
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Podcasts")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { /* TODO: voeg podcast toe */ }) {
                                Label("Voeg toe", systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.transistorGreen)
                            }
                        }
                        .padding(.horizontal)

                        let podcasts = ContentEnrichmentService.shared.getPopularPodcasts()
                        if podcasts.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "mic")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                                Text("Voeg een podcast toe via RSS")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            ForEach(podcasts, id: \.id) { podcast in
                                HStack(spacing: 12) {
                                    Image(systemName: "mic.fill")
                                        .foregroundColor(.transistorGreen)
                                        .frame(width: 40, height: 40)
                                        .background(Color.cardBg)
                                        .cornerRadius(8)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(podcast.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                        Text(podcast.description)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Transistor")
            .background(Color.darkBg)
            .navigationDestination(for: Channel.self) { channel in
                BrowseScheduleView(channel: channel, viewModel: viewModel)
            }
            .navigationDestination(for: Broadcast.self) { broadcast in
                BroadcastDetailView(broadcast: broadcast, channelId: broadcast.channelId ?? "")
            }
            .onAppear {
                Task {
                    await viewModel.loadChannels()
                }
            }
        }
    }
}

// MARK: - Dagprogramma per zender

struct BrowseScheduleView: View {
    let channel: Channel
    @ObservedObject var viewModel: ContentViewModel
    @State private var selectedDate = Date()
    @State private var broadcasts: [Broadcast] = []
    @State private var isLoading = false

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private let dateDisplayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "EEE d MMM yyyy"
        return f
    }()

    // Shortcuts: nieuws, weer, verkeer uitzendingen herkennen aan titel
    var shortcuts: [(icon: String, label: String, broadcast: Broadcast?)] {
        let news = broadcasts.last(where: { isShortcutMatch($0, keywords: ["journaal", "nieuws", "nos"]) })
        let weather = broadcasts.last(where: { isShortcutMatch($0, keywords: ["weer", "weerbericht"]) })
        let traffic = broadcasts.last(where: { isShortcutMatch($0, keywords: ["verkeer", "anwb", "file"]) })

        var result: [(String, String, Broadcast?)] = []
        if news != nil { result.append(("newspaper", "Nieuws", news)) }
        if weather != nil { result.append(("cloud.sun", "Weer", weather)) }
        if traffic != nil { result.append(("car", "Verkeer", traffic)) }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Dag-navigatie
            HStack {
                Button(action: { changeDate(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.transistorGreen)
                }

                Spacer()

                VStack(spacing: 2) {
                    if Calendar.current.isDateInToday(selectedDate) {
                        Text("Vandaag")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.transistorGreen)
                    }
                    Text(dateDisplayFormatter.string(from: selectedDate))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Button(action: { changeDate(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.transistorGreen)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.cardBg)

            // Shortcuts (nieuws/weer/verkeer)
            if !shortcuts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(shortcuts, id: \.label) { shortcut in
                            if let broadcast = shortcut.broadcast {
                                NavigationLink(value: broadcast) {
                                    HStack(spacing: 6) {
                                        Image(systemName: shortcut.icon)
                                            .font(.caption)
                                        Text(shortcut.label)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.cardBg)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.transistorGreen.opacity(0.5), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }

            // Programma-lijst
            List {
                if isLoading {
                    HStack {
                        ProgressView().tint(.transistorGreen)
                        Text("Laden...").foregroundColor(.gray)
                    }
                }

                ForEach(broadcasts) { broadcast in
                    NavigationLink(value: broadcast) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(timeFormatter.string(from: broadcast.startTime))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(isNow(broadcast) ? .transistorGreen : .white)
                                let endTime = broadcast.startTime.addingTimeInterval(Double(broadcast.duration))
                                Text(timeFormatter.string(from: endTime))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 45)

                            VStack(alignment: .leading, spacing: 4) {
                                if isNow(broadcast) {
                                    Text("NU")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.transistorGreen)
                                        .cornerRadius(4)
                                }
                                Text(broadcast.displayTitle)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                if let desc = broadcast.description, !desc.isEmpty {
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(channel.currentTitle)
        .background(Color.darkBg)
        .onAppear {
            Task { await loadSchedule() }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 50 {
                        changeDate(by: -1)
                    } else if value.translation.width < -50 {
                        changeDate(by: 1)
                    }
                }
        )
    }

    private func changeDate(by days: Int) {
        selectedDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
        Task { await loadSchedule() }
    }

    private func isNow(_ broadcast: Broadcast) -> Bool {
        let now = Date()
        let endTime = broadcast.startTime.addingTimeInterval(Double(broadcast.duration))
        return broadcast.startTime <= now && now <= endTime
    }

    private func isShortcutMatch(_ broadcast: Broadcast, keywords: [String]) -> Bool {
        let title = broadcast.displayTitle.lowercased()
        return keywords.contains(where: { title.contains($0) })
    }

    private func loadSchedule() async {
        guard let provider = viewModel.providerStore.provider(byId: channel.providerId) else { return }
        isLoading = true
        do {
            if Calendar.current.isDateInToday(selectedDate) {
                broadcasts = try await provider.fetchBroadcasts(forChannel: channel.id)
            } else {
                // Voor andere dagen: probeer uitzendingen-pagina te scrapen
                let list = try await NPOAPIService.shared.fetchBroadcastList(forChannel: channel.id)
                // Filter op datum — de list items hebben formattedDate maar geen exacte datum
                // Voorlopig tonen we de beschikbare uitzendingen
                broadcasts = list.compactMap { item in
                    Broadcast(
                        id: item.url,
                        providerId: "npo",
                        title: item.title,
                        showId: nil,
                        channelId: channel.id,
                        seasonId: nil,
                        startTime: selectedDate,
                        duration: 0,
                        description: item.time,
                        image: item.imageUrl,
                        audioUrl: nil,
                        titleOverride: nil
                    )
                }
            }
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Broadcast detail

struct BroadcastDetailView: View {
    let broadcast: Broadcast
    let channelId: String

    @EnvironmentObject var audioPlayer: AudioPlayerService
    @State private var detail: NPOBroadcastDetail?
    @State private var tracks: [NPOTrackAPI] = []
    @State private var broadcastList: [NPOBroadcastListItem] = []
    @State private var isLoading = true

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var endTime: Date {
        broadcast.startTime.addingTimeInterval(Double(broadcast.duration))
    }

    var broadcastState: BroadcastState {
        let now = Date()
        if broadcast.startTime <= now && now <= endTime {
            return .live
        } else if endTime < now {
            return .past
        } else {
            return .upcoming
        }
    }

    enum BroadcastState {
        case live, past, upcoming
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header afbeelding
                headerImage

                // Titel en tijden
                VStack(alignment: .leading, spacing: 8) {
                    // Show-link (als beschikbaar)
                    if let programmeName = detail?.programmeName, let programmeUrl = detail?.programmeUrl {
                        NavigationLink(destination: ShowPageView(channelId: channelId, programmeUrl: programmeUrl, programmeName: programmeName)) {
                            HStack(spacing: 4) {
                                Text(programmeName)
                                    .font(.subheadline)
                                    .foregroundColor(.transistorGreen)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.transistorGreen)
                            }
                        }
                    }

                    Text(broadcast.displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    HStack(spacing: 16) {
                        Label(
                            "\(timeFormatter.string(from: broadcast.startTime)) – \(timeFormatter.string(from: endTime))",
                            systemImage: "clock"
                        )
                        .font(.subheadline)
                        .foregroundColor(.transistorGreen)

                        Label("\(broadcast.duration / 60) min", systemImage: "timer")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    // Presentatoren
                    if let detail, !detail.presenters.isEmpty {
                        Label(detail.presenters.joined(separator: ", "), systemImage: "person.2")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else if let desc = broadcast.description, !desc.isEmpty {
                        Label(desc, systemImage: "person.2")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)

                // CTA
                ctaButton
                    .padding(.horizontal)

                // Beschrijving
                if let description = detail?.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Over deze uitzending")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(description)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                }

                // Fragmenten
                if let detail, !detail.fragments.isEmpty {
                    fragmentsSection(detail.fragments)
                }

                // Tracks
                if !tracks.isEmpty {
                    tracksSection
                }

                // Andere uitzendingen van dit programma
                if !broadcastList.isEmpty {
                    otherBroadcastsSection
                }

                if isLoading {
                    HStack {
                        ProgressView().tint(.transistorGreen)
                        Text("Details laden...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .padding(.vertical)
        }
        .background(Color.darkBg)
        .navigationTitle(broadcast.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await loadAll() }
        }
    }

    // MARK: - Header

    private var headerImage: some View {
        Group {
            let imageUrl = detail?.imageUrl ?? broadcast.image
            if let imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.cardBg)
                }
                .frame(height: 220)
                .clipped()
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Smart CTA

    @ViewBuilder
    private var ctaButton: some View {
        switch broadcastState {
        case .live:
            Button(action: {
                if let streamUrl = broadcast.audioUrl {
                    Task {
                        await audioPlayer.playLive(
                            url: streamUrl,
                            title: broadcast.displayTitle,
                            imageUrl: detail?.imageUrl ?? broadcast.image
                        )
                    }
                }
            }) {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Luister live")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.transistorGreen)
                .cornerRadius(12)
            }

        case .past:
            if let listenBackUrl = detail?.listenBackUrl, !listenBackUrl.isEmpty {
                Button(action: {
                    Task {
                        await audioPlayer.playOnDemand(
                            url: listenBackUrl,
                            title: broadcast.displayTitle,
                            imageUrl: detail?.imageUrl ?? broadcast.image
                        )
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Luister terug")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.transistorGreen)
                    .cornerRadius(12)
                }
            } else if detail?.isRecording == false {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Niet beschikbaar als terugluisteren")
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cardBg)
                .cornerRadius(12)
            } else {
                // Still loading or no detail yet
                HStack {
                    Image(systemName: "clock")
                    Text("Terugluisteren wordt voorbereid...")
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cardBg)
                .cornerRadius(12)
            }

        case .upcoming:
            Button(action: { /* TODO: schedule local notification */ }) {
                HStack {
                    Image(systemName: "bell")
                    Text("Herinner mij")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cardBg)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.transistorGreen, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Fragmenten

    private func fragmentsSection(_ fragments: [NPOFragment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fragmenten")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            ForEach(fragments, id: \.id) { fragment in
                HStack(spacing: 12) {
                    if let imageUrl = fragment.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.cardBg)
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(fragment.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(2)

                        if let type = fragment.type {
                            Text(type.capitalized)
                                .font(.caption)
                                .foregroundColor(.transistorGreen)
                        }
                    }

                    Spacer()

                    Image(systemName: "play.circle")
                        .foregroundColor(.transistorGreen)
                        .font(.title3)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Tracks

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gespeelde muziek")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            ForEach(Array(tracks.enumerated()), id: \.offset) { _, track in
                HStack(spacing: 12) {
                    if let imageUrl = track.image_url_200x200, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.cardBg)
                        }
                        .frame(width: 44, height: 44)
                        .cornerRadius(6)
                    } else {
                        Image(systemName: "music.note")
                            .frame(width: 44, height: 44)
                            .background(Color.cardBg)
                            .cornerRadius(6)
                            .foregroundColor(.gray)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title ?? "Onbekend")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text(track.artist ?? "Onbekend")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    if let start = track.startdatetime, let parsed = parseTime(start) {
                        Text(timeFormatter.string(from: parsed))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Andere uitzendingen

    private var otherBroadcastsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Andere uitzendingen")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            ForEach(broadcastList.prefix(8), id: \.url) { item in
                NavigationLink(destination: BroadcastFromUrlView(channelId: channelId, broadcastUrl: item.url, title: item.title)) {
                    HStack(spacing: 12) {
                        if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(Color.cardBg)
                            }
                            .frame(width: 50, height: 50)
                            .cornerRadius(6)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .lineLimit(1)

                            HStack(spacing: 8) {
                                if let date = item.date {
                                    Text(date)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                if let time = item.time {
                                    Text(time)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Data loading

    private func loadAll() async {
        isLoading = true

        async let detailTask: () = loadDetail()
        async let tracksTask: () = loadTracks()
        async let listTask: () = loadBroadcastList()

        await detailTask
        await tracksTask
        await listTask

        isLoading = false
    }

    private func loadDetail() async {
        guard !channelId.isEmpty else { return }

        // First get the broadcast list to find the URL for this broadcast
        do {
            let list = try await NPOAPIService.shared.fetchBroadcastList(forChannel: channelId)
            // Match by title
            if let match = list.first(where: { $0.title.hasPrefix(broadcast.displayTitle) }) {
                detail = try await NPOAPIService.shared.fetchBroadcastDetail(
                    forChannel: channelId,
                    broadcastUrl: match.url
                )
                // Also store the list for "andere uitzendingen"
                broadcastList = list.filter { $0.title != match.title }
            }
        } catch {
            print("Error loading broadcast detail: \(error)")
        }
    }

    private func loadTracks() async {
        guard !channelId.isEmpty else { return }
        do {
            let allTracks = try await NPOAPIService.shared.fetchTracks(forChannel: channelId)
            tracks = allTracks.filter { track in
                guard let startStr = track.startdatetime, let trackStart = parseTime(startStr) else { return false }
                return trackStart >= broadcast.startTime && trackStart <= endTime
            }
        } catch {
            print("Error loading tracks: \(error)")
        }
    }

    private func loadBroadcastList() async {
        guard !channelId.isEmpty, broadcastList.isEmpty else { return }
        do {
            let list = try await NPOAPIService.shared.fetchBroadcastList(forChannel: channelId)
            if broadcastList.isEmpty {
                broadcastList = list.filter { !$0.title.hasPrefix(broadcast.displayTitle) }
            }
        } catch {
            print("Error loading broadcast list: \(error)")
        }
    }

    private func parseTime(_ str: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f.date(from: str)
    }
}

// MARK: - Show pagina (programma met alle uitzendingen)

struct ShowPageView: View {
    let channelId: String
    let programmeUrl: String
    let programmeName: String

    @State private var showPage: NPOShowPage?
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView().tint(.transistorGreen)
                    Text("Laden...")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else if let showPage {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    if let imageUrl = showPage.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.cardBg)
                        }
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    if let description = showPage.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }

                    // Uitzendingen
                    if !showPage.broadcasts.isEmpty {
                        Text("Uitzendingen")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        ForEach(showPage.broadcasts, id: \.url) { item in
                            NavigationLink(destination: BroadcastFromUrlView(channelId: channelId, broadcastUrl: item.url, title: item.title)) {
                                HStack(spacing: 12) {
                                    if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle().fill(Color.cardBg)
                                        }
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .lineLimit(2)

                                        HStack(spacing: 8) {
                                            if let date = item.date {
                                                Text(date)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            if let time = item.time {
                                                Text(time)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding(.vertical)
            } else {
                Text("Kon programma niet laden")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .background(Color.darkBg)
        .navigationTitle(programmeName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await loadShowPage() }
        }
    }

    private func loadShowPage() async {
        isLoading = true
        do {
            showPage = try await NPOAPIService.shared.fetchShowPage(
                forChannel: channelId,
                programmeUrl: programmeUrl
            )
        } catch {
            print("Error loading show page: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Broadcast laden via URL (voor "andere uitzendingen")

struct BroadcastFromUrlView: View {
    let channelId: String
    let broadcastUrl: String
    let title: String

    @EnvironmentObject var audioPlayer: AudioPlayerService
    @State private var detail: NPOBroadcastDetail?
    @State private var isLoading = true

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView().tint(.transistorGreen)
                    Text("Laden...")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else if let detail {
                VStack(alignment: .leading, spacing: 16) {
                    // Afbeelding
                    if let imageUrl = detail.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.cardBg)
                        }
                        .frame(height: 220)
                        .clipped()
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        // Show-link
                        if let progName = detail.programmeName {
                            HStack(spacing: 4) {
                                Text(progName)
                                    .font(.subheadline)
                                    .foregroundColor(.transistorGreen)
                            }
                        }

                        Text(detail.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        if let formattedDate = detail.formattedDate {
                            Label(formattedDate, systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.transistorGreen)
                        }

                        if !detail.presenters.isEmpty {
                            Label(detail.presenters.joined(separator: ", "), systemImage: "person.2")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)

                    // CTA
                    if let listenBackUrl = detail.listenBackUrl, !listenBackUrl.isEmpty {
                        Button(action: {
                            Task {
                                await audioPlayer.playOnDemand(
                                    url: listenBackUrl,
                                    title: detail.name,
                                    imageUrl: detail.imageUrl
                                )
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Luister terug")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.transistorGreen)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    // Beschrijving
                    if let description = detail.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Over deze uitzending")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(description)
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }

                    // Fragmenten
                    if !detail.fragments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fragmenten")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)

                            ForEach(detail.fragments, id: \.id) { fragment in
                                HStack(spacing: 12) {
                                    if let imageUrl = fragment.imageUrl, let url = URL(string: imageUrl) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle().fill(Color.cardBg)
                                        }
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                    }

                                    Text(fragment.name)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .lineLimit(2)

                                    Spacer()

                                    Image(systemName: "play.circle")
                                        .foregroundColor(.transistorGreen)
                                        .font(.title3)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical)
            } else {
                Text("Kon uitzending niet laden")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .background(Color.darkBg)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await loadDetail() }
        }
    }

    private func loadDetail() async {
        isLoading = true
        do {
            detail = try await NPOAPIService.shared.fetchBroadcastDetail(
                forChannel: channelId,
                broadcastUrl: broadcastUrl
            )
        } catch {
            print("Error loading broadcast from URL: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    BrowseView()
        .preferredColorScheme(.dark)
        .environmentObject(AudioPlayerService.shared)
}
