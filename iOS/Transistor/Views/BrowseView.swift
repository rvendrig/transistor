import SwiftUI

struct BrowseView: View {
    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var podcastProvider = PodcastFeedProvider()
    @State private var showAddPodcast = false
    @State private var podcastURL = ""
    @State private var isLoadingPodcast = false
    @State private var podcastError: String?
    @State private var channelConfigMap: [String: ChannelConfig] = [:]
    @State private var navigateBroadcast: Broadcast?
    @State private var navigateChannelId: String = ""

    /// Channels grouped by networkId, with the provider name as key
    private var channelsByNetwork: [(networkName: String, channels: [Channel])] {
        let grouped = Dictionary(grouping: viewModel.channels, by: { $0.networkId })
        let store = ProviderStore.shared

        // Build ordered list: use provider name as section title
        var result: [(String, [Channel])] = []
        for provider in store.allActiveProviders() {
            let networkId = provider.id  // networkId matches provider id
            if let channels = grouped[networkId], !channels.isEmpty {
                result.append((provider.name, channels))
            }
        }
        // Any remaining networks not matched to a provider
        let coveredIds = Set(result.flatMap { $0.1.map { $0.networkId } })
        for (networkId, channels) in grouped where !coveredIds.contains(networkId) {
            result.append((networkId, channels))
        }
        return result
    }

    private func hasCapability(_ channelId: String, _ capability: ChannelCapability) -> Bool {
        channelConfigMap[channelId]?.capabilities.contains(capability) ?? false
    }

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

