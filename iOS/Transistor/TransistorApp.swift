import SwiftUI

@main
struct TransistorApp: App {
    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var audioPlayer = AudioPlayerService.shared

    init() {
        ProviderStore.shared.registerProvider(NPOProvider())
        ProviderStore.shared.registerProvider(BBCProvider())
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

    var body: some View {
        HStack(spacing: 12) {
            // Artwork
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

            // Info
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
                } else if player.isBuffering {
                    Text("Bufferen...")
                        .font(.caption)
                        .foregroundColor(.gray)
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
        .background(Color.cardBg)
    }
}

// MARK: - Color Extension
extension Color {
    static let transistorGreen = Color(red: 0.114, green: 0.733, blue: 0.329) // #1DB954
    static let darkBg = Color(red: 0.071, green: 0.071, blue: 0.071) // #121212
    static let cardBg = Color(red: 0.122, green: 0.122, blue: 0.122) // #1F1F1F
}
