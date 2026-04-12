import SwiftUI

struct LogView: View {
    @ObservedObject var viewModel: ContentViewModel

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateStyle = .medium
        return f
    }()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var groupedSessions: [(String, [ListeningSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.listeningHistory) { session in
            if calendar.isDateInToday(session.startTime) {
                return "Vandaag"
            } else if calendar.isDateInYesterday(session.startTime) {
                return "Gisteren"
            } else {
                return dateFormatter.string(from: session.startTime)
            }
        }
        return grouped.sorted { a, b in
            let aDate = a.value.first?.startTime ?? .distantPast
            let bDate = b.value.first?.startTime ?? .distantPast
            return aDate > bDate
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.listeningHistory.isEmpty && !viewModel.isLoadingListeningHistory {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Nog niets beluisterd")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Je luistergeschiedenis verschijnt hier")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                }

                // Luistersessies per dag
                ForEach(groupedSessions, id: \.0) { dateLabel, sessions in
                    Section(header: Text(dateLabel).foregroundColor(.white)) {
                        ForEach(sessions) { session in
                            HStack(spacing: 12) {
                                // Play indicator
                                Image(systemName: sessionIcon(session))
                                    .foregroundColor(.transistorGreen)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    HStack(spacing: 8) {
                                        Text("\(timeFormatter.string(from: session.startTime))")
                                            .font(.caption)
                                            .foregroundColor(.gray)

                                        if session.duration > 0 {
                                            Text("\(session.progress / 60) van \(session.duration / 60) min")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    HStack(spacing: 8) {
                                        Text(session.source)
                                            .font(.caption)
                                            .foregroundColor(.gray)

                                        if session.markerCount > 0 {
                                            Label("\(session.markerCount)", systemImage: "bookmark.fill")
                                                .font(.caption)
                                                .foregroundColor(.transistorGreen)
                                        }
                                    }
                                }

                                Spacer()

                                // Progress
                                if session.percentage > 0 && session.percentage < 100 {
                                    Text("\(session.percentage)%")
                                        .font(.caption)
                                        .foregroundColor(.transistorGreen)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Markers sectie
                if !viewModel.markers.isEmpty {
                    Section(header: Text("Markers").foregroundColor(.white)) {
                        ForEach(viewModel.markers) { marker in
                            HStack(spacing: 12) {
                                Image(systemName: "bookmark.fill")
                                    .foregroundColor(.transistorGreen)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(formatTimestamp(marker.timestamp))
                                        .font(.caption)
                                        .foregroundColor(.transistorGreen)

                                    if !marker.tags.isEmpty {
                                        Text(marker.tags.joined(separator: ", "))
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Log")
            .background(Color.darkBg)
            .onAppear {
                viewModel.loadListeningHistory()
            }
        }
    }

    private func sessionIcon(_ session: ListeningSession) -> String {
        if session.contentType == .broadcast {
            return "antenna.radiowaves.left.and.right"
        } else {
            return "headphones"
        }
    }

    private func formatTimestamp(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
