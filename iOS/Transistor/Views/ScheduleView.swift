import SwiftUI

struct ScheduleView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var selectedDate = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Provider and Date Selector
                VStack(spacing: 12) {
                    // Date Picker
                    HStack {
                        Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.transistorGreen)
                        }

                        Spacer()

                        VStack(alignment: .center, spacing: 4) {
                            Text("Schedule")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.transistorGreen)
                        }
                    }
                    .padding()

                    // Live Now Section
                    LiveNowSection(viewModel: viewModel, selectedDate: selectedDate)
                }
                .background(Color.cardBg)

                // Schedule List
                List {
                    Section("Today's Schedule") {
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .tint(.transistorGreen)
                                Text("Loading schedule...")
                                    .foregroundColor(.gray)
                            }
                        } else {
                            ForEach(Array(0..<12), id: \.self) { index in
                                // Placeholder schedule items
                                ScheduleItemRow(
                                    title: "Program \(index + 1)",
                                    time: "\(String(format: "%02d", 6 + index)):00 - \(String(format: "%02d", 7 + index)):00",
                                    presenters: ["Host \(index + 1)"],
                                    isLive: index == 0
                                )
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.darkBg)
            }
            .navigationTitle("📻 Live Guide")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.darkBg)
            .onAppear {
                Task {
                    await viewModel.loadChannels()
                }
            }
        }
    }
}

// MARK: - Live Now Section
struct LiveNowSection: View {
    @ObservedObject var viewModel: ContentViewModel
    let selectedDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔴 Now Broadcasting")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.transistorGreen)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Placeholder live items
                    ForEach(0..<3, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Live Program \(index + 1)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .lineLimit(2)

                            Text("Now • 2 hours left")
                                .font(.caption)
                                .foregroundColor(.transistorGreen)

                            Spacer()

                            Label("Listen", systemImage: "play.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        .frame(width: 160, height: 140)
                        .padding()
                        .background(Color.cardBg)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Schedule Item Row
struct ScheduleItemRow: View {
    let title: String
    let time: String
    let presenters: [String]
    let isLive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if isLive {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }

                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                Text(time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if !presenters.isEmpty {
                Text("With: \(presenters.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.transistorGreen)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        ScheduleView()
    }
    .preferredColorScheme(.dark)
}
