import SwiftUI

struct BrowseView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var selectedChannel: Channel?
    @State private var selectedShow: Show?

    var body: some View {
        NavigationView {
            Group {
                if let show = selectedShow {
                    BrowseBroadcastsView(show: show, onBack: {
                        self.selectedShow = nil
                    })
                } else if let channel = selectedChannel {
                    BrowseShowsView(channel: channel, viewModel: viewModel, onBack: {
                        self.selectedChannel = nil
                    }, onSelectShow: { show in
                        self.selectedShow = show
                    })
                } else {
                    channelsGrid
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var channelsGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Choose a channel")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                if viewModel.isLoadingChannels {
                    HStack {
                        ProgressView()
                            .tint(.transistorGreen)
                        Text("Loading channels...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }

                if let errorMessage = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Error", systemImage: "exclamationmark.circle")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(Array(viewModel.channels.enumerated()), id: \.element.id) { index, channel in
                        Button(action: { selectedChannel = channel }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(channel.currentTitle)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                Text(channel.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)

                                Spacer()
                            }
                            .frame(height: 120)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hue: Double(index) / max(Double(viewModel.channels.count), 1), saturation: 0.7, brightness: 0.5),
                                        Color(hue: Double(index) / max(Double(viewModel.channels.count), 1), saturation: 0.7, brightness: 0.3),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Transistor")
        .background(Color.darkBg)
        .onAppear {
            Task {
                await viewModel.loadChannels()
            }
        }
    }
}

// MARK: - Shows List (for a selected channel)

struct BrowseShowsView: View {
    let channel: Channel
    @ObservedObject var viewModel: ContentViewModel
    let onBack: () -> Void
    let onSelectShow: (Show) -> Void

    var body: some View {
        List {
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .tint(.transistorGreen)
                    Text("Loading shows...")
                        .foregroundColor(.gray)
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Error", systemImage: "exclamationmark.circle")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }

            ForEach(viewModel.shows) { show in
                Button(action: { onSelectShow(show) }) {
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
        .listStyle(.plain)
        .navigationTitle(channel.currentTitle)
        .background(Color.darkBg)
        .onAppear {
            Task {
                await viewModel.loadShows(forChannel: channel)
            }
        }
    }
}

// MARK: - Broadcasts List (for a selected show)

struct BrowseBroadcastsView: View {
    let show: Show
    let onBack: () -> Void

    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .tint(.transistorGreen)
                    Text("Loading broadcasts...")
                        .foregroundColor(.gray)
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Error", systemImage: "exclamationmark.circle")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }

            ForEach(viewModel.broadcasts) { broadcast in
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
        .listStyle(.plain)
        .navigationTitle(show.currentTitle)
        .background(Color.darkBg)
        .onAppear {
            Task {
                await viewModel.loadBroadcasts(forShow: show)
            }
        }
    }
}

#Preview {
    BrowseView()
        .preferredColorScheme(.dark)
}
