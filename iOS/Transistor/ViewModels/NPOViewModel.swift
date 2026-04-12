import Foundation

@MainActor
class NPOViewModel: ObservableObject {
    @Published var channels: [NPOChannel] = []
    @Published var programs: [NPOProgram] = []
    @Published var broadcasts: [NPOBroadcast] = []
    @Published var items: [NPOItem] = []

    @Published var isLoading = false
    @Published var errorMessage: String?

    // Playlist properties
    @Published var playlists: [Playlist] = []
    @Published var playlistItems: [PlaylistItem] = []
    @Published var selectedPlaylist: Playlist?
    @Published var isLoadingPlaylists = false
    @Published var playlistError: String?

    // Marker properties
    @Published var markers: [NPOMarker] = []
    @Published var isLoadingMarkers = false
    @Published var markerError: String?

    // Favorite properties
    @Published var favorites: [NPOFavorite] = []
    @Published var isFavoritedBroadcasts: Set<String> = []
    @Published var isLoadingFavorites = false
    @Published var favoriteError: String?

    private let apiService = NPOAPIService.shared
    private let mockDataService = NPODataService.shared
    private let dbService = DatabaseService.shared

    // MARK: - Load Channels

    func loadChannels() {
        channels = mockDataService.getAllChannels()
    }

    // MARK: - Load Programs

    func loadPrograms(forChannel channelId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Try to fetch from API first
            programs = try await apiService.fetchPrograms(forChannel: channelId)

            // Save to database
            for program in programs {
                // Save program logic here if needed
            }
        } catch {
            // Fallback to mock data
            print("API Error: \(error.localizedDescription)")
            programs = mockDataService.getProgramsForChannel(channelId)
            errorMessage = "Using offline data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Load Broadcasts

    func loadBroadcasts(forProgram programId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Try to fetch from API first
            broadcasts = try await apiService.fetchBroadcasts(forProgram: programId)

            // Save to database
            for broadcast in broadcasts {
                dbService.saveBroadcast(broadcast)
            }
        } catch {
            // Fallback to mock data
            print("API Error: \(error.localizedDescription)")
            broadcasts = mockDataService.getBroadcastsForProgram(programId)
            errorMessage = "Using offline data"
        }

        isLoading = false
    }

    // MARK: - Load Items

    func loadItems(forBroadcast broadcastId: String) {
        items = mockDataService.getItemsForBroadcast(broadcastId)
    }

    // MARK: - Search

    func searchPrograms(_ query: String) async {
        guard !query.isEmpty else {
            programs = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            programs = try await apiService.searchPrograms(query)
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Load All Programs (for Discover)

    func loadAllPrograms() async {
        isLoading = true
        errorMessage = nil

        do {
            programs = try await apiService.fetchAllPrograms()
        } catch {
            errorMessage = "Failed to load programs"
        }

        isLoading = false
    }

    // MARK: - Playlists

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
            print("Error: Could not create playlist in database")
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
            print("Error: Could not delete playlist from database")
        }
    }

