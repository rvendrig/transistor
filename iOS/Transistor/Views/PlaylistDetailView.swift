import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist
    let viewModel: ContentViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var showAddToPlaylist = false

    var body: some View {
        List {
            Section("Info") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(playlist.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    if let description = playlist.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.gray)
                    }

                    HStack(spacing: 16) {
                        Label(
                            "\(playlist.itemCount) items",
                            systemImage: "music.note"
                        )
                        .font(.caption)
                        .foregroundColor(.gray)

                        Label(
                            playlist.createdAt.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }

            if viewModel.playlistItems.isEmpty {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Geen items")
                        .foregroundColor(.white)
                        .font(.headline)
                    Text("Voeg items toe vanuit de NPO, Discover, of Zoeken tabbladen")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            } else {
                Section("Items") {
                    ForEach(viewModel.playlistItems) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.itemId)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                Text(item.itemType.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.transistorGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.cardBg)
                                    .cornerRadius(4)

                                Spacer()

                                Text("#\(item.position)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            if let showId = item.showId {
                                Text("Show: \(showId)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 8)
                        .contextMenu {
                            Button(role: .destructive, action: {
                                viewModel.removeFromPlaylist(playlist.id, item.itemId)
                            }) {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            if let error = viewModel.playlistError {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Error", systemImage: "exclamationmark.circle")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.plain)
        .navigationTitle(playlist.name)
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
            AddToPlaylistView(viewModel: viewModel, playlistId: playlist.id, isPresented: $showAddToPlaylist)
        }
        .onAppear {
            viewModel.loadPlaylistItems(playlist.id)
        }
    }
}

#Preview {
    let viewModel = ContentViewModel()
    let playlist = Playlist(
        id: "1",
        name: "My Playlist",
        description: "A test playlist",
        createdAt: Date(),
        itemCount: 0
    )
    NavigationView {
        PlaylistDetailView(playlist: playlist, viewModel: viewModel)
    }
    .preferredColorScheme(.dark)
}
