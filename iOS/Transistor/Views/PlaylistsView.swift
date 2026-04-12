import SwiftUI

struct PlaylistsView: View {
    @StateObject private var viewModel = NPOViewModel()
    @State private var showCreatePlaylist = false
    @State private var editingPlaylist: Playlist?
    @State private var showEditPlaylist = false

    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoadingPlaylists {
                    HStack {
                        ProgressView()
                            .tint(.transistorGreen)
                        Text("Loading playlists...")
                            .foregroundColor(.gray)
                    }
                } else if viewModel.playlists.isEmpty {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Geen afspeellijsten")
                            .foregroundColor(.white)
                            .font(.headline)
                        Text("Maak je eerste afspeellijst aan om je favoriete uitzendingen te organiseren")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else {
                    Section("Mijn Afspeellijsten") {
                        ForEach(viewModel.playlists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist, viewModel: viewModel)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(playlist.name)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)

                                    HStack(spacing: 12) {
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

                                    if let description = playlist.description, !description.isEmpty {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            .contextMenu {
                                Button(action: {
                                    editingPlaylist = playlist
                                    showEditPlaylist = true
                                }) {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button(role: .destructive, action: {
                                    viewModel.deletePlaylist(playlist.id)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                if let errorMessage = viewModel.playlistError {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Error", systemImage: "exclamationmark.circle")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.plain)
            .navigationTitle("📋 Playlists")
            .background(Color.darkBg)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreatePlaylist = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.transistorGreen)
                    }
                }
            }
            .sheet(isPresented: $showCreatePlaylist) {
                CreatePlaylistView(viewModel: viewModel, isPresented: $showCreatePlaylist)
            }
            .sheet(isPresented: $showEditPlaylist) {
                if let playlist = editingPlaylist {
                    EditPlaylistView(viewModel: viewModel, playlist: playlist, isPresented: $showEditPlaylist)
                }
            }
            .onAppear {
                viewModel.loadPlaylists()
            }
        }
    }
}

#Preview {
    NavigationView {
        PlaylistsView()
    }
    .preferredColorScheme(.dark)
}