    func renamePlaylist(_ playlistId: String, newName: String) {
        playlistError = nil

        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else {
            playlistError = "Playlist name cannot be empty"
            return
        }

        if dbService.updatePlaylistName(playlistId, newName: newName) {
            if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
                playlists[index] = Playlist(
                    id: playlistId,
                    name: newName,
                    description: playlists[index].description,
                    createdAt: playlists[index].createdAt,
                    itemCount: playlists[index].itemCount
                )
            }
            if selectedPlaylist?.id == playlistId {
                selectedPlaylist = Playlist(
                    id: playlistId,
                    name: newName,
                    description: selectedPlaylist?.description,
                    createdAt: selectedPlaylist?.createdAt ?? Date(),
                    itemCount: selectedPlaylist?.itemCount ?? 0
                )
            }
        } else {
            playlistError = "Failed to rename playlist"
            print("Error: Could not rename playlist in database")
        }
    }

    func loadPlaylistItems(_ playlistId: String) {
        isLoadingPlaylists = true
        playlistError = nil

        playlistItems = dbService.getPlaylistItems(playlistId)
        isLoadingPlaylists = false
    }

    func addToPlaylist(playlistId: String, itemId: String, type: String, broadcastId: String? = nil, programId: String? = nil) {
        playlistError = nil

        // Check if item already exists in playlist
        if dbService.isItemInPlaylist(playlistId, itemId) {
            playlistError = "Item already in playlist"
            return
        }

        if dbService.addItemToPlaylist(playlistId: playlistId, itemId: itemId, itemType: type, broadcastId: broadcastId, programId: programId) {
            // Update playlist item count
            if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
                let newCount = playlists[index].itemCount + 1
                playlists[index] = Playlist(
                    id: playlists[index].id,
                    name: playlists[index].name,
                    description: playlists[index].description,
                    createdAt: playlists[index].createdAt,
                    itemCount: newCount
                )
            }
            // Reload items if this is the selected playlist
            if selectedPlaylist?.id == playlistId {
                loadPlaylistItems(playlistId)
            }
        } else {
            playlistError = "Failed to add item to playlist"
            print("Error: Could not add item to playlist")
        }
    }

    func addBroadcastToPlaylist(playlistId: String, broadcast: NPOBroadcast, program: NPOProgram) {
        addToPlaylist(playlistId: playlistId, itemId: broadcast.id, type: "npo_broadcast", broadcastId: broadcast.id, programId: program.id)
    }

    func addProgramToPlaylist(playlistId: String, program: NPOProgram) {
        addToPlaylist(playlistId: playlistId, itemId: program.id, type: "npo_program", programId: program.id)
    }

    func removeFromPlaylist(_ playlistId: String, _ itemId: String) {
        playlistError = nil

        if dbService.removeItemFromPlaylist(playlistId, itemId) {
            playlistItems.removeAll { $0.itemId == itemId }
            // Update playlist item count
            if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
                let newCount = max(0, playlists[index].itemCount - 1)
                playlists[index] = Playlist(
                    id: playlists[index].id,
                    name: playlists[index].name,
                    description: playlists[index].description,
                    createdAt: playlists[index].createdAt,
                    itemCount: newCount
                )
            }
        } else {
            playlistError = "Failed to remove item from playlist"
            print("Error: Could not remove item from playlist")
        }
    }

    // MARK: - Markers

    func loadMarkers(forBroadcast broadcastId: String) {
        isLoadingMarkers = true
        markerError = nil

        markers = dbService.getMarkersByBroadcast(broadcastId)
        isLoadingMarkers = false
    }

    func createMarker(broadcastId: String, timestamp: Int, tags: [String]) {
        markerError = nil

        guard !tags.isEmpty else {
            markerError = "Please add at least one tag to the marker"
            return
        }

        if let marker = dbService.createMarker(broadcastId: broadcastId, timestamp: timestamp, tags: tags) {
            markers.append(marker)
        } else {
            markerError = "Failed to create marker"
            print("Error: Could not create marker in database")
        }
    }

    func deleteMarker(_ markerId: String) {
        markerError = nil

        if dbService.deleteMarker(markerId) {
            markers.removeAll { $0.id == markerId }
        } else {
            markerError = "Failed to delete marker"
            print("Error: Could not delete marker from database")
        }
    }

    // MARK: - Favorites

    func loadFavorites() {
        isLoadingFavorites = true
        favoriteError = nil

        do {
            favorites = dbService.getAllFavorites()
            isFavoritedBroadcasts = Set(favorites.map { $0.broadcastId })
            isLoadingFavorites = false
        } catch {
            favoriteError = "Failed to load favorites"
            isLoadingFavorites = false
            print("Error loading favorites: \(error.localizedDescription)")
        }
    }

    func toggleFavorite(broadcastId: String, itemType: String? = nil, programId: String? = nil) {
        favoriteError = nil

        if isFavoritedBroadcasts.contains(broadcastId) {
            // Remove from favorites
            if dbService.removeFavorite(broadcastId) {
                isFavoritedBroadcasts.remove(broadcastId)
                favorites.removeAll { $0.broadcastId == broadcastId }
            } else {
                favoriteError = "Failed to remove from favorites"
                print("Error: Could not remove favorite from database")
            }
        } else {
            // Add to favorites
            if let favorite = dbService.addFavorite(broadcastId: broadcastId, itemType: itemType, programId: programId) {
                isFavoritedBroadcasts.insert(broadcastId)
                favorites.append(favorite)
            } else {
                favoriteError = "Failed to add to favorites"
                print("Error: Could not add favorite to database")
            }
        }
    }

    func isBroadcastFavorited(_ broadcastId: String) -> Bool {
        return isFavoritedBroadcasts.contains(broadcastId)
    }
}
