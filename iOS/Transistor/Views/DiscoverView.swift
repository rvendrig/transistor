import SwiftUI

struct DiscoverView: View {
    @State private var broadcasts: [NPOBroadcast] = []
    @State private var selectedBroadcast: NPOBroadcast?

    var body: some View {
        Group {
            if let selectedBroadcast = selectedBroadcast {
                NavigationView {
                    NPOItemDetailView(item: NPODataService.shared.getItemsForBroadcast(selectedBroadcast.id).first ?? NPOItem(id: "", broadcastId: "", title: "", description: nil, type: .segment, startTime: 0, duration: 0, guests: nil, topics: nil, artist: nil, musicTitle: nil, imageURL: nil, teaserText: nil), broadcast: selectedBroadcast)
                }
            } else {
                discoverList
            }
        }
        .onAppear {
            loadBroadcasts()
        }
        .navigationTitle("Discover")
    }

    var discoverList: some View {
        List {
            Section("Recent") {
                ForEach(broadcasts.prefix(10)) { broadcast in
                    NavigationLink(destination: NPOItemsView(broadcast: broadcast)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(broadcast.title)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

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
                                    ForEach(broadcast.topics.prefix(2), id: \.self) { topic in
                                        Text(topic)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.transistorGreen.opacity(0.2))
                                            .foregroundColor(.transistorGreen)
                                            .cornerRadius(2)
                                    }
                                    if broadcast.topics.count > 2 {
                                        Text("+\(broadcast.topics.count - 2)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(Color.darkBg)
    }

    func loadBroadcasts() {
        // Load from all channels
        let channels = NPODataService.shared.getAllChannels()
        var allBroadcasts: [NPOBroadcast] = []

        for channel in channels {
            let programs = NPODataService.shared.getProgramsForChannel(channel.id)
            for program in programs {
                let broadcasts = NPODataService.shared.getBroadcastsForProgram(program.id)
                allBroadcasts.append(contentsOf: broadcasts)
            }
        }

        self.broadcasts = allBroadcasts.sorted { $0.startTime > $1.startTime }
    }
}

#Preview {
    NavigationView {
        DiscoverView()
    }
    .preferredColorScheme(.dark)
}
