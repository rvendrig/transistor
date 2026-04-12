import SwiftUI

struct EditPlaylistView: View {
    let viewModel: NPOViewModel
    let playlist: Playlist
    @Binding var isPresented: Bool

    @State private var name: String = ""
    @State private var description: String = ""

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Afspeellijst Details") {
                    TextField("Naam", text: $name)
                        .foregroundColor(.white)

                    TextField("Beschrijving (optioneel)", text: $description)
                        .foregroundColor(.white)
                }

                if let error = viewModel.playlistError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .background(Color.darkBg)
            .navigationTitle("Bewerk Afspeellijst")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleren") {
                        isPresented = false
                    }
                    .foregroundColor(.transistorGreen)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.renamePlaylist(playlist.id, newName: name)
                        isPresented = false
                    }) {
                        Text("Opslaan")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.transistorGreen)
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.5)
                }
            }
            .onAppear {
                name = playlist.name
                description = playlist.description ?? ""
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    @State var isPresented = true
    let viewModel = NPOViewModel()
    let playlist = Playlist(
        id: "1",
        name: "My Playlist",
        description: "A test playlist",
        createdAt: Date(),
        itemCount: 5
    )
    return EditPlaylistView(viewModel: viewModel, playlist: playlist, isPresented: $isPresented)
}
