# Prompt & Log Interface - Feature Design

## Overview

A conversational, AI-assisted interface alongside the traditional tabs that:
1. **Prompt Mode** - Type natural language to switch sources and search
2. **Live Display** - Real-time metadata (topics, guests, artists) during playback
3. **Listen Log** - Searchable history with smart categorization
4. **Context Wizards** - Quick actions based on content type

---

## 1. Data Models

### ListeningSession
```swift
struct ListeningSession: Identifiable, Codable {
    let id: String
    let contentId: String          // broadcast or episode ID
    let contentType: ContentType   // broadcast, episode, etc.
    let providerId: String
    let title: String
    let source: String             // "NPO", "Spotify", etc.
    let startTime: Date
    let endTime: Date?
    let duration: Int              // seconds listened
    let progress: Int              // seconds into content
    let categories: [String]       // "news", "music", "interview", etc.
    let topics: [String]           // extracted or tagged
    let guests: [String]           // people mentioned
    let artists: [String]          // if music
    let notes: String?             // user notes
    let isFavorited: Bool
    let markerCount: Int
    
    var percentage: Double {
        guard duration > 0 else { return 0 }
        return Double(progress) / Double(duration)
    }
    
    var timeAgo: String {
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < 60 { return "Now" }
        if elapsed < 3600 { return "\(Int(elapsed / 60))m ago" }
        if elapsed < 86400 { return "\(Int(elapsed / 3600))h ago" }
        return "\(Int(elapsed / 86400))d ago"
    }
}

enum ContentCategory: String, Codable {
    case news
    case music
    case interview
    case sports
    case education
    case entertainment
    case podcast
    case documentary
    case comedy
    case other
}

// Live metadata during playback
struct LiveMetadata: Codable {
    let contentTitle: String
    let currentTopic: String?
    let currentGuest: String?
    let currentArtist: String?
    let upcomingTopics: [String]
    let transcript: [TranscriptSegment]
    
    struct TranscriptSegment: Codable {
        let timestamp: Int          // seconds
        let text: String
        let speaker: String?        // who's speaking
        let isTopicChange: Bool
    }
}
```

---

## 2. Prompt Interface

### Features

**Natural Language Input**
```
"Play NPO Radio 1"
"Show me news from today"
"Find interviews about technology"
"What was I listening to yesterday?"
"Play my favorites"
"Find podcasts with David Attenborough"
```

**Prompt Parser (uses Claude API)**
- Extract intent: browse, search, filter, play
- Extract parameters: provider, category, topic, time range
- Return structured query

**UI Components**
- Text input field with autocomplete suggestions
- Command history (swipe up)
- Quick command buttons (presets)
- Voice input option (future)

### Implementation

```swift
struct PromptInterface: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var promptText = ""
    @State private var suggestions: [String] = []
    @State private var commandHistory: [String] = []
    @State private var showHistory = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top: Live metadata display
            if let session = viewModel.currentSession {
                LivePlaybackDisplay(session: session)
            }
            
            // Middle: Results or history
            if showHistory {
                CommandHistory(commands: commandHistory)
            } else {
                SearchResults(results: viewModel.searchResults)
            }
            
            // Bottom: Prompt input
            PromptInputBar(
                text: $promptText,
                suggestions: suggestions,
                onSubmit: handlePrompt(_:),
                onVoice: handleVoiceInput()
            )
        }
    }
    
    func handlePrompt(_ text: String) {
        commandHistory.append(text)
        // Parse prompt using Claude API
        Task {
            let parsed = try await parsePrompt(text)
            await viewModel.executePromptQuery(parsed)
        }
    }
}
```

---

## 3. Live Listening Display

### What Shows During Playback