                        ForEach(channelsByNetwork, id: \.networkName) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section.networkName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(Array(section.channels.enumerated()), id: \.element.id) { index, channel in
                                        Group {
                                            if hasCapability(channel.id, .schedule) {
                                                NavigationLink(value: channel) {
                                                    channelCard(channel: channel, index: index, total: section.channels.count)
                                                }
                                            } else {
                                                NavigationLink(destination: LiveOnlyChannelView(channel: channel, config: channelConfigMap[channel.id])) {
                                                    channelCard(channel: channel, index: index, total: section.channels.count)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // MARK: Podcasts sectie
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Podcasts")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { showAddPodcast = true }) {
                                Label("Voeg toe", systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.transistorGreen)
                            }
                        }
                        .padding(.horizontal)

                        if podcastProvider.feeds.isEmpty {
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
                            ForEach(podcastProvider.feeds, id: \.id) { podcast in
                                NavigationLink(destination: PodcastDetailView(podcast: podcast, provider: podcastProvider)) {
                                    HStack(spacing: 12) {
                                        if let imageUrl = podcast.image, let url = URL(string: imageUrl) {
                                            AsyncImage(url: url) { image in
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Rectangle().fill(Color.cardBg)
                                            }
                                            .frame(width: 50, height: 50)
                                            .cornerRadius(8)
                                        } else {
                                            Image(systemName: "mic.fill")
                                                .foregroundColor(.transistorGreen)
                                                .frame(width: 50, height: 50)
                                                .background(Color.cardBg)
                                                .cornerRadius(8)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(podcast.title)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                            Text("\(podcast.episodes.count) afleveringen")
                                                .font(.caption)
                                                .foregroundColor(.gray)
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
            .sheet(isPresented: $showAddPodcast) {
                AddPodcastSheet(
                    podcastURL: $podcastURL,
                    isLoading: $isLoadingPodcast,
                    error: $podcastError,
                    onAdd: { url in
                        isLoadingPodcast = true
                        podcastError = nil
                        Task {
                            do {
                                try await podcastProvider.addFeed(url)
                                isLoadingPodcast = false
                                showAddPodcast = false
                                podcastURL = ""
                            } catch {
                                podcastError = error.localizedDescription
                                isLoadingPodcast = false
                            }
                        }
                    }
                )
            }
            .onAppear {
                // Populate channel config map from all providers
                var configs: [String: ChannelConfig] = [:]
                for provider in ProviderStore.shared.allActiveProviders() {
                    for config in provider.channelConfigs() {
                        configs[config.id] = config
                    }
                }
                channelConfigMap = configs

                Task {
                    await viewModel.loadChannels()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToBroadcast)) { notification in
                if let broadcast = notification.userInfo?["broadcast"] as? Broadcast,
                   let channelId = notification.userInfo?["channelId"] as? String {
                    navigateChannelId = channelId
                    navigateBroadcast = broadcast
                }
            }
            .sheet(item: $navigateBroadcast) { broadcast in
                NavigationStack {
                    BroadcastDetailView(broadcast: broadcast, channelId: navigateChannelId)
                }
                .environmentObject(AudioPlayerService.shared)
            }
        }
    }

    @ViewBuilder
    private func channelCard(channel: Channel, index: Int, total: Int) -> some View {
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
                    Color(hue: Double(index) / max(Double(total), 1), saturation: 0.7, brightness: 0.5),
                    Color(hue: Double(index) / max(Double(total), 1), saturation: 0.7, brightness: 0.3),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - Live-only channel (geen programma-informatie)

struct LiveOnlyChannelView: View {
    let channel: Channel
    let config: ChannelConfig?
    @EnvironmentObject var audioPlayer: AudioPlayerService

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(.transistorGreen)

            Text(channel.currentTitle)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(channel.description)
                .font(.subheadline)
                .foregroundColor(.gray)

            if let streamUrl = config?.liveStreamUrl {
                Button(action: {
                    Task {
                        await audioPlayer.playLive(
                            url: streamUrl,
                            title: channel.currentTitle,
                            imageUrl: channel.logo
                        )
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Luister live")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.transistorGreen)
                    .cornerRadius(25)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.darkBg)
        .navigationTitle(channel.currentTitle)
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
            .frame(maxHeight: .infinity)
        }
        .navigationTitle(channel.currentTitle)
        .navigationBarTitleDisplayMode(.inline)
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

    private func dateLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Vandaag" }
        if calendar.isDateInYesterday(date) { return "Gisteren" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "EEE d MMM"  // "Za 11 apr"
        return f.string(from: date).replacingOccurrences(of: ".", with: "")
    }

    private func parseTimeRange(_ timeStr: String?, on date: Date) -> (Date, Int) {
        guard let timeStr else { return (date, 0) }
        // Format: "14:00 - 15:00"
        let parts = timeStr.components(separatedBy: " - ")
        guard parts.count == 2 else { return (date, 0) }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        func parseHHMM(_ str: String) -> Date? {
            let hm = str.trimmingCharacters(in: .whitespaces).components(separatedBy: ":")
            guard hm.count == 2, let h = Int(hm[0]), let m = Int(hm[1]) else { return nil }
            var dc = components
            dc.hour = h
            dc.minute = m
            return calendar.date(from: dc)
        }

        guard let start = parseHHMM(parts[0]) else { return (date, 0) }
        let end = parseHHMM(parts[1]) ?? start
        let duration = max(0, Int(end.timeIntervalSince(start)))
        return (start, duration)
    }

    private func loadSchedule() async {
        guard let provider = viewModel.providerStore.provider(byId: channel.providerId) else { return }
        isLoading = true
        do {
            if Calendar.current.isDateInToday(selectedDate) {
                broadcasts = try await provider.fetchBroadcasts(forChannel: channel.id)
            } else {
                // Voor andere dagen: gebruik uitzendingen-lijst en filter op datum
                let list = try await NPOAPIService.shared.fetchBroadcastList(forChannel: channel.id)

                // Filter: match "Gisteren", "Vandaag", of datumformat "Za 11 apr"
                let targetLabel = dateLabel(for: selectedDate)
                let filtered = list.filter { item in
                    guard let date = item.date else { return false }
                    return date.lowercased() == targetLabel.lowercased()
                }

                // Als er geen match is, toon alles (de pagina geeft ~20 items over meerdere dagen)
                let items = filtered.isEmpty ? list : filtered

                broadcasts = items.compactMap { item in
                    let (startTime, duration) = parseTimeRange(item.time, on: selectedDate)
                    return Broadcast(
                        id: item.url,
                        providerId: "npo",
                        title: item.title,
                        showId: nil,
                        channelId: channel.id,
                        seasonId: nil,
                        startTime: startTime,
                        duration: duration,
                        description: nil,
                        image: item.imageUrl,
                        audioUrl: nil,
                        titleOverride: nil,
                        detailUrl: nil
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
                            imageUrl: detail?.imageUrl ?? broadcast.image,
                            broadcast: broadcast,
                            channelId: channelId
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
                            imageUrl: detail?.imageUrl ?? broadcast.image,
                            broadcast: broadcast,
                            channelId: channelId
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

            ForEach(Array(fragments.enumerated()), id: \.element.id) { index, fragment in
                Button(action: {
                    playFragment(fragment, index: index, totalFragments: fragments.count)
                }) {
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

                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.transistorGreen)
                            .font(.title3)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top, 8)
    }

    private func playFragment(_ fragment: NPOFragment, index: Int, totalFragments: Int) {
        // Speel de terugluister-MP3 van de uitzending af op het geschatte tijdstip
        guard let listenBackUrl = detail?.listenBackUrl, !listenBackUrl.isEmpty else { return }

        // Schat het tijdstip: verdeel de uitzending evenredig over de fragmenten
        let estimatedOffset = totalFragments > 1
            ? Double(index) / Double(totalFragments) * Double(broadcast.duration)
            : 0

        Task {
            await audioPlayer.playOnDemand(
                url: listenBackUrl,
                title: fragment.name,
                imageUrl: fragment.imageUrl ?? detail?.imageUrl ?? broadcast.image,
                source: "npo"
            )
            // Seek naar het geschatte tijdstip na korte delay (wacht op buffering)
            if estimatedOffset > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
                audioPlayer.seek(to: estimatedOffset)
            }
        }
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

        do {
            // Direct URL beschikbaar → gebruik die
            if let detailUrl = broadcast.detailUrl, !detailUrl.isEmpty {
                detail = try await NPOAPIService.shared.fetchBroadcastDetail(
                    forChannel: channelId,
                    broadcastUrl: detailUrl
                )
                let list = try await NPOAPIService.shared.fetchBroadcastList(forChannel: channelId)
                broadcastList = list.filter { $0.url != detailUrl }
                return
            }

            // Fallback: zoek op titel
            let list = try await NPOAPIService.shared.fetchBroadcastList(forChannel: channelId)
            let title = broadcast.displayTitle.lowercased()

            let match = list.first(where: { $0.title.lowercased().hasPrefix(title) })
                ?? list.first(where: { $0.title.lowercased().contains(title) })
                ?? list.first(where: { title.contains($0.title.lowercased()) })

            if let match {
                detail = try await NPOAPIService.shared.fetchBroadcastDetail(
                    forChannel: channelId,
                    broadcastUrl: match.url
                )
                broadcastList = list.filter { $0.url != match.url }
            } else {
                broadcastList = list
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

// MARK: - Podcast toevoegen sheet

struct AddPodcastSheet: View {
    @Binding var podcastURL: String
    @Binding var isLoading: Bool
    @Binding var error: String?
    let onAdd: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Voeg een podcast toe")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                TextField("RSS feed URL", text: $podcastURL)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Button(action: { onAdd(podcastURL) }) {
                    if isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Text("Toevoegen")
                    }
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(podcastURL.isEmpty ? Color.gray : Color.transistorGreen)
                .cornerRadius(12)
                .disabled(podcastURL.isEmpty || isLoading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Voorbeelden:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    ForEach(["https://podcast.npo.nl/feed/argos.xml",
                             "https://feeds.acast.com/public/shows/ologies"], id: \.self) { example in
                        Button(action: { podcastURL = example }) {
                            Text(example)
                                .font(.caption)
                                .foregroundColor(.transistorGreen)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color.darkBg)
        }
    }
}

// MARK: - Podcast detail (episodes lijst)

struct PodcastDetailView: View {
    let podcast: PodcastFeed
    let provider: PodcastFeedProvider
    @EnvironmentObject var audioPlayer: AudioPlayerService

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        List {
            // Header
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if let imageUrl = podcast.image, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.cardBg)
                        }
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(12)
                    }

                    Text(podcast.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .listRowBackground(Color.clear)

            // Episodes
            Section(header: Text("\(podcast.episodes.count) afleveringen").foregroundColor(.white)) {
                ForEach(podcast.episodes) { episode in
                    Button(action: {
                        Task {
                            await audioPlayer.playOnDemand(
                                url: episode.audioUrl ?? "",
                                title: episode.title,
                                imageUrl: episode.image ?? podcast.image,
                                source: "podcast"
                            )
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(episode.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .lineLimit(2)

                            HStack(spacing: 8) {
                                Text(dateFormatter.string(from: episode.publishDate))
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                if episode.duration > 0 {
                                    Text("\(episode.duration / 60) min")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            if let desc = episode.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(3)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(podcast.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.darkBg)
    }
}

#Preview {
    BrowseView()
        .preferredColorScheme(.dark)
        .environmentObject(AudioPlayerService.shared)
}
