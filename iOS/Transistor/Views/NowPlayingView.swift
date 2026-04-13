import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var player: AudioPlayerService
    @Environment(\.dismiss) var dismiss

    @State private var detail: NPOBroadcastDetail?
    @State private var tracks: [NPOTrackAPI] = []
    @State private var broadcastList: [NPOBroadcastListItem] = []
    @State private var isLoadingDetail = false
    @State private var hasScrolled = false

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var broadcast: Broadcast? { player.currentBroadcast }
    private var channelId: String { player.currentChannelId ?? "" }

    var body: some View {
        VStack(spacing: 0) {
            // Sticky compact transport bar (verschijnt bij scrollen)
            if hasScrolled {
                compactTransportBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            ScrollView {
                VStack(spacing: 16) {
                    // === PLAYER SECTIE ===
                    playerSection

                    // === DETAIL SECTIE (altijd tonen als broadcast bekend) ===
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)

                    if broadcast != nil {
                        detailSection
                    } else if detail != nil {
                        // Detail geladen maar geen broadcast-object (bijv. via fragment)
                        detailSection
                    } else if isLoadingDetail {
                        HStack {
                            ProgressView().tint(.transistorGreen)
                            Text("Details laden...").foregroundColor(.gray).font(.caption)
                        }
                        .padding()
                    }

                    // Stop
                    Button(action: { player.stop(); dismiss() }) {
                        Text("Stop")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 24)
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.onChange(of: geo.frame(in: .named("nowplaying")).minY) { _, newValue in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                hasScrolled = newValue < -250
                            }
                        }
                    }
                )
            }
            .coordinateSpace(name: "nowplaying")
        }
        .background(Color.darkBg)
        .onAppear {
            Task { await loadDetail() }
        }
        .onChange(of: player.currentBroadcast) {
            // Herlaad detail als de broadcast verandert
            Task { await loadDetail() }
        }
    }

    // MARK: - Compact Transport Bar (sticky)

    private var compactTransportBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Mini artwork
                if let imageUrl = player.currentImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Color.cardBg)
                    }
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
                } else {
                    Image(systemName: player.isLiveStream ? "antenna.radiowaves.left.and.right" : "music.note")
                        .frame(width: 40, height: 40)
                        .background(Color.cardBg)
                        .cornerRadius(6)
                        .foregroundColor(.transistorGreen)
                }

                // Titel
                Text(player.currentTitle ?? "")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                // Controls
                if !player.isLiveStream {
                    Button(action: { player.seek(to: max(0, player.currentTime - 15)) }) {
                        Image(systemName: "gobackward.15")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }

                Button(action: {
                    if player.isPlaying { player.pause() } else { player.resume() }
                }) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }

                if !player.isLiveStream {
                    Button(action: { player.seek(to: min(player.duration, player.currentTime + 30)) }) {
                        Image(systemName: "goforward.30")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Thin seek bar
            if !player.isLiveStream && player.duration > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.gray.opacity(0.3))
                        Rectangle()
                            .fill(Color.transistorGreen)
                            .frame(width: geo.size.width * CGFloat(player.currentTime / max(player.duration, 1)))
                    }
                }
                .frame(height: 3)
            }
        }
        .background(Color.cardBg)
    }

    // MARK: - Full Player Section

    private var playerSection: some View {
        VStack(spacing: 20) {
            // Drag handle
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            // Artwork
            if let imageUrl = player.currentImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.cardBg)
                }
                .frame(width: 280, height: 280)
                .cornerRadius(16)
                .shadow(radius: 10)
            } else {
                Image(systemName: player.isLiveStream ? "antenna.radiowaves.left.and.right" : "music.note")
                    .font(.system(size: 80))
                    .foregroundColor(.transistorGreen)
                    .frame(width: 280, height: 280)
                    .background(Color.cardBg)
                    .cornerRadius(16)
            }

            // Title + source
            VStack(spacing: 6) {
                Text(player.currentTitle ?? "")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                if player.isLiveStream {
                    HStack(spacing: 4) {
                        Circle().fill(Color.red).frame(width: 8, height: 8)
                        Text("LIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.transistorGreen)
                    }
                } else if let source = player.currentSource {
                    Text(source)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)

            // Seek bar
            if !player.isLiveStream && player.duration > 0 {
                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { player.currentTime },
                            set: { player.seek(to: $0) }
                        ),
                        in: 0...max(player.duration, 1)
                    )
                    .tint(.transistorGreen)

                    HStack {
                        Text(formatTime(player.currentTime))
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("-\(formatTime(max(0, player.duration - player.currentTime)))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)
            }

            // Playback controls
            HStack(spacing: 40) {
                if !player.isLiveStream {
                    Button(action: { player.seek(to: max(0, player.currentTime - 15)) }) {
                        Image(systemName: "gobackward.15")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }

                Button(action: {
                    if player.isPlaying { player.pause() } else { player.resume() }
                }) {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.transistorGreen)
                }

                if !player.isLiveStream {
                    Button(action: { player.seek(to: min(player.duration, player.currentTime + 30)) }) {
                        Image(systemName: "goforward.30")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }

            // Speed control
            if !player.isLiveStream {
                HStack(spacing: 16) {
                    ForEach([0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
                        Button(action: { player.setPlaybackRate(Float(rate)) }) {
                            Text(rate == 1.0 ? "1x" : "\(rate, specifier: "%.2g")x")
                                .font(.caption)
                                .fontWeight(player.playbackRate == Float(rate) ? .bold : .regular)
                                .foregroundColor(player.playbackRate == Float(rate) ? .transistorGreen : .gray)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(player.playbackRate == Float(rate) ? Color.transistorGreen.opacity(0.15) : Color.clear)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Detail Section

    @ViewBuilder
    private var detailSection: some View {
        if let broadcast = player.currentBroadcast {
            let channelId = player.currentChannelId ?? ""

            VStack(alignment: .leading, spacing: 16) {
                // Show link + tijden
                VStack(alignment: .leading, spacing: 8) {
                    if let progName = detail?.programmeName {
                        HStack(spacing: 4) {
                            Text(progName)
                                .font(.subheadline)
                                .foregroundColor(.transistorGreen)
                        }
                    }

                    let endTime = broadcast.startTime.addingTimeInterval(Double(broadcast.duration))
                    HStack(spacing: 16) {
                        Label(
                            "\(timeFormatter.string(from: broadcast.startTime)) – \(timeFormatter.string(from: endTime))",
                            systemImage: "clock"
                        )
                        .font(.subheadline)
                        .foregroundColor(.transistorGreen)

                        if broadcast.duration > 0 {
                            Label("\(broadcast.duration / 60) min", systemImage: "timer")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    if let detail, !detail.presenters.isEmpty {
                        Label(detail.presenters.joined(separator: ", "), systemImage: "person.2")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fragmenten")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        ForEach(Array(detail.fragments.enumerated()), id: \.element.id) { index, fragment in
                            Button(action: {
                                playFragment(fragment, index: index, total: detail.fragments.count, broadcast: broadcast)
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

                // Tracks
                if !tracks.isEmpty {
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

                // Andere uitzendingen
                if !broadcastList.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Andere uitzendingen")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        ForEach(broadcastList.prefix(5), id: \.url) { item in
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
                                            Text(date).font(.caption).foregroundColor(.gray)
                                        }
                                        if let time = item.time {
                                            Text(time).font(.caption).foregroundColor(.gray)
                                        }
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                }
            }

            if isLoadingDetail {
                HStack {
                    ProgressView().tint(.transistorGreen)
                    Text("Details laden...").foregroundColor(.gray).font(.caption)
                }
                .padding()
            }
        }
    }

    // MARK: - Helpers

    private func loadDetail() async {
        guard let broadcast = player.currentBroadcast,
              let channelId = player.currentChannelId,
              !channelId.isEmpty else { return }

        isLoadingDetail = true

        async let detailTask: () = loadBroadcastDetail(channelId: channelId, broadcast: broadcast)
        async let tracksTask: () = loadTracks(channelId: channelId, broadcast: broadcast)

        await detailTask
        await tracksTask

        isLoadingDetail = false
    }

    private func loadBroadcastDetail(channelId: String, broadcast: Broadcast) async {
        do {
            // Direct URL beschikbaar → gebruik die
            if let detailUrl = broadcast.detailUrl, !detailUrl.isEmpty {
                detail = try await NPOAPIService.shared.fetchBroadcastDetail(
                    forChannel: channelId,
                    broadcastUrl: detailUrl
                )
                // Laad ook de lijst voor "andere uitzendingen"
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

    private func loadTracks(channelId: String, broadcast: Broadcast) async {
        do {
            let allTracks = try await NPOAPIService.shared.fetchTracks(forChannel: channelId)
            let endTime = broadcast.startTime.addingTimeInterval(Double(broadcast.duration))
            tracks = allTracks.filter { track in
                guard let startStr = track.startdatetime, let trackStart = parseTime(startStr) else { return false }
                return trackStart >= broadcast.startTime && trackStart <= endTime
            }
        } catch {
            print("Error loading tracks: \(error)")
        }
    }

    private func playFragment(_ fragment: NPOFragment, index: Int, total: Int, broadcast: Broadcast) {
        guard let listenBackUrl = detail?.listenBackUrl, !listenBackUrl.isEmpty else { return }
        let estimatedOffset = total > 1
            ? Double(index) / Double(total) * Double(broadcast.duration)
            : 0

        Task {
            await player.playOnDemand(
                url: listenBackUrl,
                title: fragment.name,
                imageUrl: fragment.imageUrl ?? detail?.imageUrl ?? broadcast.image,
                source: "npo",
                broadcast: broadcast,
                channelId: player.currentChannelId
            )
            if estimatedOffset > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                player.seek(to: estimatedOffset)
            }
        }
    }

    private func parseTime(_ str: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f.date(from: str)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let total = Int(seconds)
        if total >= 3600 {
            return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
        }
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
