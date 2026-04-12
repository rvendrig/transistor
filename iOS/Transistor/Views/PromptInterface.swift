import SwiftUI

struct PromptInterface: View {
    @StateObject var viewModel: ContentViewModel
    @State private var promptText = ""
    @State private var commandHistory: [String] = []
    @State private var selectedResult: ContentProvider? = nil
    @State private var showingResults = false

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

                // Quick Suggestions
                if promptText.isEmpty && !commandHistory.isEmpty {
                    quickSuggestionsView()
                }

                // Suggested Prompts
                if promptText.isEmpty {
                    suggestedPromptsView()
                }

                // Recent Commands
                if !commandHistory.isEmpty && promptText.isEmpty {
                    recentCommandsView()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Voice Commands")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

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
}

enum PromptIntent {
    case search
    case play
    case browse
    case filter
    case history
}

struct ParsedQuery {
    let intent: PromptIntent
    let provider: String?
    let category: ContentCategory?
    let query: String
}

#Preview {
    PromptInterface(viewModel: ContentViewModel())
}