```swift
struct LivePlaybackDisplay: View {
    let session: ListeningSession
    @State private var showTranscript = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Now Playing
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(session.source)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                ZStack(alignment: .center) {
                    Circle()
                        .stroke(Color.cardBg, lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: session.percentage)
                        .stroke(Color.transistorGreen, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(session.percentage * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.cardBg)
            .cornerRadius(12)
            
            // Current Section
            if let topic = session.topics.first {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Current Topic", systemImage: "bookmark.fill")
                        .font(.caption)
                        .foregroundColor(.transistorGreen)
                    
                    Text(topic)
                        .font(.body)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .padding()
                .background(Color.cardBg)
                .cornerRadius(8)
            }
            
            // Guests/Artists
            if !session.guests.isEmpty || !session.artists.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !session.guests.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.transistorGreen)
                            Text("Guests: " + session.guests.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if !session.artists.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "music.note")
                                .foregroundColor(.transistorGreen)
                            Text("Artists: " + session.artists.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.cardBg)
                .cornerRadius(8)
            }
            
            // View Transcript
            if !session.topics.isEmpty {
                Button(action: { showTranscript = true }) {
                    HStack {
                        Image(systemName: "text.alignleft")
                        Text("View Transcript & Topics")
                    }
                    .font(.caption)
                    .foregroundColor(.transistorGreen)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.cardBg)
                    .cornerRadius(8)
                }
            }
        }
        .sheet(isPresented: $showTranscript) {
            TranscriptView(session: session)
        }
    }
}
```

---

## 4. Listening Log / History

### Browse History

```swift
struct ListeningLogView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var filterCategory: ContentCategory? = nil
    @State private var sortBy: SortOption = .recent
    
    enum SortOption {
        case recent
        case longest
        case mostMarked
        case byTopic
    }
    
    var filteredSessions: [ListeningSession] {
        var sessions = viewModel.listeningHistory
        
        if let category = filterCategory {
            sessions = sessions.filter { $0.categories.contains(category.rawValue) }
        }
        
        switch sortBy {
        case .recent:
            return sessions.sorted { $0.startTime > $1.startTime }
        case .longest:
            return sessions.sorted { $0.duration > $1.duration }
        case .mostMarked:
            return sessions.sorted { $0.markerCount > $1.markerCount }
        case .byTopic:
            return sessions.sorted { $0.topics.joined() > $1.topics.joined() }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter & Sort
                HStack(spacing: 12) {
                    Menu {
                        ForEach(ContentCategory.allCases, id: \.self) { category in
                            Button(action: { filterCategory = category == filterCategory ? nil : category }) {
                                HStack {
                                    if filterCategory == category {
                                        Image(systemName: "checkmark")
                                    }
                                    Text(category.rawValue.capitalized)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            Text("Filter")
                                .font(.caption)
                        }
                        .foregroundColor(.transistorGreen)
                        .padding(8)
                        .background(Color.cardBg)
                        .cornerRadius(6)
                    }
                    
                    Menu {
                        Button("Recent") { sortBy = .recent }
                        Button("Longest") { sortBy = .longest }
                        Button("Most Marked") { sortBy = .mostMarked }
                        Button("By Topic") { sortBy = .byTopic }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Sort")
                                .font(.caption)
                        }
                        .foregroundColor(.transistorGreen)
                        .padding(8)
                        .background(Color.cardBg)
                        .cornerRadius(6)
                    }
                    
                    Spacer()
                }
                .padding()
                
                // Listening History List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredSessions) { session in
                            ListeningLogItem(session: session)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("📻 Listen History")
            .background(Color.darkBg)
        }
    }
}

struct ListeningLogItem: View {
    let session: ListeningSession
    @State private var showDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text(session.source)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(session.timeAgo)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if session.isFavorited {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            // Topics & Guests (scrollable chips)
            if !session.topics.isEmpty || !session.guests.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(session.topics.prefix(3), id: \.self) { topic in
                            Label(topic, systemImage: "bookmark.fill")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.transistorGreen.opacity(0.3))
                                .cornerRadius(12)
                        }
                        
                        ForEach(session.guests.prefix(2), id: \.self) { guest in
                            Label(guest, systemImage: "person.fill")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.3))
                                .cornerRadius(12)
                        }
                        
                        if session.markerCount > 0 {
                            Label("\(session.markerCount) marks", systemImage: "bookmark")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.3))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            // Progress bar
            HStack(spacing: 8) {
                ProgressView(value: Double(session.progress) / Double(session.duration))
                    .tint(.transistorGreen)
                
                Text("\(session.progress / 60)m / \(session.duration / 60)m")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // Quick Actions
            HStack(spacing: 12) {
                Button(action: { showDetail = true }) {
                    Label("Details", systemImage: "info.circle")
                        .font(.caption2)
                        .foregroundColor(.transistorGreen)
                }
                
                Button(action: { /* Resume playback */ }) {
                    Label("Resume", systemImage: "play.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.transistorGreen)
                }
                
                Button(action: { /* Share */ }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.caption2)
                        .foregroundColor(.transistorGreen)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(12)
        .sheet(isPresented: $showDetail) {
            ListeningSessionDetail(session: session)
        }
    }
}
```

