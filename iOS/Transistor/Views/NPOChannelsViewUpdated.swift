import SwiftUI

struct NPOChannelsViewV2: View {
    @StateObject private var viewModel = NPOViewModel()
    @State private var selectedChannel: NPOChannel?

    var body: some View {
        Group {
            if let selectedChannel = selectedChannel {
                NPOProgramsViewV2(channel: selectedChannel, onBack: {
                    self.selectedChannel = nil
                })
            } else {
                channelsGrid
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadChannels()
        }
    }

    var channelsGrid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Kies een zender")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(viewModel.channels) { channel in
                        Button(action: { selectedChannel = channel }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(channel.name)
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
                                        Color(hue: Double(viewModel.channels.firstIndex(where: { $0.id == channel.id }) ?? 0) / Double(viewModel.channels.count), saturation: 0.7, brightness: 0.5),
                                        Color(hue: Double(viewModel.channels.firstIndex(where: { $0.id == channel.id }) ?? 0) / Double(viewModel.channels.count), saturation: 0.7, brightness: 0.3),
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
        .navigationTitle("📻 Transistor")
        .background(Color.darkBg)
    }
}

struct NPOProgramsViewV2: View {
    let channel: NPOChannel
    let onBack: () -> Void

    @StateObject private var viewModel = NPOViewModel()
    @State private var selectedProgram: NPOProgram?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Group {
            if let selectedProgram = selectedProgram {
                NPOBroadcastsViewV2(program: selectedProgram, onBack: {
                    self.selectedProgram = nil
                })
            } else {
                programsList
            }
        }
        .onAppear {
            Task {
                await viewModel.loadPrograms(forChannel: channel.id)
            }
        }
    }

    var programsList: some View {
        List {
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .tint(.transistorGreen)
                    Text("Loading programs...")
                        .foregroundColor(.gray)
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Using Offline Data", systemImage: "exclamationmark.circle")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }

            ForEach(viewModel.programs) { program in
                NavigationLink(destination: NPOBroadcastsViewV2(program: program, onBack: {
                    self.selectedProgram = nil
                })) {
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
                            Text("Met: \(program.presenters.joined(separator: ", "))")
                                .font(.caption2)
                                .foregroundColor(.transistorGreen)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(channel.name)
        .background(Color.darkBg)
    }
}

struct NPOBroadcastsViewV2: View {
    let program: NPOProgram
    let onBack: () -> Void

    @StateObject private var viewModel = NPOViewModel()
    @State private var selectedBroadcast: NPOBroadcast?

    var body: some View {
        Group {
            if let selectedBroadcast = selectedBroadcast {
                NPOItemsViewV2(broadcast: selectedBroadcast)
            } else {
                broadcastsList
            }
        }
        .onAppear {
            Task {
                await viewModel.loadBroadcasts(forProgram: program.id)
            }
        }
    }

    var broadcastsList: some View {
        List {
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .tint(.transistorGreen)
                    Text("Loading broadcasts...")
                        .foregroundColor(.gray)
                }
            }

            ForEach(viewModel.broadcasts) { broadcast in
                NavigationLink(destination: NPOItemsViewV2(broadcast: broadcast)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(broadcast.title)
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
        .listStyle(.plain)
        .navigationTitle(program.title)
        .background(Color.darkBg)
    }
}

struct NPOItemsViewV2: View {
    let broadcast: NPOBroadcast
    @State private var items: [NPOItem] = []

    var body: some View {
        List {
            Section("Onderdelen van de uitzending") {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    NavigationLink(destination: NPOItemDetailView(item: item, broadcast: broadcast)) {
                        HStack(spacing: 12) {
                            VStack(alignment: .center, spacing: 4) {
                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.transistorGreen)
                                    .clipShape(Circle())
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)

                                HStack(spacing: 8) {
                                    Label(itemTypeLabel(item.type), systemImage: itemTypeIcon(item.type))
                                        .font(.caption)
                                        .foregroundColor(.transistorGreen)

                                    Text("\(item.duration / 60) min")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(broadcast.title)
        .background(Color.darkBg)
        .onAppear {
            items = NPODataService.shared.getItemsForBroadcast(broadcast.id)
        }
    }

    func itemTypeLabel(_ type: NPOItem.ItemType) -> String {
        switch type {
        case .interview: return "Interview"
        case .music: return "Muziek"
        case .news: return "Nieuws"
        case .report: return "Reportage"
        case .segment: return "Segment"
        case .topic: return "Thema"
        }
    }

    func itemTypeIcon(_ type: NPOItem.ItemType) -> String {
        switch type {
        case .interview: return "microphone.fill"
        case .music: return "music.note"
        case .news: return "newspaper.fill"
        case .report: return "doc.fill"
        case .segment: return "bookmark.fill"
        case .topic: return "tag.fill"
        }
    }
}

#Preview {
    NavigationView {
        NPOChannelsViewV2()
    }
    .preferredColorScheme(.dark)
}
