import SwiftUI

struct MarkerCreationSheet: View {
    @ObservedObject var viewModel: NPOViewModel
    let broadcastId: String
    let currentTimestamp: Int // in seconds
    @Binding var isPresented: Bool

    @State private var tagInput = ""
    @State private var tags: [String] = []

    var formattedTime: String {
        let minutes = currentTimestamp / 60
        let seconds = currentTimestamp % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var isValid: Bool {
        !tags.isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Marker Details") {
                    HStack {
                        Text("Time")
                        Spacer()
                        Text(formattedTime)
                            .foregroundColor(.gray)
                    }
                }

                Section("Tags") {
                    HStack {
                        TextField("Add a tag (e.g., 'Important', 'Follow up')", text: $tagInput)
                            .foregroundColor(.white)

                        Button(action: {
                            if !tagInput.trimmingCharacters(in: .whitespaces).isEmpty {
                                let newTag = tagInput.trimmingCharacters(in: .whitespaces)
                                if !tags.contains(newTag) {
                                    tags.append(newTag)
                                    tagInput = ""
                                }
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.transistorGreen)
                        }
                    }

                    if tags.isEmpty {
                        Text("Add at least one tag to create a marker")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack {
                                    Text(tag)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.transistorGreen)
                                        .cornerRadius(16)

                                    Spacer()

                                    Button(action: {
                                        tags.removeAll { $0 == tag }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                }

                if let error = viewModel.markerError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .background(Color.darkBg)
            .navigationTitle("Create Marker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.transistorGreen)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.createMarker(broadcastId: broadcastId, timestamp: currentTimestamp, tags: tags)
                        isPresented = false
                    }) {
                        Text("Create")
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
    return MarkerCreationSheet(
        viewModel: viewModel,
        broadcastId: "test-id",
        currentTimestamp: 120,
        isPresented: $isPresented
    )
}
