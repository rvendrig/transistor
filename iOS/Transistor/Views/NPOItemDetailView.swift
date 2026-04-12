import SwiftUI

struct NPOItemDetailView: View {
    let item: NPOItem
    let broadcast: NPOBroadcast
    @StateObject private var viewModel = NPOViewModel()
    @State private var showAddToPlaylist = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                // Type Badge
                HStack {
                    Label(itemTypeLabel(item.type), systemImage: itemTypeIcon(item.type))
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.transistorGreen)
                        .cornerRadius(20)
                    Spacer()
                }
                .padding(.horizontal)

                // Duration and Time
                VStack(alignment: .leading, spacing: 8) {
                    Label("\(item.duration / 60) minutes", systemImage: "clock.fill")
                        .foregroundColor(.gray)

                    if let startOffset = item.startOffset {
                        Label("Starts at \(startOffset / 60):\(String(format: "%02d", startOffset % 60))", systemImage: "timer")
                            .foregroundColor(.gray)
                    }

                    Label(broadcast.title, systemImage: "radio.fill")
                        .foregroundColor(.transistorGreen)
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .padding()
                .background(Color.cardBg)
                .cornerRadius(8)
                .padding(.horizontal)

                // Description
                if let description = item.description {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(description)
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Color.cardBg)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                // Guests
                if !item.guests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Guests & Participants")
                            .font(.headline)
                            .foregroundColor(.white)

                        ForEach(item.guests, id: \.self) { guest in
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.transistorGreen)
                                Text(guest)
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.cardBg)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                // Topics
                if !item.topics.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Topics")
                            .font(.headline)
                            .foregroundColor(.white)

                        Wrap(items: item.topics, id: \.self) { topic in
                            Text(topic)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.transistorGreen.opacity(0.3))
                                .cornerRadius(16)
                        }
                    }
                    .padding()
                    .background(Color.cardBg)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.darkBg)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddToPlaylist = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.transistorGreen)
                }
            }
        }
        .sheet(isPresented: $showAddToPlaylist) {
            AddToPlaylistView(viewModel: viewModel, playlistId: item.id, isPresented: $showAddToPlaylist)
        }
        .onAppear {
            viewModel.loadPlaylists()
        }
    }

    func itemTypeLabel(_ type: NPOItem.ItemType) -> String {
        switch type {
        case .interview: return "Interview"
        case .music: return "Music"
        case .news: return "News"
        case .report: return "Report"
        case .segment: return "Segment"
        case .topic: return "Topic"
        }
    }

    func itemTypeIcon(_ type: NPOItem.ItemType) -> String {
        switch type {
        case .interview: return "microphone.fill"
        case .music: return "music.note"
        case .news: return "newspaper.fill"
        case .report: return "doc.fill"
        case .segment: return "bookmark.fill"
        case .topic: return "tag.fill"
        }
    }
}

// Helper view for wrapping items in a grid
struct Wrap<Content: View, Item: Identifiable>: View {
    let items: [Item]
    let id: KeyPath<Item, Item.ID>
    let content: (Item) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            var currentRow: [Item] = []
            var rows: [[Item]] = []

            for item in items {
                currentRow.append(item)
                if currentRow.count >= 2 {
                    rows.append(currentRow)
                    currentRow = []
                }
            }
            if !currentRow.isEmpty {
                rows.append(currentRow)
            }

            ForEach(rows, id: \.hashValue) { row in
                HStack(spacing: 8) {
                    ForEach(row) { item in
                        content(item)
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        NPOItemDetailView(
            item: NPOItem(
                id: "1",
                broadcastId: "1",
                title: "Sample Interview",
                description: "A fascinating interview about technology and innovation",
                type: .interview,
                duration: 600,
                guests: ["Dr. Jane Smith", "Prof. John Doe"],
                topics: ["Technology", "Science"],
                startOffset: 0
            ),
            broadcast: NPOBroadcast(
                id: "1",
                title: "Morning Show",
                programId: "1",
                startTime: Date(),
                duration: 3600,
                description: "The best of the morning",
                image: nil
            )
        )
    }
    .preferredColorScheme(.dark)
}
