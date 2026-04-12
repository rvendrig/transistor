import SwiftUI

struct LivePlaybackDisplay: View {
    let session: ListeningSession
    @State private var showingTranscript = false

    var body: some View {
        VStack(spacing: 20) {
            // Circular Progress
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: CGFloat(session.percentage) / 100)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 8) {
                    Text("\(session.percentage)%")
                        .font(.system(size: 32, weight: .bold))

                    Text("Played")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Current Title
            VStack(spacing: 8) {
                Text(session.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.caption)

                    Text(session.source)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Current Topic Display
            if !session.topics.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Current Topic", systemImage: "tag.fill")
                        .font(.headline)
                        .foregroundColor(.blue)

                    Text(session.topics.first ?? "")
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            // Guests Display
            if !session.guests.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Guests", systemImage: "person.2.fill")
                        .font(.headline)
                        .foregroundColor(.green)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(session.guests.prefix(4), id: \.self) { guest in
                                guestBadge(guest)
                            }
                        }
                    }
                }
            }

            // Artists Display
            if !session.artists.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Artists", systemImage: "music.note")
                        .font(.headline)
                        .foregroundColor(.orange)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(session.artists.prefix(4), id: \.self) { artist in
                                artistBadge(artist)
                            }
                        }
                    }
                }
            }

            // Transcript / Details Button
            Button(action: { showingTranscript = true }) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("View Transcript & Topics")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            .sheet(isPresented: $showingTranscript) {
                TranscriptView(session: session)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private func guestBadge(_ guest: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)

            Text(guest)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 60)
        .padding(8)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }

    private func artistBadge(_ artist: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)

            Text(artist)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 60)
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TranscriptView: View {
    let session: ListeningSession
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.title)
                            .font(.headline)

                        Text(session.source)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Topics Section
                    if !session.topics.isEmpty {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(session.topics, id: \.self) { topic in
                                    HStack(spacing: 8) {
                                        Image(systemName: "tag.fill")
                                            .font(.caption)
                                            .foregroundColor(.blue)

                                        Text(topic)
                                            .font(.body)

                                        Spacer()

                                        Button(action: {}) {
                                            Image(systemName: "arrow.up.right")
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        } header: {
                            Text("Topics Covered")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }

                    // Guests Section
                    if !session.guests.isEmpty {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(session.guests, id: \.self) { guest in
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.fill")
                                            .font(.caption)
                                            .foregroundColor(.green)

                                        Text(guest)
                                            .font(.body)

                                        Spacer()

                                        Button(action: {}) {
                                            Image(systemName: "arrow.up.right")
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        } header: {
                            Text("Guests")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }

                    // Artists Section
                    if !session.artists.isEmpty {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(session.artists, id: \.self) { artist in
                                    HStack(spacing: 8) {
                                        Image(systemName: "music.note.fill")
                                            .font(.caption)
                                            .foregroundColor(.orange)

                                        Text(artist)
                                            .font(.body)

                                        Spacer()

                                        Button(action: {}) {
                                            Image(systemName: "arrow.up.right")
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.blue)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        } header: {
                            Text("Artists")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }

                    // Notes
                    if let notes = session.notes, !notes.isEmpty {
                        Section {
                            Text(notes)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } header: {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Transcript")
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
}

#Preview {
    LivePlaybackDisplay(session: ListeningSession(
        id: "1",
        contentId: "prog1",
        contentType: .broadcast,
        providerId: "npo",
        title: "Sample Radio Program",
        source: "NPO Radio 1",
        startTime: Date(),
        duration: 3600,
        progress: 1800,
        categories: [.news, .interview],
        topics: ["Climate", "Technology"],
        guests: ["John Smith", "Jane Doe"],
        artists: ["Artist 1"],
        isFavorited: true,
        markerCount: 3
    ))
}
