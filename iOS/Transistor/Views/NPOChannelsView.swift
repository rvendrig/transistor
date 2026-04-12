import SwiftUI

struct NPOChannelsView: View {
    @State private var channels: [NPOChannel] = []
    @State private var selectedChannel: NPOChannel?

    var body: some View {
        Group {
            if let selectedChannel = selectedChannel {
                NPOProgramsView(channel: selectedChannel)
            } else {
                channelsGrid
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            channels = NPODataService.shared.getAllChannels()
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
                    ForEach(channels) { channel in
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
                                        Color(hue: Double(channels.firstIndex(where: { $0.id == channel.id }) ?? 0) / Double(channels.count), saturation: 0.7, brightness: 0.5),
                                        Color(hue: Double(channels.firstIndex(where: { $0.id == channel.id }) ?? 0) / Double(channels.count), saturation: 0.7, brightness: 0.3),
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

struct NPOProgramsView: View {
    let channel: NPOChannel
    @State private var programs: [NPOProgram] = []
    @State private var selectedProgram: NPOProgram?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Group {
            if let selectedProgram = selectedProgram {
                NPOBroadcastsView(program: selectedProgram)
            } else {
                programsList
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            programs = NPODataService.shared.getProgramsForChannel(channel.id)
        }
    }

    var programsList: some View {
        List {
            ForEach(programs) { program in
                NavigationLink(destination: NPOBroadcastsView(program: program)) {
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

struct NPOBroadcastsView: View {
    let program: NPOProgram
    @State private var broadcasts: [NPOBroadcast] = []
    @State private var selectedBroadcast: NPOBroadcast?

    var body: some View {
        Group {
            if let selectedBroadcast = selectedBroadcast {
                NPOItemsView(broadcast: selectedBroadcast)
            } else {
                broadcastsList
            }
        }
        .onAppear {
            broadcasts = NPODataService.shared.getBroadcastsForProgram(program.id)
        }
    }

    var broadcastsList: some View {
        List {
            ForEach(broadcasts) { broadcast in
                NavigationLink(destination: NPOItemsView(broadcast: broadcast)) {
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

struct NPOItemsView: View {
    let broadcast: NPOBroadcast
    @State private var items: [NPOItem] = []
    @State private var selectedItem: NPOItem?

    var body: some View {
        Group {
            if let selectedItem = selectedItem {
                NPOItemDetailView(item: selectedItem, broadcast: broadcast)
            } else {
                itemsList
            }
        }
        .onAppear {
            items = NPODataService.shared.getItemsForBroadcast(broadcast.id)
        }
    }

    var itemsList: some View {
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

struct NPOItemDetailView: View {
    let item: NPOItem
    let broadcast: NPOBroadcast

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: itemTypeIcon())
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(itemTypeColor())
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(itemTypeLabel())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.transistorGreen)

                            Text("In: \(broadcast.title)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }

                    Text(item.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.cardBg)
                .cornerRadius(12)

                // Description
                if let description = item.description {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OMSCHRIJVING")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.transistorGreen)

                        Text(description)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.cardBg)
                    .cornerRadius(12)
                }

                // Teaser
                if let teaserText = item.teaserText {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\"\(teaserText)\"")
                            .font(.body)
                            .italic()
                            .foregroundColor(.transistorGreen)
                    }
                    .padding()
                    .background(Color.cardBg)
                    .cornerRadius(12)
                }

                // Guests
                if let guests = item.guests, !guests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SPREKERS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.transistorGreen)

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(guests, id: \.self) { guest in
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.transistorGreen)
                                    Text(guest)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.cardBg)
                    .cornerRadius(12)
                }

                // Topics
                if let topics = item.topics, !topics.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ONDERWERPEN")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.transistorGreen)

                        HStack(spacing: 8) {
                            ForEach(topics, id: \.self) { topic in
                                Text(topic)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.transistorGreen.opacity(0.2))
                                    .foregroundColor(.transistorGreen)
                                    .cornerRadius(4)
                            }
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.cardBg)
                    .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Onderdeel")
        .background(Color.darkBg)
    }

    func itemTypeLabel() -> String {
        switch item.type {
        case .interview: return "Interview"
        case .music: return "Muziek"
        case .news: return "Nieuws"
        case .report: return "Reportage"
        case .segment: return "Segment"
        case .topic: return "Thema"
        }
    }

    func itemTypeIcon() -> String {
        switch item.type {
        case .interview: return "microphone.fill"
        case .music: return "music.note"
        case .news: return "newspaper.fill"
        case .report: return "doc.fill"
        case .segment: return "bookmark.fill"
        case .topic: return "tag.fill"
        }
    }

    func itemTypeColor() -> Color {
        switch item.type {
        case .interview: return .transistorGreen
        case .music: return Color(red: 1, green: 0.427, blue: 0.616)
        case .news: return Color(red: 0.255, green: 0.412, blue: 0.882)
        case .report: return Color(red: 1, green: 0.549, blue: 0)
        case .segment: return Color(red: 0.576, green: 0.439, blue: 0.859)
        case .topic: return Color(red: 0.129, green: 0.698, blue: 0.667)
        }
    }
}

#Preview {
    NavigationView {
        NPOChannelsView()
    }
    .preferredColorScheme(.dark)
}
