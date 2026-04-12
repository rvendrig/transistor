import SwiftUI

struct AddToPlaylistView: View {
    let viewModel: ContentViewModel
    let playlistId: String?
    @Binding var isPresented: Bool

    @State private var showCreatePlaylist = false
    @State private var itemTitle = "Item"
    @State private var itemType: PlaylistItemType = .broadcast
    @State private var showId: String?
    @State private var selectedPlaylistId: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationView {
            List {
                if let successMessage = successMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Success", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(successMessage)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
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

                Section("Selecteer Afspeellijst") {
                    if viewModel.playlists.isEmpty {
                        VStack(alignment: .center, spacing: 8) {
                            Text("Geen afspeellijsten beschikbaar")
                                .foregroundColor(.gray)
                            Text("Maak een nieuwe afspeellijst aan")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    } else {
                        ForEach(viewModel.playlists) { playlist in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(playlist.name)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("\(playlist.itemCount) items")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                if selectedPlaylistId == playlist.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.transistorGreen)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPlaylistId = (selectedPlaylistId == playlist.id) ? nil : playlist.id
                            }
                        }
                    }
                }

                Section {
                    Button(action: { showCreatePlaylist = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.transistorGreen)
                            Text("Nieuwe Afspeellijst")
                                .foregroundColor(.transistorGreen)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Voeg Toe aan Afspeellijst")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.darkBg)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleren") {
                        isPresented = false
                    }
                    .foregroundColor(.transistorGreen)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if let selectedId = selectedPlaylistId {
                        Button(action: {
                            viewModel.addToPlaylist(
                                playlistId: selectedId,
                                itemId: playlistId ?? UUID().uuidString,
                                type: itemType,
                                showId: showId
                            )
                            successMessage = "Added to '\(viewModel.playlists.first(where: { $0.id == selectedId })?.name ?? "playlist")'"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                isPresented = false
                            }
                        }) {
                            Text("Voeg Toe")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.transistorGreen)
                    } else {
                        Text("Voeg Toe")
                            .fontWeight(.bold)
                            .foregroundColor(.transistorGreen)
                            .opacity(0.5)
                    }
                }
            }
            .sheet(isPresented: $showCreatePlaylist) {
                CreatePlaylistView(viewModel: viewModel, isPresented: $showCreatePlaylist)
                    .onDisappear {
                        if let lastPlaylist = viewModel.playlists.last {
                            selectedPlaylistId = lastPlaylist.id
                        }
                    }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    @State var isPresented = true
    let viewModel = ContentViewModel()
    return AddToPlaylistView(viewModel: viewModel, playlistId: "test-id", isPresented: $isPresented)
}
