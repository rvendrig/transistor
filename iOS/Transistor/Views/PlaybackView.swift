import SwiftUI

struct PlaybackView: View {
    @StateObject var audioPlayer = AudioPlayerService.shared
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                if let content = audioPlayer.currentContent {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Art/Icon
                            VStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .aspectRatio(1, contentMode: .fit)

                                    if let image = content.image {
                                        AsyncImage(url: URL(string: image)) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                            } else if phase.error != nil {
                                                Image(systemName: "photo")
                                                    .font(.title)
                                                    .foregroundColor(.gray)
                                            } else {
                                                ProgressView()
                                            }
                                        }
                                    } else {
                                        Image(systemName: "waveform.circle")
                                            .font(.system(size: 60))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .frame(height: 250)
                                .cornerRadius(12)
                                .padding()
                            }

                            // Title and Metadata
                            VStack(spacing: 8) {
                                Text(content.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .lineLimit(3)

                                VStack(spacing: 4) {
                                    Text(content.publishDate.formatted(date: .abbreviated, time: .short))
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    if let duration = content.duration > 0 ? formatDuration(content.duration) : nil {
                                        Text("Duration: \(duration)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)

                            // Progress
                            VStack(spacing: 8) {
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(.systemGray5))

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.blue)
                                            .frame(width: geometry.size.width * (audioPlayer.duration > 0 ? CGFloat(audioPlayer.currentTime / audioPlayer.duration) : 0))
                                    }
                                }
                                .frame(height: 8)

                                HStack {
                                    Text(formatTime(audioPlayer.currentTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Text(formatTime(audioPlayer.duration))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Playback Controls
                            HStack(spacing: 20) {
                                Spacer()

                                Button(action: { audioPlayer.seek(to: max(0, audioPlayer.currentTime - 15)) }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "gobackward.15")
                                            .font(.title3)
                                        Text("15s")
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.blue)
                                }

                                Spacer()

                                Button(action: {
                                    if audioPlayer.isPlaying {
                                        audioPlayer.pause()
                                    } else {
                                        audioPlayer.resume()
                                    }
                                }) {
                                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 56))
                                        .foregroundColor(.blue)
                                }

                                Spacer()

                                Button(action: { audioPlayer.seek(to: min(audioPlayer.duration, audioPlayer.currentTime + 15)) }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "goforward.15")
                                            .font(.title3)
                                        Text("15s")
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.blue)
                                }

                                Spacer()
                            }

                            // Playback Speed
                            HStack(spacing: 12) {
                                Text("Speed")
                                    .font(.subheading)
                                    .foregroundColor(.secondary)

                                Spacer()

                                HStack(spacing: 8) {
                                    ForEach([0.75, 1.0, 1.25, 1.5], id: \.self) { speed in
                                        Button(action: { audioPlayer.setPlaybackRate(Float(speed)) }) {
                                            Text(String(format: "%.2fx", speed))
                                                .font(.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.2))
                                                .foregroundColor(.blue)
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)

                            // Listening Session Info (if exists)
                            if let session = viewModel.currentListeningSession {
                                ListeningSessionInfoCard(session: session)
                            }

                            Spacer()
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("Nothing Playing")
                            .font(.headline)

                        Text("Select content to begin playback")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle("Now Playing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }

        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct ListeningSessionInfoCard: View {
    let session: ListeningSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Listening Session")
                    .font(.subheading)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(session.percentage)%")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }

            if !session.topics.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Topics")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        ForEach(session.topics.prefix(2), id: \.self) { topic in
                            Text(topic)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(3)
                        }
                    }
                }
            }

            if !session.guests.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Guests")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        ForEach(session.guests.prefix(2), id: \.self) { guest in
                            Text(guest)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(3)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    PlaybackView(viewModel: ContentViewModel())
}
