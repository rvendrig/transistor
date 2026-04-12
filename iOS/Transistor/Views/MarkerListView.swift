import SwiftUI

struct MarkerListView: View {
    @ObservedObject var viewModel: NPOViewModel
    let broadcastId: String

    var body: some View {
        if viewModel.markers.isEmpty {
            VStack(alignment: .center, spacing: 12) {
                Image(systemName: "bookmark")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("No markers yet")
                    .foregroundColor(.white)
                    .font(.headline)
                Text("Create markers to save important moments during playback")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
        } else {
            List {
                Section("Markers") {
                    ForEach(viewModel.markers.sorted(by: { $0.timestamp < $1.timestamp })) { marker in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(formatTimestamp(marker.timestamp))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.transistorGreen)

                                Spacer()

                                Text(marker.createdAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            if !marker.tags.isEmpty {
                                Wrap(items: marker.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.transistorGreen.opacity(0.3))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .contextMenu {
                            Button(role: .destructive, action: {
                                viewModel.deleteMarker(marker.id)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(Color.darkBg)
        }
    }

    private func formatTimestamp(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
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
    let viewModel = NPOViewModel()
    MarkerListView(viewModel: viewModel, broadcastId: "test-id")
}
