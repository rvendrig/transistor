import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search shows, broadcasts...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: searchText) {
                                searchTask?.cancel()
                                searchTask = Task {
                                    try? await Task.sleep(nanoseconds: 300_000_000)
                                    guard !Task.isCancelled else { return }
                                    await viewModel.search(searchText)
                                }
                            }
                    }
                }

                if viewModel.isSearching {
                    HStack {
                        ProgressView()
                            .tint(.transistorGreen)
                        Text("Searching...")
                            .foregroundColor(.gray)
                    }
                }

                let results = viewModel.searchResults

                if !results.shows.isEmpty {
                    Section("Shows (\(results.shows.count))") {
                        ForEach(results.shows) { show in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(show.currentTitle)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                Text(show.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)

                                if !show.presenters.isEmpty {
                                    Text("With: \(show.presenters.joined(separator: ", "))")
                                        .font(.caption2)
                                        .foregroundColor(.transistorGreen)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }

                if !results.broadcasts.isEmpty {
                    Section("Broadcasts (\(results.broadcasts.count))") {
                        ForEach(results.broadcasts) { broadcast in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(broadcast.displayTitle)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                HStack(spacing: 12) {
                                    Label(
                                        broadcast.startTime.formatted(date: .abbreviated, time: .shortened),
                                        systemImage: "calendar"
                                    )
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                    Label(
                                        "\(broadcast.duration / 60) min",
                                        systemImage: "clock"
                                    )
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }

                if !results.episodes.isEmpty {
                    Section("Episodes (\(results.episodes.count))") {
                        ForEach(results.episodes) { episode in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(episode.displayTitle)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                HStack(spacing: 12) {
                                    Label(
                                        episode.publishDate.formatted(date: .abbreviated, time: .shortened),
                                        systemImage: "calendar"
                                    )
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                    Label(
                                        "\(episode.duration / 60) min",
                                        systemImage: "clock"
                                    )
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }

                if !searchText.isEmpty && results.totalResults == 0 && !viewModel.isSearching {
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No results found")
                            .foregroundColor(.gray)
                        Text("Try searching for another show, broadcast, or topic")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                }
            }
            .listStyle(.plain)
            .navigationTitle("Search")
            .background(Color.darkBg)
        }
    }
}

#Preview {
    NavigationView {
        SearchView()
    }
    .preferredColorScheme(.dark)
}
