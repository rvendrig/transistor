import SwiftUI

struct ListeningLogView: View {
    @StateObject var viewModel: ContentViewModel
    @State private var selectedCategory: ContentCategory? = nil
    @State private var sortBy: SortOption = .recent
    @State private var selectedSession: ListeningSession? = nil
    @State private var showingDetails = false

    enum SortOption: String, CaseIterable {
        case recent = "Recent"
        case longest = "Longest"
        case mostMarked = "Most Marked"
        case byTopic = "By Topic"
    }

    var filteredAndSortedSessions: [ListeningSession] {
        var sessions = selectedCategory.map { viewModel.getListeningHistoryByCategory($0) } ?? viewModel.listeningHistory

        switch sortBy {
        case .recent:
            sessions.sort { $0.startTime > $1.startTime }
        case .longest:
            sessions.sort { $0.duration > $1.duration }
        case .mostMarked:
            sessions.sort { $0.markerCount > $1.markerCount }
        case .byTopic:
            sessions.sort { ($0.topics.first ?? "") < ($1.topics.first ?? "") }
        }

        return sessions
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Text("Filter:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        filterButton(title: "All", category: nil)
                        ForEach(ContentCategory.allCases, id: \.self) { category in
                            filterButton(title: category.displayName, category: category)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))

                // Sort Bar
                HStack {
                    Text("Sort by:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Sort", selection: $sortBy) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .font(.caption)

                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))

                // List
                if filteredAndSortedSessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.xmark")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No listening history")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Your listening sessions will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    List {
                        ForEach(filteredAndSortedSessions) { session in
                            NavigationLink(destination: ListeningSessionDetailView(session: session, viewModel: viewModel)) {
                                ListeningLogItem(session: session)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Listening History")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadListeningHistory()
            }
        }
    }

    private func filterButton(title: String, category: ContentCategory?) -> some View {
        Button(action: { selectedCategory = category }) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
                .foregroundColor(selectedCategory == category ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct ListeningLogItem: View {
    let session: ListeningSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.headline)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(session.source)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("·")
                            .foregroundColor(.secondary)

                        Text(session.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if session.isFavorited {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(session.percentage) / 100)
                }
                .cornerRadius(2)
            }
            .frame(height: 4)

            // Topics, guests, artists
            tagsView()
        }
        .padding(.vertical, 8)
    }

    private func tagsView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if !session.topics.isEmpty {
                tagRow(title: "Topics", items: session.topics, color: .blue)
            }

            if !session.guests.isEmpty {
                tagRow(title: "Guests", items: session.guests, color: .green)
            }

            if !session.artists.isEmpty {
                tagRow(title: "Artists", items: session.artists, color: .orange)
            }
        }
    }

    private func tagRow(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(items.prefix(3), id: \.self) { item in
                        Text(item)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(color.opacity(0.2))
                            .foregroundColor(color)
                            .cornerRadius(4)
                    }

                    if items.count > 3 {
                        Text("+\(items.count - 3)")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .foregroundColor(.secondary)
                            .cornerRadius(4)
                    }
                }
            }
        }
    }
}

struct ListeningSessionDetailView: View {
    let session: ListeningSession
    @ObservedObject var viewModel: ContentViewModel
    @State private var notes = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(session.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        Button(action: {}) {
                            Image(systemName: session.isFavorited ? "heart.fill" : "heart")
                                .foregroundColor(session.isFavorited ? .red : .gray)
                        }
                    }

                    Text(session.source)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Listened \(session.timeAgo)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("·")
                            .foregroundColor(.secondary)

                        Text(formatDuration(session.progress) + " / " + formatDuration(session.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

                // Progress
                VStack(spacing: 8) {
                    HStack {
                        Text("Listening Progress")
                            .font(.headline)
                        Spacer()
                        Text("\(session.percentage)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(.systemGray5))

                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * CGFloat(session.percentage) / 100)
                        }
                        .cornerRadius(4)
                    }
                    .frame(height: 8)
                }
                .padding()

                // Categories
                if !session.categories.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Categories")
                            .font(.headline)

                        HStack(spacing: 8) {
                            ForEach(session.categories, id: \.self) { category in
                                Text(category.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding()
                }

                // Topics
                if !session.topics.isEmpty {
                    metadataSection(title: "Topics", items: session.topics, color: .blue)
                }

                // Guests
                if !session.guests.isEmpty {
                    metadataSection(title: "Guests", items: session.guests, color: .green)
                }

                // Artists
                if !session.artists.isEmpty {
                    metadataSection(title: "Artists", items: session.artists, color: .orange)
                }

                // Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)

                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onAppear {
                            notes = session.notes ?? ""
                        }

                    Button(action: {
                        viewModel.addNoteToListeningSession(session.id, note: notes)
                    }) {
                        Text("Save Notes")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()

                // Markers
                if session.markerCount > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Markers")
                                .font(.headline)
                            Spacer()
                            Text("\(session.markerCount)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                        }
                    }
                    .padding()
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metadataSection(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.2))
                        .foregroundColor(color)
                        .cornerRadius(4)
                }
            }
        }
        .padding()
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

#Preview {
    ListeningLogView(viewModel: ContentViewModel())
}
