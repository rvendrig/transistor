import Foundation

@MainActor
class ContentViewModel: ObservableObject {
    // MARK: - Content Properties
    @Published var channels: [Channel] = []
    @Published var programs: [Program] = []
    @Published var broadcasts: [Broadcast] = []
    @Published var episodes: [Episode] = []

    // MARK: - Loading States
    @Published var isLoading = false
    @Published var isLoadingChannels = false
    @Published var errorMessage: String?

    // MARK: - Provider Management
    @Published var selectedProviders: Set<String> = ["npo"]
    let providerStore = ProviderStore.shared

    // MARK: - Playlist properties
    @Published var playlists: [Playlist] = []
    @Published var playlistItems: [PlaylistItem] = []
    @Published var selectedPlaylist: Playlist?
    @Published var isLoadingPlaylists = false
    @Published var playlistError: String?

    // MARK: - Marker properties
    @Published var markers: [Marker] = []
    @Published var isLoadingMarkers = false
    @Published var markerError: String?

    // MARK: - Favorite properties
    @Published var favorites: [Favorite] = []
    @Published var isFavoritedContent: Set<String> = []
    @Published var isLoadingFavorites = false
    @Published var favoriteError: String?

    // MARK: - Listening Session properties
    @Published var listeningHistory: [ListeningSession] = []
    @Published var currentListeningSession: ListeningSession?
    @Published var isLoadingListeningHistory = false
    @Published var listeningSessionError: String?

    // MARK: - Search
    @Published var searchResults: UnifiedSearchResult = UnifiedSearchResult(programs: [], broadcasts: [], episodes: [])
    @Published var isSearching = false

    private let dbService = DatabaseService.shared

    // MARK: - Channel Loading
    func loadChannels() async {
        isLoadingChannels = true
        errorMessage = nil
        var allChannels: [Channel] = []

        for providerId in selectedProviders {
            guard let provider = providerStore.provider(byId: providerId) else { continue }

            do {
                let channels = try await provider.fetchChannels()
                allChannels.append(contentsOf: channels)
            } catch {
                print("Error loading channels from \(providerId): \(error.localizedDescription)")
                errorMessage = "Failed to load some channels"
            }
        }

        self.channels = allChannels
        isLoadingChannels = false
    }

    // MARK: - Programs Loading
    func loadPrograms(forChannel channel: Channel) async {
        isLoading = true
        errorMessage = nil

        guard let provider = providerStore.provider(byId: channel.providerId) else {
            errorMessage = "Provider not found"
            isLoading = false
            return
        }

        do {
            programs = try await provider.fetchPrograms(forChannel: channel.id)
        } catch {
            errorMessage = "Failed to load programs: \(error.localizedDescription)"
            programs = []
        }

        isLoading = false
    }

    // MARK: - Broadcasts Loading
    func loadBroadcasts(forProgram program: Program) async {
        isLoading = true
        errorMessage = nil

        guard let provider = providerStore.provider(byId: program.providerId) else {
            errorMessage = "Provider not found"
            isLoading = false
            return
        }

        do {
            broadcasts = try await provider.fetchBroadcasts(forProgram: program.id)
        } catch {
            errorMessage = "Failed to load broadcasts: \(error.localizedDescription)"
            broadcasts = []
        }

        isLoading = false
    }

    // MARK: - Episodes Loading
    func loadEpisodes(forFeed feedId: String, provider: ContentProvider) async {
        isLoading = true
        errorMessage = nil

        if let podcastProvider = provider as? PodcastFeedProvider {
            episodes = podcastProvider.getEpisodes(forFeed: feedId)
        }

        isLoading = false
    }

    // MARK: - Unified Search
    func search(_ query: String) async {
        guard !query.isEmpty else {
            searchResults = UnifiedSearchResult(programs: [], broadcasts: [], episodes: [])
            return
        }

        isSearching = true
        errorMessage = nil

        var allPrograms: [Program] = []
        var allBroadcasts: [Broadcast] = []
        var allEpisodes: [Episode] = []

        for providerId in selectedProviders {
            guard let provider = providerStore.provider(byId: providerId) else { continue }

            do {
                let results = try await provider.search(query)

                for result in results {
                    if let program = result as? Program {
                        allPrograms.append(program)
                    } else if let broadcast = result as? Broadcast {
                        allBroadcasts.append(broadcast)
                    } else if let episode = result as? Episode {
                        allEpisodes.append(episode)
                    }
                }
            } catch {
                print("Error searching \(providerId): \(error.localizedDescription)")
            }
        }

        searchResults = UnifiedSearchResult(
            programs: allPrograms,
            broadcasts: allBroadcasts,
            episodes: allEpisodes
        )
        isSearching = false
    }

    // MARK: - Provider Management
    func setProviderActive(_ providerId: String, _ active: Bool) {
        if active {
            selectedProviders.insert(providerId)
        } else {
            selectedProviders.remove(providerId)
        }
    }

    func isProviderActive(_ providerId: String) -> Bool {
        selectedProviders.contains(providerId)
    }

    // MARK: - Playlist Methods (same as before but updated for generic content)
    func loadPlaylists() {
        isLoadingPlaylists = true
        playlistError = nil

        do {
            playlists = dbService.getAllPlaylists()
            isLoadingPlaylists = false
        } catch {
            playlistError = "Failed to load playlists"
            isLoadingPlaylists = false
            print("Error loading playlists: \(error.localizedDescription)")
        }
    }

