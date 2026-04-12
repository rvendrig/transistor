import SwiftUI

struct CreatePlaylistView: View {
    let viewModel: NPOViewModel
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var description = ""

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
            .navigationTitle("Nieuwe Afspeellijst")
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
                        viewModel.createPlaylist(
                            name: name,
                            description: description.isEmpty ? nil : description
                        )
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
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    @State var isPresented = true
    let viewModel = NPOViewModel()
    return CreatePlaylistView(viewModel: viewModel, isPresented: $isPresented)
}
