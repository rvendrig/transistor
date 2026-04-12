import SwiftUI

// MARK: - Wizard Action Types
enum WizardAction: String, CaseIterable {
    case relatedContent = "Find Similar"
    case seeGuests = "View Guests"
    case readTranscript = "Read Transcript"
    case shareHighlight = "Share"
    case createPlaylist = "Add to Playlist"
    case findSimilar = "Discover Similar"
    case learnMore = "Learn More"
    case downloadEpisode = "Download"
    case followArtist = "Follow"
    case followPodcast = "Subscribe"

    var icon: String {
        switch self {
        case .relatedContent: return "sparkles"
        case .seeGuests: return "person.2"
        case .readTranscript: return "doc.text"
        case .shareHighlight: return "square.and.arrow.up"
        case .createPlaylist: return "plus.circle"
        case .findSimilar: return "magnifyingglass"
        case .learnMore: return "info.circle"
        case .downloadEpisode: return "arrow.down.circle"
        case .followArtist: return "heart"
        case .followPodcast: return "bell"
        }
    }
}

struct NewsWizard: View {
    let session: ListeningSession
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.title)
                        .font(.headline)

                    Text("News Segment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)

                // Topics
                if !session.topics.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Topics Covered", systemImage: "tag.fill")
                            .font(.headline)
                            .foregroundColor(.red)

                        VStack(spacing: 8) {
                            ForEach(session.topics, id: \.self) { topic in
                                HStack {
                                    Text(topic)
                                        .font(.body)

                                    Spacer()

                                    Button(action: {}) {
                                        Image(systemName: "arrow.up.right.circle")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }

                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)

                    VStack(spacing: 8) {
                        wizardActionButton(action: .readTranscript, icon: "doc.text", color: .blue)
                        wizardActionButton(action: .createPlaylist, icon: "plus.circle", color: .green)
                        wizardActionButton(action: .shareHighlight, icon: "square.and.arrow.up", color: .orange)
                        wizardActionButton(action: .findSimilar, icon: "sparkles", color: .purple)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("News Wizard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func wizardActionButton(action: WizardAction, icon: String, color: Color) -> some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)

                Text(action.rawValue)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct MusicWizard: View {
    let session: ListeningSession
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.title)
                        .font(.headline)

                    Text("Music Program")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)

                // Artists
                if !session.artists.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Artists Featured", systemImage: "music.note.fill")
                            .font(.headline)
                            .foregroundColor(.orange)

                        VStack(spacing: 8) {
                            ForEach(session.artists, id: \.self) { artist in
                                HStack {
                                    Image(systemName: "music.note")
                                        .foregroundColor(.orange)

                                    Text(artist)
                                        .font(.body)

                                    Spacer()

                                    Button(action: {}) {
                                        Image(systemName: "heart")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }

                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)

                    VStack(spacing: 8) {
                        wizardActionButton(action: .createPlaylist, icon: "plus.circle", color: .blue)
                        wizardActionButton(action: .downloadEpisode, icon: "arrow.down.circle", color: .green)
                        wizardActionButton(action: .shareHighlight, icon: "square.and.arrow.up", color: .orange)
                        wizardActionButton(action: .followArtist, icon: "heart.fill", color: .red)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Music Wizard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func wizardActionButton(action: WizardAction, icon: String, color: Color) -> some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)

                Text(action.rawValue)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct PodcastWizard: View {
    let session: ListeningSession
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.title)
                        .font(.headline)

                    Text("Podcast Episode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)

                // Guests
                if !session.guests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Guests", systemImage: "person.2.fill")
                            .font(.headline)
                            .foregroundColor(.purple)

                        VStack(spacing: 8) {
                            ForEach(session.guests, id: \.self) { guest in
                                HStack {
                                    Image(systemName: "person.crop.circle.fill")
                                        .foregroundColor(.purple)

                                    Text(guest)
                                        .font(.body)

                                    Spacer()

                                    Button(action: {}) {
                                        Image(systemName: "arrow.up.right.circle")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }

                // Topics
                if !session.topics.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Topics Discussed", systemImage: "tag.fill")
                            .font(.headline)
                            .foregroundColor(.blue)

                        HStack(spacing: 8) {
                            ForEach(session.topics.prefix(3), id: \.self) { topic in
                                Text(topic)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }

                            if session.topics.count > 3 {
                                Text("+\(session.topics.count - 3)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.secondary)
                                    .cornerRadius(4)
                            }
                        }
                    }
                }

                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)

                    VStack(spacing: 8) {
                        wizardActionButton(action: .readTranscript, icon: "doc.text", color: .blue)
                        wizardActionButton(action: .followPodcast, icon: "bell.fill", color: .purple)
                        wizardActionButton(action: .createPlaylist, icon: "plus.circle", color: .green)
                        wizardActionButton(action: .shareHighlight, icon: "square.and.arrow.up", color: .orange)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Podcast Wizard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func wizardActionButton(action: WizardAction, icon: String, color: Color) -> some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)

                Text(action.rawValue)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

#Preview {
    NewsWizard(session: ListeningSession(
        id: "1",
        contentId: "1",
        contentType: .broadcast,
        providerId: "npo",
        title: "Sample News",
        source: "NPO Radio 1",
        startTime: Date(),
        duration: 1800,
        progress: 900,
        categories: [.news],
        topics: ["Politics", "Climate"],
        guests: [],
        artists: [],
        isFavorited: false,
        markerCount: 0
    ))
}
