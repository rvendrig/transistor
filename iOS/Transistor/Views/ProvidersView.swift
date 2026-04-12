import SwiftUI

struct ProvidersView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var showAddCustomFeed = false
    @State private var customFeedURL = ""

    var body: some View {
        NavigationView {
            List {
                Section("Active Providers") {
                    ForEach(viewModel.providerStore.allActiveProviders(), id: \.id) { provider in
                        ProviderRow(
                            provider: provider,
                            isActive: viewModel.isProviderActive(provider.id),
                            onToggle: { viewModel.setProviderActive(provider.id, !viewModel.isProviderActive(provider.id)) }
                        )
                    }
                }

                Section("Available Providers") {
                    Button(action: { showAddCustomFeed = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.transistorGreen)
                            Text("Add Podcast Feed")
                                .foregroundColor(.transistorGreen)
                        }
                    }

                    NavigationLink(destination: ProviderDiscoveryView()) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.transistorGreen)
                            Text("Discover Networks")
                                .foregroundColor(.transistorGreen)
                        }
                    }
                }

                Section("Provider Information") {
                    Text("You can add multiple providers and browse content from all of them together. Create playlists mixing content from different sources.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .listStyle(.plain)
            .navigationTitle("📡 Providers")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.darkBg)
            .sheet(isPresented: $showAddCustomFeed) {
                AddPodcastFeedSheet(isPresented: $showAddCustomFeed, feedURL: $customFeedURL)
            }
        }
    }
}

// MARK: - Provider Row
struct ProviderRow: View {
    let provider: ContentProvider
    let isActive: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(provider.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .textCase(.capitalized)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { isActive },
                    set: { _ in onToggle() }
                ))
                .tint(.transistorGreen)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Provider Discovery View
struct ProviderDiscoveryView: View {
    let availableProviders = [
        ("bbc", "BBC Sounds", ProviderType.radioNetwork),
        ("spotify", "Spotify", ProviderType.podcastPlatform),
        ("apple_podcasts", "Apple Podcasts", ProviderType.podcastPlatform),
        ("dw", "Deutsche Welle", ProviderType.radioNetwork),
        ("rfi", "RFI Français", ProviderType.radioNetwork),
        ("custom", "Custom RSS Feed", ProviderType.custom),
    ]

    var body: some View {
        List {
            Section("Available Networks") {
                ForEach(availableProviders, id: \.0) { id, name, type in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text(type.rawValue.replacingOccurrences(of: "_", with: " "))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.capitalized)
                        }

                        Spacer()

                        Button(action: {}) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.transistorGreen)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Section("Coming Soon") {
                Text("More providers will be added soon. You can also add any podcast via RSS feed.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Discover Networks")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.darkBg)
    }
}

// MARK: - Add Podcast Feed Sheet
struct AddPodcastFeedSheet: View {
    @Binding var isPresented: Bool
    @Binding var feedURL: String
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Podcast Feed URL") {
                    TextField("https://example.com/feed.xml", text: $feedURL)
                        .foregroundColor(.white)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                }

                Section("About") {
                    Text("Paste the RSS feed URL of any podcast or broadcaster. Common formats like Podcast RSS feeds are supported.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .background(Color.darkBg)
            .navigationTitle("Add Podcast Feed")
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
                        Task {
                            isLoading = true
                            // In a real implementation, this would parse and add the feed
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            isLoading = false
                            isPresented = false
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .tint(.transistorGreen)
                        } else {
                            Text("Add")
                                .fontWeight(.bold)
                                .foregroundColor(.transistorGreen)
                        }
                    }
                    .disabled(feedURL.isEmpty || isLoading)
                    .opacity((feedURL.isEmpty || isLoading) ? 0.5 : 1)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ProvidersView()
}
