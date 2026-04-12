import SwiftUI

struct NPOItemDetailView: View {
    let item: NPOItem
    let broadcast: NPOBroadcast
    @StateObject private var contentViewModel = ContentViewModel()
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

                        FlowLayout(spacing: 8) {
                            ForEach(item.topics, id: \.self) { topic in
                                Text(topic)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.transistorGreen.opacity(0.3))
                                    .cornerRadius(16)
                            }
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
            AddToPlaylistView(viewModel: contentViewModel, playlistId: item.id, isPresented: $showAddToPlaylist)
        }
        .onAppear {
            contentViewModel.loadPlaylists()
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

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
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
                image: nil,
                audioUrl: nil
            )
        )
    }
    .preferredColorScheme(.dark)
}