    func createPlaylist(name: String, description: String? = nil) {
        playlistError = nil

        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            playlistError = "Playlist name cannot be empty"
            return
        }

        if let playlist = dbService.createPlaylist(name: name, description: description) {
            playlists.append(playlist)
        } else {
            playlistError = "Failed to create playlist"
        }
    }

    func deletePlaylist(_ playlistId: String) {
        playlistError = nil

        if dbService.deletePlaylist(playlistId) {
            playlists.removeAll { $0.id == playlistId }
            if selectedPlaylist?.id == playlistId {
                selectedPlaylist = nil
            }
        } else {
            playlistError = "Failed to delete playlist"
        }
    }

    // MARK: - Marker Methods (updated for generic content)
    func loadMarkers(forContent contentId: String) {
        isLoadingMarkers = true
        markerError = nil

        markers = dbService.getMarkersByContent(contentId)
        isLoadingMarkers = false
    }

    func createMarker(contentId: String, contentType: ContentType, providerId: String, timestamp: Int, tags: [String]) {
        markerError = nil

        guard !tags.isEmpty else {
            markerError = "Please add at least one tag to the marker"
            return
        }

        if let marker = dbService.createMarker(contentId: contentId, contentType: contentType, providerId: providerId, timestamp: timestamp, tags: tags) {
            markers.append(marker)
        } else {
            markerError = "Failed to create marker"
        }
    }

    func deleteMarker(_ markerId: String) {
        markerError = nil

        if dbService.deleteMarker(markerId) {
            markers.removeAll { $0.id == markerId }
        } else {
            markerError = "Failed to delete marker"
        }
    }

    // MARK: - Favorite Methods (updated for generic content)
    func loadFavorites() {
        isLoadingFavorites = true
        favoriteError = nil

        do {
            favorites = dbService.getAllFavorites()
            isFavoritedContent = Set(favorites.map { $0.contentId })
            isLoadingFavorites = false
        } catch {
            favoriteError = "Failed to load favorites"
            isLoadingFavorites = false
        }
    }

    func toggleFavorite(contentId: String, contentType: ContentType, providerId: String) {
        favoriteError = nil

        if isFavoritedContent.contains(contentId) {
            // Remove from favorites
            if dbService.removeFavorite(contentId) {
                isFavoritedContent.remove(contentId)
                favorites.removeAll { $0.contentId == contentId }
            } else {
                favoriteError = "Failed to remove from favorites"
            }
        } else {
            // Add to favorites
            if let favorite = dbService.addFavorite(contentId: contentId, contentType: contentType, providerId: providerId) {
                isFavoritedContent.insert(contentId)
                favorites.append(favorite)
            } else {
                favoriteError = "Failed to add to favorites"
            }
        }
    }

    func isFavorited(_ contentId: String) -> Bool {
        isFavoritedContent.contains(contentId)
    }

    // MARK: - Listening Session Methods
    func loadListeningHistory(limit: Int = 50) {
        isLoadingListeningHistory = true
        listeningSessionError = nil

        do {
            listeningHistory = dbService.getListeningHistory(limit: limit)
            isLoadingListeningHistory = false
        } catch {
            listeningSessionError = "Failed to load listening history"
            isLoadingListeningHistory = false
            print("Error loading listening history: \(error.localizedDescription)")
        }
    }

    func startListeningSession(contentId: String, contentType: ContentType, providerId: String, title: String, source: String, duration: Int, categories: [ContentCategory] = [], topics: [String] = [], guests: [String] = [], artists: [String] = []) {
        listeningSessionError = nil

        if let session = dbService.createListeningSession(contentId: contentId, contentType: contentType, providerId: providerId, title: title, source: source, duration: duration, categories: categories, topics: topics, guests: guests, artists: artists) {
            currentListeningSession = session
            listeningHistory.insert(session, at: 0)
        } else {
            listeningSessionError = "Failed to start listening session"
        }
    }

    func updateCurrentSessionProgress(_ progress: Int) {
        listeningSessionError = nil

        guard let session = currentListeningSession else {
            listeningSessionError = "No active listening session"
            return
        }

        if dbService.updateListeningSessionProgress(session.id, progress: progress) {
            // Update local copy
            if let index = listeningHistory.firstIndex(where: { $0.id == session.id }) {
                listeningHistory[index].progress = progress
                currentListeningSession?.progress = progress
            }
        } else {
            listeningSessionError = "Failed to update session progress"
        }
    }

    func endCurrentListeningSession() {
        listeningSessionError = nil

        guard let session = currentListeningSession else {
            listeningSessionError = "No active listening session"
            return
        }

        if dbService.endListeningSession(session.id) {
            currentListeningSession = nil
        } else {
            listeningSessionError = "Failed to end listening session"
        }
    }

    func getListeningHistoryByCategory(_ category: ContentCategory, limit: Int = 50) -> [ListeningSession] {
        return dbService.getListeningSessionsByCategory(category, limit: limit)
    }

    func addNoteToListeningSession(_ sessionId: String, note: String) {
        listeningSessionError = nil

        if dbService.addNoteToListeningSession(sessionId, note: note) {
            // Update local copy
            if let index = listeningHistory.firstIndex(where: { $0.id == sessionId }) {
                listeningHistory[index].notes = note
            }
        } else {
            listeningSessionError = "Failed to add note to session"
        }
    }
}
