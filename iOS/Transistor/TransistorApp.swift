import SwiftUI

@main
struct TransistorApp: App {
    @StateObject private var viewModel = ContentViewModel()

    init() {
        ProviderStore.shared.registerProvider(NPOProvider())
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                // Browse Channels
                BrowseView()
                    .tabItem {
                        Label("Browse", systemImage: "square.grid.2x2")
                    }

                // Live Guide/Schedule
                ScheduleView()
                    .tabItem {
                        Label("Guide", systemImage: "calendar")
                    }

                // Playlists
                PlaylistsView()
                    .tabItem {
                        Label("Playlists", systemImage: "list.bullet")
                    }

                // Listening Hub (History + Commands)
                ListeningHubView(viewModel: viewModel)
                    .tabItem {
                        Label("Hub", systemImage: "sparkles")
                    }

                // Providers
                ProvidersView()
                    .tabItem {
                        Label("Providers", systemImage: "network")
                    }

                // Search
                SearchView()
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Color Extension
extension Color {
    static let transistorGreen = Color(red: 0.114, green: 0.733, blue: 0.329) // #1DB954
    static let darkBg = Color(red: 0.071, green: 0.071, blue: 0.071) // #121212
    static let cardBg = Color(red: 0.122, green: 0.122, blue: 0.122) // #1F1F1F
}
