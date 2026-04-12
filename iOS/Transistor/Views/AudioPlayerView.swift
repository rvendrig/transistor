import SwiftUI

struct AudioPlayerView: View {
    @StateObject var audioPlayer = AudioPlayerService.shared
    @State private var showingPlayer = false
    let content: AudioContent?

    var body: some View {
        VStack(spacing: 12) {
            if let content = audioPlayer.currentContent {
                // Mini Player
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(content.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        Text(content.publishDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: audioPlayer.pause) {
                            Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                .font(.caption)
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

                // Progress
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(.systemGray5))

                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * (audioPlayer.duration > 0 ? CGFloat(audioPlayer.currentTime / audioPlayer.duration) : 0))
                        }
                        .cornerRadius(2)
                    }
                    .frame(height: 3)

                    HStack {
                        Text(formatTime(audioPlayer.currentTime))
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(formatTime(audioPlayer.duration))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Full Player
            if showingPlayer {
                fullPlayerView()
            }
        }
    }

    private func fullPlayerView() -> some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { showingPlayer = false }) {
                    Image(systemName: "chevron.down")
                        .foregroundColor(.primary)
                }

                Spacer()

                if let content = audioPlayer.currentContent {
                    Text(content.title)
                        .font(.headline)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: { audioPlayer.stop() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            }

            if let content = audioPlayer.currentContent {
                VStack(spacing: 8) {
                    Text(content.title)
                        .font(.headline)
                        .lineLimit(2)

                    Text(content.publishDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }

            // Large Progress
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))

                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * (audioPlayer.duration > 0 ? CGFloat(audioPlayer.currentTime / audioPlayer.duration) : 0))
                    }
                    .cornerRadius(4)
                }
                .frame(height: 6)

                HStack {
                    Text(formatTime(audioPlayer.currentTime))
                        .font(.body)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(formatTime(audioPlayer.duration))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }

            // Playback Controls
            HStack(spacing: 20) {
                Button(action: { audioPlayer.seek(to: max(0, audioPlayer.currentTime - 15)) }) {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                Spacer()

                Button(action: { audioPlayer.pause() }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                }

                Spacer()

                Button(action: { audioPlayer.seek(to: min(audioPlayer.duration, audioPlayer.currentTime + 15)) }) {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            // Playback Speed
            HStack {
                Text("Speed")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 8) {
                    ForEach([0.75, 1.0, 1.25, 1.5], id: \.self) { speed in
                        Button(action: { audioPlayer.setPlaybackRate(Float(speed)) }) {
                            Text(String(format: "%.2fx", speed))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }

            Spacer()
        }
        .padding()
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
}

#Preview {
    AudioPlayerView(content: nil)
}
