import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = NPOViewModel()
    @State private var searchText = ""

    var filteredPrograms: [NPOProgram] {
        if searchText.isEmpty {
            return viewModel.programs
        } else {
            return viewModel.programs.filter { program in
                program.title.lowercased().contains(searchText.lowercased()) ||
                    program.description.lowercased().contains(searchText.lowercased()) ||
                    program.presenters.contains { presenter in
                        presenter.lowercased().contains(searchText.lowercased())
                    }
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search programs...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                            .tint(.transistorGreen)
                        Text("Searching...")
                            .foregroundColor(.gray)
                    }
                }

                if !filteredPrograms.isEmpty {
                    Section("Results (\(filteredPrograms.count))") {
                        ForEach(filteredPrograms) { program in
                            NavigationLink(destination: NPOProgramsViewV2(channel: NPOChannel(id: program.channelId ?? "", name: "", description: "", logoURL: nil), onBack: {})) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(program.title)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)

                                    Text(program.description)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)

                                    if !program.presenters.isEmpty {
                                        Text("With: \(program.presenters.joined(separator: ", "))")
                                            .font(.caption2)
                                            .foregroundColor(.transistorGreen)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                } else if !searchText.isEmpty {
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No results found")
                            .foregroundColor(.gray)
                        Text("Try searching for another program, presenter, or topic")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                }
            }
            .listStyle(.plain)
            .navigationTitle("🔍 Search")
            .background(Color.darkBg)
            .onAppear {
                Task {
                    await viewModel.loadAllPrograms()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SearchView()
    }
    .preferredColorScheme(.dark)
}
