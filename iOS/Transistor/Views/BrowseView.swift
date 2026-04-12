import SwiftUI

struct BrowseView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Kies een zender")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal)

                    if viewModel.isLoadingChannels {
                        HStack {
                            ProgressView()
                                .tint(.transistorGreen)
                            Text("Laden...")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(Array(viewModel.channels.enumerated()), id: \.element.id) { index, channel in
                            NavigationLink(value: channel) {
                                VStack(alignment: .leading, spacing: 8) {
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
                                .frame(height: 120)
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

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        List {
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .tint(.transistorGreen)
                    Text("Laden...")
                        .foregroundColor(.gray)
                }
            }

            ForEach(viewModel.broadcasts) { broadcast in
                NavigationLink(value: broadcast) {
                    HStack(alignment: .top, spacing: 12) {
                        // Tijdblok
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

                        // Programma-info
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

                            if let description = broadcast.description, !description.isEmpty {
                                Text(description)
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
        .navigationTitle(channel.currentTitle)
        .background(Color.darkBg)
        .onAppear {
            Task {
                await loadSchedule()
            }
        }
    }

    private func isNow(_ broadcast: Broadcast) -> Bool {
        let now = Date()
        let endTime = broadcast.startTime.addingTimeInterval(Double(broadcast.duration))
        return broadcast.startTime <= now && now <= endTime
    }

    private func loadSchedule() async {
        guard let provider = viewModel.providerStore.provider(byId: channel.providerId) else { return }
        viewModel.isLoading = true
        do {
            viewModel.broadcasts = try await provider.fetchBroadcasts(forChannel: channel.id)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
        viewModel.isLoading = false
    }
}

// MARK: - Broadcast detail

struct BroadcastDetailView: View {
    let broadcast: Broadcast
    let channelId: String

    @State private var tracks: [NPOTrackAPI] = []
    @State private var isLoadingTracks = false

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var endTime: Date {
        broadcast.startTime.addingTimeInterval(Double(broadcast.duration))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header met afbeelding
                if let imageUrl = broadcast.image, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.cardBg)
                    }
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Titel en info
                VStack(alignment: .leading, spacing: 8) {
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

                        Label(
                            "\(broadcast.duration / 60) min",
                            systemImage: "timer"
                        )
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }

                    if let description = broadcast.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.gray)
                    }

                    if isNow {
                        Label("Nu op de radio", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.transistorGreen)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal)

                // Luister-knop
                if let audioUrl = broadcast.audioUrl, let _ = URL(string: audioUrl) {
                    Button(action: {
                        // TODO: start playback via AudioPlayerService
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Luister live")
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

                // Gespeelde tracks
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

                                if let start = track.startdatetime {
                                    let parsed = parseTime(start)
                                    if let parsed {
                                        Text(timeFormatter.string(from: parsed))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                } else if isLoadingTracks {
                    HStack {
                        ProgressView().tint(.transistorGreen)
                        Text("Tracks laden...")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.darkBg)
        .navigationTitle(broadcast.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await loadTracks() }
        }
    }

    private var isNow: Bool {
        let now = Date()
        return broadcast.startTime <= now && now <= endTime
    }

    private func loadTracks() async {
        guard !channelId.isEmpty else { return }
        isLoadingTracks = true
        do {
            let allTracks = try await NPOAPIService.shared.fetchTracks(forChannel: channelId)
            // Filter tracks die binnen deze uitzending vallen
            tracks = allTracks.filter { track in
                guard let startStr = track.startdatetime, let trackStart = parseTime(startStr) else { return false }
                return trackStart >= broadcast.startTime && trackStart <= endTime
            }
        } catch {
            print("Error loading tracks: \(error)")
        }
        isLoadingTracks = false
    }

    private func parseTime(_ str: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f.date(from: str)
    }
}

#Preview {
    BrowseView()
        .preferredColorScheme(.dark)
}
