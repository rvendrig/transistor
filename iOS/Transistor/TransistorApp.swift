import SwiftUI

@main
struct TransistorApp: App {
    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var audioPlayer = AudioPlayerService.shared

    init() {
        ProviderStore.shared.registerProvider(NPOProvider())
        ProviderStore.shared.registerProvider(TalpaProvider())
    }

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
            TabView {
                BrowseView()
                    .tabItem {
                        Label("Browse", systemImage: "square.grid.2x2")
                    }

                PlaylistsView()
                    .tabItem {
                        Label("Playlists", systemImage: "list.bullet")
                    }

                LogView(viewModel: viewModel)
                    .tabItem {
                        Label("Log", systemImage: "clock.arrow.circlepath")
                    }

                SearchView()
                    .tabItem {
                        Label("Zoeken", systemImage: "magnifyingglass")
                    }

                SettingsView()
                    .tabItem {
                        Label("Instellingen", systemImage: "gearshape")
                    }
            }
            .preferredColorScheme(.dark)

                // Mini player
                if audioPlayer.currentTitle != nil {
                    MiniPlayerView()
                        .padding(.bottom, 49) // boven de tab bar
                }
            }
            .environmentObject(audioPlayer)
        }
    }
}

// MARK: - Mini Player

struct MiniPlayerView: View {
    @EnvironmentObject var player: AudioPlayerService
    @State private var showFullPlayer = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar (thin line at top, only for on-demand)
            if !player.isLiveStream && player.duration > 0 {
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.transistorGreen)
                        .frame(width: geo.size.width * CGFloat(player.currentTime / max(player.duration, 1)))
                }
                .frame(height: 2)
                .background(Color.gray.opacity(0.3))
            }

            HStack(spacing: 12) {
                // Artwork — tap opens full player
                Button(action: { showFullPlayer = true }) {
                    HStack(spacing: 12) {
                        if let imageUrl = player.currentImageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(Color.darkBg)
                            }
                            .frame(width: 40, height: 40)
                            .cornerRadius(6)
                        } else {
                            Image(systemName: player.isLiveStream ? "antenna.radiowaves.left.and.right" : "music.note")
                                .frame(width: 40, height: 40)
                                .background(Color.darkBg)
                                .cornerRadius(6)
                                .foregroundColor(.transistorGreen)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.currentTitle ?? "")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .lineLimit(1)

                            if player.isLiveStream {
                                Text("LIVE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.transistorGreen)
                            } else if player.duration > 0 {
                                Text("\(formatTime(player.currentTime)) / \(formatTime(player.duration))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            } else if player.isBuffering {
                                Text("Bufferen...")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                Spacer()

                // Controls
                if player.isBuffering {
                    ProgressView()
                        .tint(.transistorGreen)
                } else {
                    Button(action: {
                        if player.isPlaying { player.pause() } else { player.resume() }
                    }) {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    Button(action: { player.stop() }) {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.cardBg)
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView()
                .environmentObject(player)
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Full Player

struct FullPlayerView: View {
    @EnvironmentObject var player: AudioPlayerService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Drag handle
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            Spacer()

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
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
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

            // Seek bar (only for on-demand)
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
                // Rewind 15s (only on-demand)
                if !player.isLiveStream {
                    Button(action: { player.seek(to: max(0, player.currentTime - 15)) }) {
                        Image(systemName: "gobackward.15")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }

                // Play/Pause
                Button(action: {
                    if player.isPlaying { player.pause() } else { player.resume() }
                }) {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.transistorGreen)
                }

                // Forward 30s (only on-demand)
                if !player.isLiveStream {
                    Button(action: { player.seek(to: min(player.duration, player.currentTime + 30)) }) {
                        Image(systemName: "goforward.30")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }

            // Speed control (only on-demand)
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

            Spacer()

            // Stop button
            Button(action: {
                player.stop()
                dismiss()
            }) {
                Text("Stop")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 24)
        }
        .background(Color.darkBg)
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

// MARK: - Color Extension
extension Color {
    static let transistorGreen = Color(red: 0.114, green: 0.733, blue: 0.329) // #1DB954
    static let darkBg = Color(red: 0.071, green: 0.071, blue: 0.071) // #121212
    static let cardBg = Color(red: 0.122, green: 0.122, blue: 0.122) // #1F1F1F
}