---

## 5. Contextual Wizards

### Per-Content-Type Actions

```swift
struct ContentWizard {
    let contentType: ContentCategory
    let actions: [WizardAction]
}

enum WizardAction {
    case relatedContent(query: String)
    case seeGuests
    case readTranscript
    case shareHighlight
    case createPlaylist
    case findSimilar
    case learnMore
    case downloadEpisode
    case followArtist
    case followPodcast
}

// News Wizard
struct NewsWizard: View {
    let session: ListeningSession
    
    var body: some View {
        VStack(spacing: 16) {
            Text("News Summary")
                .font(.headline)
                .fontWeight(.bold)
            
            // Show topics discussed
            VStack(alignment: .leading, spacing: 8) {
                Text("Topics Covered:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                ForEach(session.topics, id: \.self) { topic in
                    Button(action: { /* Search related news */ }) {
                        HStack {
                            Text(topic)
                            Spacer()
                            Image(systemName: "magnifyingglass")
                        }
                        .foregroundColor(.transistorGreen)
                        .padding()
                        .background(Color.cardBg)
                        .cornerRadius(8)
                    }
                }
            }
            
            Divider()
            
            // Quick actions
            Button(action: { /* Find similar news */ }) {
                Label("Find Similar News", systemImage: "newspaper.fill")
            }
            
            Button(action: { /* Save for later */ }) {
                Label("Save for Later", systemImage: "bookmark")
            }
            
            Button(action: { /* Read full transcript */ }) {
                Label("Full Transcript", systemImage: "doc.text")
            }
        }
        .padding()
    }
}

// Music Wizard
struct MusicWizard: View {
    let session: ListeningSession
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Music Details")
                .font(.headline)
                .fontWeight(.bold)
            
            // Show artists
            VStack(alignment: .leading, spacing: 8) {
                ForEach(session.artists, id: \.self) { artist in
                    Button(action: { /* Follow artist */ }) {
                        HStack {
                            Image(systemName: "music.mic")
                            Text(artist)
                            Spacer()
                            Image(systemName: "heart")
                        }
                        .foregroundColor(.transistorGreen)
                        .padding()
                        .background(Color.cardBg)
                        .cornerRadius(8)
                    }
                }
            }
            
            Divider()
            
            Button(action: { /* Add to playlist */ }) {
                Label("Add to Playlist", systemImage: "plus.circle")
            }
            
            Button(action: { /* Download */ }) {
                Label("Download Episode", systemImage: "arrow.down.circle")
            }
            
            Button(action: { /* Share */ }) {
                Label("Share Playlist", systemImage: "square.and.arrow.up")
            }
        }
        .padding()
    }
}

// Podcast Wizard
struct PodcastWizard: View {
    let session: ListeningSession
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Episode Info")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                if !session.guests.isEmpty {
                    Label("Guests: " + session.guests.joined(separator: ", "), systemImage: "person.fill")
                        .foregroundColor(.gray)
                }
                
                Label("Topics: " + session.topics.joined(separator: ", "), systemImage: "bookmark")
                    .foregroundColor(.gray)
            }
            .font(.caption)
            
            Divider()
            
            Button(action: { /* Subscribe to podcast */ }) {
                Label("Subscribe to Podcast", systemImage: "bell.badge")
            }
            
            Button(action: { /* Share episode */ }) {
                Label("Share Episode Link", systemImage: "link")
            }
            
            Button(action: { /* Follow guest */ }) {
                Label("Follow Guest", systemImage: "person.badge.plus")
            }
            
            Button(action: { /* Read notes */ }) {
                Label("Show Notes", systemImage: "list.bullet")
            }
        }
        .padding()
    }
}
```

