import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [NPOBroadcast] = []
    @State private var allBroadcasts: [NPOBroadcast] = []

    var filteredResults: [NPOBroadcast] {
        if searchText.isEmpty {
            return []
        }
        return allBroadcasts.filter { broadcast in
            broadcast.title.localizedCaseInsensitiveContains(searchText) ||
            broadcast.description?.localizedCaseInsensitiveContains(searchText) ?? false ||
            broadcast.topics.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search episodes...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.cardBg)
            .cornerRadius(8)
            .padding()

            // Results
            if searchText.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("Search for episodes")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Type keywords to find broadcasts and episodes")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if filteredResults.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("No results found")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Try different keywords")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List {
                    ForEach(filteredResults) { broadcast in
                        NavigationLink(destination: NPOItemsView(broadcast: broadcast)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(broadcast.title)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                Text(broadcast.broadcasterName)
                                    .font(.caption)
                                    .foregroundColor(.transistorGreen)

                                HStack(spacing: 12) {
                                    Label(
                                        broadcast.startTime.formatted(date: .abbreviated, time: .shortened),
                                        systemImage: "calendar"
                                    )
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                    Label(
                                        "\(broadcast.duration / 60) min",
                                        systemImage: "clock"
                                    )
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                }

                                if !broadcast.topics.isEmpty {
                                    HStack(spacing: 4) {
                                        ForEach(broadcast.topics.prefix(3), id: \.self) { topic in
                                            Text(topic)
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.transistorGreen.opacity(0.2))
                                                .foregroundColor(.transistorGreen)
                                                .cornerRadius(2)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Search")
        .background(Color.darkBg)
        .onAppear {
            loadAllBroadcasts()
        }
    }

    func loadAllBroadcasts() {
        let channels = NPODataService.shared.getAllChannels()
        var all: [NPOBroadcast] = []

        for channel in channels {
            let programs = NPODataService.shared.getProgramsForChannel(channel.id)
            for program in programs {
                let broadcasts = NPODataService.shared.getBroadcastsForProgram(program.id)
                all.append(contentsOf: broadcasts)
            }
        }

        self.allBroadcasts = all
    }
}

#Preview {
    NavigationView {
        SearchView()
    }
    .preferredColorScheme(.dark)
}
