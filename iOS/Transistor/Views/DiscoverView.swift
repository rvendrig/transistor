import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel = NPOViewModel()

    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                            .tint(.transistorGreen)
                        Text("Loading recent broadcasts...")
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

                Section("Recent Broadcasts") {
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

                                if let description = broadcast.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("🎉 Discover")
            .background(Color.darkBg)
            .onAppear {
                Task {
                    await viewModel.loadAllPrograms()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        DiscoverView()
    }
    .preferredColorScheme(.dark)
}