---

## 6. Prompt Parser (Claude API)

```swift
struct PromptParser {
    static func parsePrompt(_ text: String) async throws -> ParsedQuery {
        let systemPrompt = """
        You are a radio/podcast navigation assistant. Parse user prompts into structured commands.
        
        Return JSON with:
        - intent: "browse" | "search" | "play" | "filter" | "history"
        - provider: provider ID or null
        - category: content type or null
        - query: search string or null
        - timeRange: "today" | "week" | "month" | "all" or null
        
        Examples:
        "Play NPO Radio 1" → {"intent": "play", "provider": "npo", "category": null}
        "Show me news from today" → {"intent": "filter", "category": "news", "timeRange": "today"}
        "Find interviews about tech" → {"intent": "search", "category": "interview", "query": "tech"}
        """
        
        let response = try await ClaudeAPI.message(
            systemPrompt: systemPrompt,
            userMessage: text,
            model: "claude-3-5-sonnet-20241022"
        )
        
        return try JSONDecoder().decode(ParsedQuery.self, from: response.data(using: .utf8)!)
    }
}

struct ParsedQuery: Codable {
    let intent: String
    let provider: String?
    let category: String?
    let query: String?
    let timeRange: String?
}
```

---

## 7. Future Enhancements

- 🤖 **AI Summaries** - Claude generates summary of listening session
- 🔊 **Voice Commands** - "Hey Transistor, play NPO"
- 📊 **Listening Stats** - Most listened topics, artists, etc.
- 🧠 **Smart Recommendations** - Based on listening history
- 💾 **Export History** - Download as CSV/JSON
- 🔗 **Deep Links** - Share specific timestamps
- 📝 **Auto-Tagging** - Claude tags content automatically
- 🎯 **Notifications** - When favorite artists/topics broadcast
- 🌐 **Social** - Share with friends, see what they're listening

---

## Integration Points

1. **With Existing Tabs**
   - Prompt interface as 6th tab OR overlay modal
   - History accessible from main navigation
   - Seamless handoff between interfaces

2. **With Playback**
   - Live metadata updates during playback
   - Session tracking starts automatically
   - Markers integrate into log

3. **With Database**
   - New `listening_sessions` table
   - Track all listening (with privacy controls)
   - Index by date, category, provider

4. **With Claude API**
   - Parse natural language prompts
   - Generate summaries (future)
   - Smart tagging (future)

---

## User Experience Flow

```
User opens app
    ↓
Sees tabbed interface + Prompt button
    ↓
Types: "Show me interviews"
    ↓
Claude parses → filters to interviews
    ↓
User taps one → plays with live metadata
    ↓
Live display shows: "Interviewing Jane Smith about AI"
    ↓
User clicks transcript → sees full dialog + timestamps
    ↓
User marks interesting moments (markers)
    ↓
Session saved to log automatically
    ↓
Can search history: "Find all Jane Smith interviews"
    ↓
One-click actions: Subscribe, Share, Follow, Save
```

This creates a **hybrid experience**: traditional navigation + conversational AI + smart history with contextual wizards.

