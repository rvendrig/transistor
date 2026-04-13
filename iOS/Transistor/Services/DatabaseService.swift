import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class DatabaseService {
    static let shared = DatabaseService()

    private let dbPath: String
    private var db: OpaquePointer?

    private init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        dbPath = documentsDirectory.appendingPathComponent("transistor.db").path

        openDatabase()
        createTables()
        migrateSchema()
    }

    // MARK: - Database Setup

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }

    private func createTables() {
        let createNetworksTable = """
        CREATE TABLE IF NOT EXISTS networks (
            id TEXT PRIMARY KEY,
            provider_id TEXT NOT NULL,
            titles TEXT,
            description TEXT,
            logo TEXT
        )
        """

        let createChannelsTable = """
        CREATE TABLE IF NOT EXISTS channels (
            id TEXT PRIMARY KEY,
            provider_id TEXT NOT NULL,
            network_id TEXT,
            titles TEXT,
            description TEXT,
            logo_url TEXT
        )
        """

        let createShowsTable = """
        CREATE TABLE IF NOT EXISTS shows (
            id TEXT PRIMARY KEY,
            provider_id TEXT NOT NULL,
            titles TEXT,
            description TEXT,
            presenters TEXT,
            image TEXT,
            genre TEXT,
            channel_ids TEXT
        )
        """

        let createSeasonsTable = """
        CREATE TABLE IF NOT EXISTS seasons (
            id TEXT PRIMARY KEY,
            provider_id TEXT NOT NULL,
            show_id TEXT,
            titles TEXT,
            season_number INTEGER,
            description TEXT
        )
        """

        let createBroadcastsTable = """
        CREATE TABLE IF NOT EXISTS broadcasts (
            id TEXT PRIMARY KEY,
            provider_id TEXT NOT NULL,
            title TEXT NOT NULL,
            show_id TEXT,
            channel_id TEXT,
            season_id TEXT,
            start_time TEXT NOT NULL,
            duration INTEGER,
            description TEXT,
            image TEXT,
            audio_url TEXT,
            title_override TEXT,
            detail_url TEXT
        )
        """

        let createSegmentsTable = """
        CREATE TABLE IF NOT EXISTS segments (
            id TEXT PRIMARY KEY,
            provider_id TEXT NOT NULL,
            parent_id TEXT NOT NULL,
            parent_type TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            segment_type TEXT,
            duration INTEGER,
            persons TEXT,
            topics TEXT,
            start_offset INTEGER,
            image TEXT
        )
        """

        let createClipsTable = """
        CREATE TABLE IF NOT EXISTS clips (
            id TEXT PRIMARY KEY,
            provider_id TEXT NOT NULL,
            source_id TEXT,
            source_type TEXT,
            title TEXT,
            description TEXT,
            start_offset INTEGER,
            duration INTEGER,
            audio_url TEXT
        )
        """

        let createPodcastFeedsTable = """
        CREATE TABLE IF NOT EXISTS podcast_feeds (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            feed_url TEXT NOT NULL,
            image TEXT
        )
        """

        let createPodcastEpisodesTable = """
        CREATE TABLE IF NOT EXISTS podcast_episodes (
            id TEXT PRIMARY KEY,
            feed_id TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            pub_date TEXT,
            duration INTEGER,
            audio_url TEXT,
            image TEXT,
            FOREIGN KEY(feed_id) REFERENCES podcast_feeds(id)
        )
        """

        let createSubscriptionsTable = """
        CREATE TABLE IF NOT EXISTS subscriptions (
            id TEXT PRIMARY KEY,
            program_id TEXT NOT NULL,
            subscribed_at TEXT,
            FOREIGN KEY(program_id) REFERENCES shows(id)
        )
        """

        let createPlaylistsTable = """
        CREATE TABLE IF NOT EXISTS playlists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            created_at TEXT NOT NULL,
            item_count INTEGER DEFAULT 0
        )
        """

        let createPlaylistItemsTable = """
        CREATE TABLE IF NOT EXISTS playlist_items (
            id TEXT PRIMARY KEY,
            playlist_id TEXT NOT NULL,
            item_id TEXT NOT NULL,
            item_type TEXT NOT NULL,
            show_id TEXT,
            provider_id TEXT,
            position INTEGER NOT NULL,
            added_at TEXT NOT NULL,
            FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
            UNIQUE(playlist_id, item_id)
        )
        """

        let createPlaylistItemsIndices = """
        CREATE INDEX IF NOT EXISTS idx_playlist_items_playlist_id
        ON playlist_items(playlist_id)
        """

        let createMarkersTable = """
        CREATE TABLE IF NOT EXISTS markers (
            id TEXT PRIMARY KEY,
            content_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            provider_id TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            tags TEXT,
            created_at TEXT NOT NULL
        )
        """

        let createMarkersIndices = """
        CREATE INDEX IF NOT EXISTS idx_markers_content_id
        ON markers(content_id)
        """

        let createFavoritesTable = """
        CREATE TABLE IF NOT EXISTS favorites (
            id TEXT PRIMARY KEY,
            content_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            provider_id TEXT NOT NULL,
            added_at TEXT NOT NULL,
            UNIQUE(content_id)
        )
        """

        let createFavoritesIndices = """
        CREATE INDEX IF NOT EXISTS idx_favorites_content_id
        ON favorites(content_id)
        """

        let createListeningSessionsTable = """
        CREATE TABLE IF NOT EXISTS listening_sessions (
            id TEXT PRIMARY KEY,
            content_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            provider_id TEXT NOT NULL,
            title TEXT NOT NULL,
            source TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT,
            duration INTEGER NOT NULL,
            progress INTEGER DEFAULT 0,
            categories TEXT,
            topics TEXT,
            guests TEXT,
            artists TEXT,
            notes TEXT,
            is_favorited INTEGER DEFAULT 0,
            marker_count INTEGER DEFAULT 0
        )
        """

        let createListeningSessionsIndices = """
        CREATE INDEX IF NOT EXISTS idx_listening_sessions_content_id
        ON listening_sessions(content_id)
        """

        let createListeningSessionsDateIndices = """
        CREATE INDEX IF NOT EXISTS idx_listening_sessions_start_time
        ON listening_sessions(start_time)
        """

        for createTableSQL in [
            createNetworksTable,
            createChannelsTable,
            createShowsTable,
            createSeasonsTable,
            createBroadcastsTable,
            createSegmentsTable,
            createClipsTable,
            createPodcastFeedsTable,
            createPodcastEpisodesTable,
            createSubscriptionsTable,
            createPlaylistsTable,
            createPlaylistItemsTable,
            createPlaylistItemsIndices,
            createMarkersTable,
            createMarkersIndices,
            createFavoritesTable,
            createFavoritesIndices,
            createListeningSessionsTable,
            createListeningSessionsIndices,
            createListeningSessionsDateIndices
        ] {
            var errorMessage: UnsafeMutablePointer<Int8>?
            if sqlite3_exec(db, createTableSQL, nil, nil, &errorMessage) != SQLITE_OK {
                if let error = errorMessage {
                    print("Error creating table: \(String(cString: error))")
                    sqlite3_free(error)
                }
            }
        }
    }

    private func migrateSchema() {
        // Add detail_url column to broadcasts if it doesn't exist yet
        let alterSQL = "ALTER TABLE broadcasts ADD COLUMN detail_url TEXT"
        // Ignore error if column already exists
        sqlite3_exec(db, alterSQL, nil, nil, nil)
    }

    // MARK: - JSON Helpers

    private func encodeTitles(_ titles: [TitledPeriod]) -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(titles) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func decodeTitles(_ json: String?) -> [TitledPeriod] {
        guard let json = json, let data = json.data(using: .utf8) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([TitledPeriod].self, from: data)) ?? []
    }

    private func encodeStringArray(_ array: [String]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: array) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func decodeStringArray(_ json: String?) -> [String] {
        guard let json = json, let data = json.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String] else { return [] }
        return parsed
    }

    // MARK: - Channel Operations

    func saveChannel(_ channel: Channel) {
        let query = """
        INSERT OR REPLACE INTO channels (id, provider_id, network_id, titles, description, logo_url)
        VALUES (?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, channel.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, channel.providerId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, channel.networkId, -1, SQLITE_TRANSIENT)
            if let titlesJSON = encodeTitles(channel.titles) {
                sqlite3_bind_text(statement, 4, titlesJSON, -1, SQLITE_TRANSIENT)
            }
            sqlite3_bind_text(statement, 5, channel.description, -1, SQLITE_TRANSIENT)
            if let logo = channel.logo {
                sqlite3_bind_text(statement, 6, logo, -1, SQLITE_TRANSIENT)
            }

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving channel")
            }
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Show Operations

    func saveShow(_ show: Show) {
        let query = """
        INSERT OR REPLACE INTO shows (id, provider_id, titles, description, presenters, image, genre, channel_ids)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, show.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, show.providerId, -1, SQLITE_TRANSIENT)
            if let titlesJSON = encodeTitles(show.titles) {
                sqlite3_bind_text(statement, 3, titlesJSON, -1, SQLITE_TRANSIENT)
            }
            sqlite3_bind_text(statement, 4, show.description, -1, SQLITE_TRANSIENT)

            if let presentersJSON = encodeStringArray(show.presenters) {
                sqlite3_bind_text(statement, 5, presentersJSON, -1, SQLITE_TRANSIENT)
            }

            if let image = show.image {
                sqlite3_bind_text(statement, 6, image, -1, SQLITE_TRANSIENT)
            }
            if let genre = show.genre {
                sqlite3_bind_text(statement, 7, genre, -1, SQLITE_TRANSIENT)
            }
            if let channelIds = show.channelIds, let channelIdsJSON = encodeStringArray(channelIds) {
                sqlite3_bind_text(statement, 8, channelIdsJSON, -1, SQLITE_TRANSIENT)
            }

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving show")
            }
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Broadcast Operations

    func saveBroadcast(_ broadcast: Broadcast) {
        let query = """
        INSERT OR REPLACE INTO broadcasts (id, provider_id, title, show_id, channel_id, season_id, start_time, duration, description, image, audio_url, title_override, detail_url)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, broadcast.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, broadcast.providerId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, broadcast.title, -1, SQLITE_TRANSIENT)
            if let showId = broadcast.showId {
                sqlite3_bind_text(statement, 4, showId, -1, SQLITE_TRANSIENT)
            }
            if let channelId = broadcast.channelId {
                sqlite3_bind_text(statement, 5, channelId, -1, SQLITE_TRANSIENT)
            }
            if let seasonId = broadcast.seasonId {
                sqlite3_bind_text(statement, 6, seasonId, -1, SQLITE_TRANSIENT)
            }

            let dateFormatter = ISO8601DateFormatter()
            let dateString = dateFormatter.string(from: broadcast.startTime)
            sqlite3_bind_text(statement, 7, dateString, -1, SQLITE_TRANSIENT)

            sqlite3_bind_int(statement, 8, Int32(broadcast.duration))

            if let description = broadcast.description {
                sqlite3_bind_text(statement, 9, description, -1, SQLITE_TRANSIENT)
            }
            if let image = broadcast.image {
                sqlite3_bind_text(statement, 10, image, -1, SQLITE_TRANSIENT)
            }
            if let audioUrl = broadcast.audioUrl {
                sqlite3_bind_text(statement, 11, audioUrl, -1, SQLITE_TRANSIENT)
            }
            if let titleOverride = broadcast.titleOverride {
                sqlite3_bind_text(statement, 12, titleOverride, -1, SQLITE_TRANSIENT)
            }
            if let detailUrl = broadcast.detailUrl {
                sqlite3_bind_text(statement, 13, detailUrl, -1, SQLITE_TRANSIENT)
            }

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving broadcast")
            }
        }
        sqlite3_finalize(statement)
    }

    /// Convenience wrapper: saves an NPOBroadcast by converting to generic Broadcast
    func saveBroadcast(_ broadcast: NPOBroadcast) {
        let generic = Broadcast(
            id: broadcast.id,
            providerId: "npo",
            title: broadcast.title,
            showId: broadcast.programId,
            channelId: nil,
            seasonId: nil,
            startTime: broadcast.startTime,
            duration: broadcast.duration,
            description: broadcast.description,
            image: broadcast.image,
            audioUrl: broadcast.audioUrl,
            titleOverride: nil,
            detailUrl: nil
        )
        saveBroadcast(generic)
    }

    func getBroadcastsByShow(_ showId: String) -> [Broadcast] {
        var broadcasts: [Broadcast] = []
        let query = "SELECT id, provider_id, title, show_id, channel_id, season_id, start_time, duration, description, image, audio_url, title_override, detail_url FROM broadcasts WHERE show_id = ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, showId, -1, SQLITE_TRANSIENT)

            let dateFormatter = ISO8601DateFormatter()
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let providerId = String(cString: sqlite3_column_text(statement, 1))
                let title = String(cString: sqlite3_column_text(statement, 2))
                let showId = sqlite3_column_text(statement, 3).map { String(cString: $0) }
                let channelId = sqlite3_column_text(statement, 4).map { String(cString: $0) }
                let seasonId = sqlite3_column_text(statement, 5).map { String(cString: $0) }
                let dateString = String(cString: sqlite3_column_text(statement, 6))
                let duration = Int(sqlite3_column_int(statement, 7))
                let description = sqlite3_column_text(statement, 8).map { String(cString: $0) }
                let image = sqlite3_column_text(statement, 9).map { String(cString: $0) }
                let audioUrl = sqlite3_column_text(statement, 10).map { String(cString: $0) }
                let titleOverride = sqlite3_column_text(statement, 11).map { String(cString: $0) }
                let detailUrl = sqlite3_column_text(statement, 12).map { String(cString: $0) }

                if let startTime = dateFormatter.date(from: dateString) {
                    let broadcast = Broadcast(
                        id: id,
                        providerId: providerId,
                        title: title,
                        showId: showId,
                        channelId: channelId,
                        seasonId: seasonId,
                        startTime: startTime,
                        duration: duration,
                        description: description,
                        image: image,
                        audioUrl: audioUrl,
                        titleOverride: titleOverride,
                        detailUrl: detailUrl
                    )
                    broadcasts.append(broadcast)
                }
            }
        }
        sqlite3_finalize(statement)
        return broadcasts
    }

    // MARK: - Segment Operations

    func saveSegment(_ segment: Segment) {
        let query = """
        INSERT OR REPLACE INTO segments (id, provider_id, parent_id, parent_type, title, description, segment_type, duration, persons, topics, start_offset, image)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, segment.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, segment.providerId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, segment.parentId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, segment.parentType.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 5, segment.title, -1, SQLITE_TRANSIENT)
            if let description = segment.description {
                sqlite3_bind_text(statement, 6, description, -1, SQLITE_TRANSIENT)
            }
            sqlite3_bind_text(statement, 7, segment.segmentType.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 8, Int32(segment.duration))

            if let personsJSON = encodeStringArray(segment.persons) {
                sqlite3_bind_text(statement, 9, personsJSON, -1, SQLITE_TRANSIENT)
            }
            if let topicsJSON = encodeStringArray(segment.topics) {
                sqlite3_bind_text(statement, 10, topicsJSON, -1, SQLITE_TRANSIENT)
            }

            sqlite3_bind_int(statement, 11, Int32(segment.startOffset))

            if let image = segment.image {
                sqlite3_bind_text(statement, 12, image, -1, SQLITE_TRANSIENT)
            }

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving segment")
            }
        }
        sqlite3_finalize(statement)
    }

    func getSegmentsByParent(_ parentId: String) -> [Segment] {
        var segments: [Segment] = []
        let query = "SELECT id, provider_id, parent_id, parent_type, title, description, segment_type, duration, persons, topics, start_offset, image FROM segments WHERE parent_id = ? ORDER BY start_offset ASC"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, parentId, -1, SQLITE_TRANSIENT)

            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let providerId = String(cString: sqlite3_column_text(statement, 1))
                let parentId = String(cString: sqlite3_column_text(statement, 2))
                let parentTypeString = String(cString: sqlite3_column_text(statement, 3))
                let parentType = ContentType(rawValue: parentTypeString) ?? .broadcast
                let title = String(cString: sqlite3_column_text(statement, 4))
                let description = sqlite3_column_text(statement, 5).map { String(cString: $0) }
                let segmentTypeString = sqlite3_column_text(statement, 6).map { String(cString: $0) } ?? "other"
                let segmentType = SegmentType(rawValue: segmentTypeString) ?? .other
                let duration = Int(sqlite3_column_int(statement, 7))
                let personsStr = sqlite3_column_text(statement, 8).map { String(cString: $0) }
                let persons = decodeStringArray(personsStr)
                let topicsStr = sqlite3_column_text(statement, 9).map { String(cString: $0) }
                let topics = decodeStringArray(topicsStr)
                let startOffset = Int(sqlite3_column_int(statement, 10))
                let image = sqlite3_column_text(statement, 11).map { String(cString: $0) }

                let segment = Segment(
                    id: id,
                    providerId: providerId,
                    parentId: parentId,
                    parentType: parentType,
                    title: title,
                    description: description,
                    startOffset: startOffset,
                    duration: duration,
                    segmentType: segmentType,
                    persons: persons,
                    topics: topics,
                    image: image
                )
                segments.append(segment)
            }
        }
        sqlite3_finalize(statement)
        return segments
    }

    // MARK: - Playlist Operations

    func createPlaylist(name: String, description: String? = nil) -> Playlist? {
        let id = UUID().uuidString
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.string(from: Date())

        let query = """
        INSERT INTO playlists (id, name, description, created_at, item_count)
        VALUES (?, ?, ?, ?, 0)
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, name, -1, SQLITE_TRANSIENT)
            if let description = description {
                sqlite3_bind_text(statement, 3, description, -1, SQLITE_TRANSIENT)
            }
            sqlite3_bind_text(statement, 4, createdAt, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return Playlist(id: id, name: name, description: description, createdAt: Date(), itemCount: 0)
            }
        }
        sqlite3_finalize(statement)
        return nil
    }

    func getAllPlaylists() -> [Playlist] {
        var playlists: [Playlist] = []
        let query = "SELECT id, name, description, created_at, item_count FROM playlists ORDER BY created_at DESC"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let dateFormatter = ISO8601DateFormatter()
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let description = sqlite3_column_text(statement, 2).map { String(cString: $0) }
                let createdAtString = String(cString: sqlite3_column_text(statement, 3))
                let itemCount = Int(sqlite3_column_int(statement, 4))

                if let createdAt = dateFormatter.date(from: createdAtString) {
                    let playlist = Playlist(id: id, name: name, description: description, createdAt: createdAt, itemCount: itemCount)
                    playlists.append(playlist)
                }
            }
        }
        sqlite3_finalize(statement)
        return playlists
    }

    func updatePlaylistName(_ playlistId: String, newName: String) -> Bool {
        let query = "UPDATE playlists SET name = ? WHERE id = ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, newName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, playlistId, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }

    func deletePlaylist(_ playlistId: String) -> Bool {
        let query = "DELETE FROM playlists WHERE id = ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, playlistId, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }

    func addItemToPlaylist(playlistId: String, itemId: String, itemType: PlaylistItemType, showId: String? = nil, providerId: String? = nil) -> Bool {
        // Get next position
        let maxPosQuery = "SELECT MAX(position) FROM playlist_items WHERE playlist_id = ?"
        var statement: OpaquePointer?
        var nextPosition = 0

        if sqlite3_prepare_v2(db, maxPosQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, playlistId, -1, SQLITE_TRANSIENT)
            if sqlite3_step(statement) == SQLITE_ROW {
                let maxPos = sqlite3_column_int(statement, 0)
                nextPosition = maxPos > 0 ? Int(maxPos) + 1 : 1
            }
        }
        sqlite3_finalize(statement)

        // Insert item
        let id = UUID().uuidString
        let dateFormatter = ISO8601DateFormatter()
        let addedAt = dateFormatter.string(from: Date())

        let query = """
        INSERT INTO playlist_items (id, playlist_id, item_id, item_type, show_id, provider_id, position, added_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, playlistId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, itemId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, itemType.rawValue, -1, SQLITE_TRANSIENT)
            if let showId = showId {
                sqlite3_bind_text(statement, 5, showId, -1, SQLITE_TRANSIENT)
            }
            if let providerId = providerId {
                sqlite3_bind_text(statement, 6, providerId, -1, SQLITE_TRANSIENT)
            }
            sqlite3_bind_int(statement, 7, Int32(nextPosition))
            sqlite3_bind_text(statement, 8, addedAt, -1, SQLITE_TRANSIENT)

            let success = sqlite3_step(statement) == SQLITE_DONE
            sqlite3_finalize(statement)

            if success {
                updatePlaylistItemCount(playlistId)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }

    func getPlaylistItems(_ playlistId: String) -> [PlaylistItem] {
        var items: [PlaylistItem] = []
        let query = """
        SELECT id, playlist_id, item_id, item_type, show_id, provider_id, position, added_at
        FROM playlist_items WHERE playlist_id = ? ORDER BY position ASC
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, playlistId, -1, SQLITE_TRANSIENT)

            let dateFormatter = ISO8601DateFormatter()
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let playlistId = String(cString: sqlite3_column_text(statement, 1))
                let itemId = String(cString: sqlite3_column_text(statement, 2))
                let itemTypeString = String(cString: sqlite3_column_text(statement, 3))
                let itemType = PlaylistItemType(rawValue: itemTypeString) ?? .broadcast
                let showId = sqlite3_column_text(statement, 4).map { String(cString: $0) }
                let providerId = sqlite3_column_text(statement, 5).map { String(cString: $0) }
                let position = Int(sqlite3_column_int(statement, 6))
                let addedAtString = String(cString: sqlite3_column_text(statement, 7))

                if let addedAt = dateFormatter.date(from: addedAtString) {
                    let item = PlaylistItem(id: id, playlistId: playlistId, itemId: itemId, itemType: itemType, contentType: nil, showId: showId, providerId: providerId, position: position, addedAt: addedAt)
                    items.append(item)
                }
            }
        }
        sqlite3_finalize(statement)
        return items
    }

    func removeItemFromPlaylist(_ playlistId: String, _ itemId: String) -> Bool {
        let query = "DELETE FROM playlist_items WHERE playlist_id = ? AND item_id = ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, playlistId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, itemId, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                updatePlaylistItemCount(playlistId)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }

    func isItemInPlaylist(_ playlistId: String, _ itemId: String) -> Bool {
        let query = "SELECT COUNT(*) FROM playlist_items WHERE playlist_id = ? AND item_id = ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, playlistId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, itemId, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_ROW {
                let count = sqlite3_column_int(statement, 0)
                sqlite3_finalize(statement)
                return count > 0
            }
        }
        sqlite3_finalize(statement)
        return false
    }

    private func updatePlaylistItemCount(_ playlistId: String) {
        let countQuery = "SELECT COUNT(*) FROM playlist_items WHERE playlist_id = ?"
        var statement: OpaquePointer?
        var itemCount = 0

        if sqlite3_prepare_v2(db, countQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, playlistId, -1, SQLITE_TRANSIENT)
            if sqlite3_step(statement) == SQLITE_ROW {
                itemCount = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)

        let updateQuery = "UPDATE playlists SET item_count = ? WHERE id = ?"
        if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(itemCount))
            sqlite3_bind_text(statement, 2, playlistId, -1, SQLITE_TRANSIENT)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Marker Operations (Generic - works with any content type)

    func createMarker(contentId: String, contentType: ContentType, providerId: String, timestamp: Int, tags: [String]) -> Marker? {
        let id = UUID().uuidString
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.string(from: Date())

        let tagsJSON = (try? JSONSerialization.data(withJSONObject: tags)) ?? Data()
        let query = """
        INSERT INTO markers (id, content_id, content_type, provider_id, timestamp, tags, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, contentId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, contentType.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, providerId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 5, Int32(timestamp))
            sqlite3_bind_blob(statement, 6, (tagsJSON as NSData).bytes, Int32(tagsJSON.count), SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 7, createdAt, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return Marker(id: id, contentId: contentId, contentType: contentType, providerId: providerId, timestamp: timestamp, tags: tags, createdAt: Date())
            }
        }
        sqlite3_finalize(statement)
        return nil
    }

    func getMarkersByContent(_ contentId: String) -> [Marker] {
        var markers: [Marker] = []
        let query = "SELECT id, content_id, content_type, provider_id, timestamp, tags, created_at FROM markers WHERE content_id = ? ORDER BY timestamp ASC"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, contentId, -1, SQLITE_TRANSIENT)

            let dateFormatter = ISO8601DateFormatter()
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let contentId = String(cString: sqlite3_column_text(statement, 1))
                let contentTypeString = String(cString: sqlite3_column_text(statement, 2))
                let contentType = ContentType(rawValue: contentTypeString) ?? .broadcast
                let providerId = String(cString: sqlite3_column_text(statement, 3))
                let timestamp = Int(sqlite3_column_int(statement, 4))
                let createdAtString = String(cString: sqlite3_column_text(statement, 6))

                var tags: [String] = []
                if let data = sqlite3_column_blob(statement, 5) {
                    let length = sqlite3_column_bytes(statement, 5)
                    let nsData = NSData(bytes: data, length: Int(length))
                    if let parsed = try? JSONSerialization.jsonObject(with: nsData as Data) as? [String] {
                        tags = parsed
                    }
                }

                if let createdAt = dateFormatter.date(from: createdAtString) {
                    let marker = Marker(id: id, contentId: contentId, contentType: contentType, providerId: providerId, timestamp: timestamp, tags: tags, createdAt: createdAt)
                    markers.append(marker)
                }
            }
        }
        sqlite3_finalize(statement)
        return markers
    }

    func deleteMarker(_ markerId: String) -> Bool {
        let query = "DELETE FROM markers WHERE id = ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, markerId, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }

    // MARK: - Favorites Operations (Generic)

    func addFavorite(contentId: String, contentType: ContentType, providerId: String) -> Favorite? {
        let id = UUID().uuidString
        let dateFormatter = ISO8601DateFormatter()
        let addedAt = dateFormatter.string(from: Date())

        let query = """
        INSERT OR REPLACE INTO favorites (id, content_id, content_type, provider_id, added_at)
        VALUES (?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, contentId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, contentType.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, providerId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 5, addedAt, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return Favorite(id: id, contentId: contentId, contentType: contentType, providerId: providerId, addedAt: Date())
            }
        }
        sqlite3_finalize(statement)
        return nil
    }

    func removeFavorite(_ contentId: String) -> Bool {
        let query = "DELETE FROM favorites WHERE content_id = ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, contentId, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }

    func isFavorite(_ contentId: String) -> Bool {
        let query = "SELECT COUNT(*) FROM favorites WHERE content_id = ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, contentId, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_ROW {
                let count = sqlite3_column_int(statement, 0)
                sqlite3_finalize(statement)
                return count > 0
            }
        }
        sqlite3_finalize(statement)
        return false
    }

    func getAllFavorites() -> [Favorite] {
        var favorites: [Favorite] = []
        let query = "SELECT id, content_id, content_type, provider_id, added_at FROM favorites ORDER BY added_at DESC"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let dateFormatter = ISO8601DateFormatter()
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let contentId = String(cString: sqlite3_column_text(statement, 1))
                let contentTypeString = String(cString: sqlite3_column_text(statement, 2))
                let contentType = ContentType(rawValue: contentTypeString) ?? .broadcast
                let providerId = String(cString: sqlite3_column_text(statement, 3))
                let addedAtString = String(cString: sqlite3_column_text(statement, 4))

                if let addedAt = dateFormatter.date(from: addedAtString) {
                    let favorite = Favorite(id: id, contentId: contentId, contentType: contentType, providerId: providerId, addedAt: addedAt)
                    favorites.append(favorite)
                }
            }
        }
        sqlite3_finalize(statement)
        return favorites
    }

    // MARK: - Listening Session Operations

    func createListeningSession(contentId: String, contentType: ContentType, providerId: String, title: String, source: String, duration: Int, categories: [ContentCategory] = [], topics: [String] = [], guests: [String] = [], artists: [String] = []) -> ListeningSession? {
        let id = UUID().uuidString
        let dateFormatter = ISO8601DateFormatter()
        let startTime = dateFormatter.string(from: Date())

        let categoriesJSON = (try? JSONSerialization.data(withJSONObject: categories.map { $0.rawValue })) ?? Data()
        let topicsJSON = (try? JSONSerialization.data(withJSONObject: topics)) ?? Data()
        let guestsJSON = (try? JSONSerialization.data(withJSONObject: guests)) ?? Data()
        let artistsJSON = (try? JSONSerialization.data(withJSONObject: artists)) ?? Data()

        let query = """
        INSERT INTO listening_sessions (id, content_id, content_type, provider_id, title, source, start_time, duration, categories, topics, guests, artists)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, contentId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, contentType.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, providerId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 5, title, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 6, source, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 7, startTime, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 8, Int32(duration))
            sqlite3_bind_blob(statement, 9, (categoriesJSON as NSData).bytes, Int32(categoriesJSON.count), SQLITE_TRANSIENT)
            sqlite3_bind_blob(statement, 10, (topicsJSON as NSData).bytes, Int32(topicsJSON.count), SQLITE_TRANSIENT)
            sqlite3_bind_blob(statement, 11, (guestsJSON as NSData).bytes, Int32(guestsJSON.count), SQLITE_TRANSIENT)
            sqlite3_bind_blob(statement, 12, (artistsJSON as NSData).bytes, Int32(artistsJSON.count), SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return ListeningSession(
                    id: id,
                    contentId: contentId,
                    contentType: contentType,
                    providerId: providerId,
                    title: title,
                    source: source,
                    startTime: Date(),
                    duration: duration,
                    progress: 0,
                    categories: categories,
                    topics: topics,
                    guests: guests,
                    artists: artists,
                    isFavorited: false,
                    markerCount: 0
                )
            }
        }
        sqlite3_finalize(statement)
        return nil
    }

    func updateListeningSessionProgress(_ sessionId: String, progress: Int) -> Bool {
        let query = "UPDATE listening_sessions SET progress = ? WHERE id = ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(progress))
            sqlite3_bind_text(statement, 2, sessionId, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }

    func endListeningSession(_ sessionId: String) -> Bool {
        let dateFormatter = ISO8601DateFormatter()
        let endTime = dateFormatter.string(from: Date())
        let query = "UPDATE listening_sessions SET end_time = ? WHERE id = ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, endTime, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, sessionId, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }

    func getListeningHistory(limit: Int = 50) -> [ListeningSession] {
        var sessions: [ListeningSession] = []
        let query = "SELECT id, content_id, content_type, provider_id, title, source, start_time, end_time, duration, progress, categories, topics, guests, artists, notes, is_favorited, marker_count FROM listening_sessions ORDER BY start_time DESC LIMIT ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(limit))

            let dateFormatter = ISO8601DateFormatter()
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let contentId = String(cString: sqlite3_column_text(statement, 1))
                let contentTypeString = String(cString: sqlite3_column_text(statement, 2))
                let contentType = ContentType(rawValue: contentTypeString) ?? .broadcast
                let providerId = String(cString: sqlite3_column_text(statement, 3))
                let title = String(cString: sqlite3_column_text(statement, 4))
                let source = String(cString: sqlite3_column_text(statement, 5))
                let startTimeString = String(cString: sqlite3_column_text(statement, 6))
                let endTimeString = sqlite3_column_text(statement, 7).map { String(cString: $0) }
                let duration = Int(sqlite3_column_int(statement, 8))
                let progress = Int(sqlite3_column_int(statement, 9))
                let notes = sqlite3_column_text(statement, 14).map { String(cString: $0) }
                let isFavorited = sqlite3_column_int(statement, 15) != 0
                let markerCount = Int(sqlite3_column_int(statement, 16))

                var categories: [ContentCategory] = []
                if let data = sqlite3_column_blob(statement, 10) {
                    let length = sqlite3_column_bytes(statement, 10)
                    let nsData = NSData(bytes: data, length: Int(length))
                    if let parsed = try? JSONSerialization.jsonObject(with: nsData as Data) as? [String] {
                        categories = parsed.compactMap { ContentCategory(rawValue: $0) }
                    }
                }

                var topics: [String] = []
                if let data = sqlite3_column_blob(statement, 11) {
                    let length = sqlite3_column_bytes(statement, 11)
                    let nsData = NSData(bytes: data, length: Int(length))
                    if let parsed = try? JSONSerialization.jsonObject(with: nsData as Data) as? [String] {
                        topics = parsed
                    }
                }

                var guests: [String] = []
                if let data = sqlite3_column_blob(statement, 12) {
                    let length = sqlite3_column_bytes(statement, 12)
                    let nsData = NSData(bytes: data, length: Int(length))
                    if let parsed = try? JSONSerialization.jsonObject(with: nsData as Data) as? [String] {
                        guests = parsed
                    }
                }

                var artists: [String] = []
                if let data = sqlite3_column_blob(statement, 13) {
                    let length = sqlite3_column_bytes(statement, 13)
                    let nsData = NSData(bytes: data, length: Int(length))
                    if let parsed = try? JSONSerialization.jsonObject(with: nsData as Data) as? [String] {
                        artists = parsed
                    }
                }

                if let startTime = dateFormatter.date(from: startTimeString) {
                    let endTime = endTimeString.flatMap { dateFormatter.date(from: $0) }
                    let session = ListeningSession(
                        id: id,
                        contentId: contentId,
                        contentType: contentType,
                        providerId: providerId,
                        title: title,
                        source: source,
                        startTime: startTime,
                        endTime: endTime,
                        duration: duration,
                        progress: progress,
                        categories: categories,
                        topics: topics,
                        guests: guests,
                        artists: artists,
                        notes: notes,
                        isFavorited: isFavorited,
                        markerCount: markerCount
                    )
                    sessions.append(session)
                }
            }
        }
        sqlite3_finalize(statement)
        return sessions
    }

    func getListeningSessionsByCategory(_ category: ContentCategory, limit: Int = 50) -> [ListeningSession] {
        var sessions: [ListeningSession] = []
        let query = "SELECT id, content_id, content_type, provider_id, title, source, start_time, end_time, duration, progress, categories, topics, guests, artists, notes, is_favorited, marker_count FROM listening_sessions WHERE categories LIKE ? ORDER BY start_time DESC LIMIT ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let categoryPattern = "%\(category.rawValue)%"
            sqlite3_bind_text(statement, 1, categoryPattern, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 2, Int32(limit))

            let dateFormatter = ISO8601DateFormatter()
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let contentId = String(cString: sqlite3_column_text(statement, 1))
                let contentTypeString = String(cString: sqlite3_column_text(statement, 2))
                let contentType = ContentType(rawValue: contentTypeString) ?? .broadcast
                let providerId = String(cString: sqlite3_column_text(statement, 3))
                let title = String(cString: sqlite3_column_text(statement, 4))
                let source = String(cString: sqlite3_column_text(statement, 5))
                let startTimeString = String(cString: sqlite3_column_text(statement, 6))
                let endTimeString = sqlite3_column_text(statement, 7).map { String(cString: $0) }
                let duration = Int(sqlite3_column_int(statement, 8))
                let progress = Int(sqlite3_column_int(statement, 9))
                let notes = sqlite3_column_text(statement, 14).map { String(cString: $0) }
                let isFavorited = sqlite3_column_int(statement, 15) != 0
                let markerCount = Int(sqlite3_column_int(statement, 16))

                var categories: [ContentCategory] = []
                if let data = sqlite3_column_blob(statement, 10) {
                    let length = sqlite3_column_bytes(statement, 10)
                    let nsData = NSData(bytes: data, length: Int(length))
                    if let parsed = try? JSONSerialization.jsonObject(with: nsData as Data) as? [String] {
                        categories = parsed.compactMap { ContentCategory(rawValue: $0) }
                    }
                }

                var topics: [String] = []
                if let data = sqlite3_column_blob(statement, 11) {
                    let length = sqlite3_column_bytes(statement, 11)
                    let nsData = NSData(bytes: data, length: Int(length))
                    if let parsed = try? JSONSerialization.jsonObject(with: nsData as Data) as? [String] {
                        topics = parsed
                    }
                }

                var guests: [String] = []
                if let data = sqlite3_column_blob(statement, 12) {
                    let length = sqlite3_column_bytes(statement, 12)
                    let nsData = NSData(bytes: data, length: Int(length))
                    if let parsed = try? JSONSerialization.jsonObject(with: nsData as Data) as? [String] {
                        guests = parsed
                    }
                }

                var artists: [String] = []
                if let data = sqlite3_column_blob(statement, 13) {
                    let length = sqlite3_column_bytes(statement, 13)
                    let nsData = NSData(bytes: data, length: Int(length))
                    if let parsed = try? JSONSerialization.jsonObject(with: nsData as Data) as? [String] {
                        artists = parsed
                    }
                }

                if let startTime = dateFormatter.date(from: startTimeString) {
                    let endTime = endTimeString.flatMap { dateFormatter.date(from: $0) }
                    let session = ListeningSession(
                        id: id,
                        contentId: contentId,
                        contentType: contentType,
                        providerId: providerId,
                        title: title,
                        source: source,
                        startTime: startTime,
                        endTime: endTime,
                        duration: duration,
                        progress: progress,
                        categories: categories,
                        topics: topics,
                        guests: guests,
                        artists: artists,
                        notes: notes,
                        isFavorited: isFavorited,
                        markerCount: markerCount
                    )
                    sessions.append(session)
                }
            }
        }
        sqlite3_finalize(statement)
        return sessions
    }

    func addNoteToListeningSession(_ sessionId: String, note: String) -> Bool {
        let query = "UPDATE listening_sessions SET notes = ? WHERE id = ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, note, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, sessionId, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }

    // MARK: - Deinit

    deinit {
        sqlite3_close(db)
    }
}
