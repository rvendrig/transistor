import SwiftUI

struct ListeningHubView: View {
    @StateObject var viewModel: ContentViewModel
    @State private var selectedTab: HubTab = .history
    @State private var selectedCategory: ContentCategory? = nil
    @State private var sortBy: SortOption = .recent
    @State private var promptText = ""
    @State private var commandHistory: [String] = []

    enum HubTab {
        case history
        case commands
    }

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

    var suggestions: [String] {
        [
            "Play NPO Radio 1",
            "Show me news from today",
            "Find interviews about technology",
            "Search music programs",
            "Browse podcasts",
            "What's live now?"
        ]
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segment Control
                Picker("View", selection: $selectedTab) {
                    Label("History", systemImage: "clock.fill").tag(HubTab.history)
                    Label("Commands", systemImage: "waveform.circle").tag(HubTab.commands)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(.systemGray6))

                // Content
                Group {
                    if selectedTab == .history {
                        historyView()
                    } else {
                        commandsView()
                    }
                }

                Spacer()
            }
            .navigationTitle("Listening Hub")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadListeningHistory()
            }
        }
    }

    // MARK: - History View

    private func historyView() -> some View {
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
    }

    // MARK: - Commands View

    private func commandsView() -> some View {
        VStack(spacing: 16) {
            // Prompt Input
            HStack(spacing: 12) {
                Image(systemName: "waveform")
                    .font(.title2)
                    .foregroundColor(.blue)

                TextField("Ask anything...", text: $promptText, onCommit: handlePrompt)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)

                Button(action: handlePrompt) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(promptText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            ScrollView {
                VStack(spacing: 16) {
                    // Quick Suggestions
                    quickSuggestionsView()

                    // Suggested Prompts
                    if promptText.isEmpty {
                        suggestedPromptsView()
                    }

                    // Recent Commands
                    if !commandHistory.isEmpty && promptText.isEmpty {
                        recentCommandsView()
                    }
                }
                .padding()
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Helper Views

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

    private func quickSuggestionsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 8) {
                Button(action: {
                    promptText = "Browse all channels"
                    handlePrompt()
                }) {
                    Label("Browse", systemImage: "square.grid.2x2")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                }

                Button(action: {
                    promptText = "Show live now"
                    handlePrompt()
                }) {
                    Label("Live Now", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }

                Button(action: {
                    promptText = "Show my listening history"
                    handlePrompt()
                }) {
                    Label("History", systemImage: "clock")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
            }
        }
    }

    private func suggestedPromptsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try Asking")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        promptText = suggestion
                        handlePrompt()
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.blue)

                            Text(suggestion)
                                .font(.body)
                                .lineLimit(1)

                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    private func recentCommandsView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Commands")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(commandHistory.prefix(5), id: \.self) { command in
                    Button(action: {
                        promptText = command
                        handlePrompt()
                    }) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text(command)
                                .font(.body)
                                .lineLimit(1)

                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    // MARK: - Command Handler

    private func handlePrompt() {
        guard !promptText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // Add to history
        commandHistory.insert(promptText, at: 0)
        if commandHistory.count > 10 {
            commandHistory.removeLast()
        }

        // Parse the prompt
        let query = parsePrompt(promptText)

        // Execute based on intent
        executePromptIntent(query)

        // Clear input
        promptText = ""
    }

    private func parsePrompt(_ text: String) -> ParsedQuery {
        let lowercased = text.lowercased()

        // Simple intent detection
        var intent = PromptIntent.search

        if lowercased.contains("play") || lowercased.contains("listen") {
            intent = .play
        } else if lowercased.contains("browse") || lowercased.contains("show me") {
            intent = .browse
        } else if lowercased.contains("live") || lowercased.contains("now") {
            intent = .filter
        } else if lowercased.contains("history") || lowercased.contains("listening") {
            intent = .history
        }

        // Extract keywords
        var provider: String? = nil
        if lowercased.contains("npo") {
            provider = "npo"
        } else if lowercased.contains("bbc") {
            provider = "bbc"
        }

        // Extract category
        var category: ContentCategory? = nil
        for cat in ContentCategory.allCases {
            if lowercased.contains(cat.rawValue) {
                category = cat
                break
            }
        }

        // Remove command keywords for query
        var query = text
        let keywords = ["play", "listen", "browse", "show me", "find", "search", "live", "now", "history"]
        for keyword in keywords {
            query = query.replacingOccurrences(of: keyword, with: "").trimmingCharacters(in: .whitespaces)
        }

        return ParsedQuery(intent: intent, provider: provider, category: category, query: query)
    }

    private func executePromptIntent(_ query: ParsedQuery) {
        switch query.intent {
        case .search:
            Task {
                await viewModel.search(query.query)
            }

        case .play:
            if let provider = query.provider {
                viewModel.setProviderActive(provider, true)
            }
            Task {
                await viewModel.search(query.query)
            }

        case .browse:
            Task {
                await viewModel.loadChannels()
            }

        case .filter:
            Task {
                await viewModel.loadChannels()
            }

        case .history:
            viewModel.loadListeningHistory()
            selectedTab = .history
        }
    }
}

#Preview {
    ListeningHubView(viewModel: ContentViewModel())
}
