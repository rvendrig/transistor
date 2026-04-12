import SwiftUI

@main
struct TransistorApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                NPOChannelsViewV2()
                    .tabItem {
                        Label("NPO", systemImage: "radio.fill")
                    }

                DiscoverView()
                    .tabItem {
                        Label("Discover", systemImage: "sparkles")
                    }

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
