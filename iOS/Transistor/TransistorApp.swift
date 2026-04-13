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
            NowPlayingView()
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

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToBroadcast = Notification.Name("navigateToBroadcast")
}

// MARK: - Color Extension
extension Color {
    static let transistorGreen = Color(red: 0.114, green: 0.733, blue: 0.329) // #1DB954
    static let darkBg = Color(red: 0.071, green: 0.071, blue: 0.071) // #121212
    static let cardBg = Color(red: 0.122, green: 0.122, blue: 0.122) // #1F1F1F
}
