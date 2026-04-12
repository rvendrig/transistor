import SwiftUI

@main
struct TransistorApp: App {
    @State private var selectedTab: Int = 0

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                // NPO Tab
                NavigationView {
                    NPOChannelsView()
                }
                .tabItem {
                    Label("NPO", systemImage: "radio.fill")
                }
                .tag(0)

                // Discover Tab
                NavigationView {
                    DiscoverView()
                }
                .tabItem {
                    Label("Discover", systemImage: "home.fill")
                }
                .tag(1)

                // Search Tab
                NavigationView {
                    SearchView()
                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(2)
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Color Theme

extension Color {
    static let transistorGreen = Color(red: 0.114, green: 0.733, blue: 0.329) // #1DB954
    static let darkBg = Color(red: 0.071, green: 0.071, blue: 0.071) // #121212
    static let cardBg = Color(red: 0.122, green: 0.122, blue: 0.122) // #1F1F1F
}
