import Foundation
import SQLite3

class DatabaseService {
    static let shared = DatabaseService()

    private var db: OpaquePointer?

    private let dbPath: String = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.appendingPathComponent("transistor.db").path
    }()

    init() {
        self.createDatabase()
    }

    // MARK: - Database Setup

    private func createDatabase() {
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            createTables()
        } else {
            print("Error opening database")
        }
    }

    private func createTables() {
        let createChannelsTable = """
        CREATE TABLE IF NOT EXISTS npo_channels (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            imageURL TEXT,
            streamURL TEXT
        );
        """

        let createProgramsTable = """
        CREATE TABLE IF NOT EXISTS npo_programs (
            id TEXT PRIMARY KEY,
            channelId TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            imageURL TEXT,
            presenters TEXT,
            genres TEXT,
            FOREIGN KEY (channelId) REFERENCES npo_channels(id)
        );
        """

        let createBroadcastsTable = """
        CREATE TABLE IF NOT EXISTS npo_broadcasts (
            id TEXT PRIMARY KEY,
            programId TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            startTime INTEGER NOT NULL,
            endTime INTEGER,
            duration INTEGER,
            audioURL TEXT,
            imageURL TEXT,
            broadcasterName TEXT,
            presenters TEXT,
            guests TEXT,
            topics TEXT,
            musicPlayed TEXT,
            isFavorite INTEGER DEFAULT 0,
            FOREIGN KEY (programId) REFERENCES npo_programs(id)
        );
        """

        let createItemsTable = """
        CREATE TABLE IF NOT EXISTS npo_items (
            id TEXT PRIMARY KEY,
            broadcastId TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            type TEXT NOT NULL,
            startTime INTEGER NOT NULL,
            duration INTEGER NOT NULL,
            guests TEXT,
            topics TEXT,
            artist TEXT,
            musicTitle TEXT,
            imageURL TEXT,
            teaserText TEXT,
            FOREIGN KEY (broadcastId) REFERENCES npo_broadcasts(id)
        );
        """

        let createFeedsTable = """
        CREATE TABLE IF NOT EXISTS podcast_feeds (
            id TEXT PRIMARY KEY,
            url TEXT UNIQUE NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            imageURL TEXT,
            author TEXT,
            category TEXT,
            createdAt INTEGER NOT NULL,
            lastFetched INTEGER NOT NULL
        );
        """

        let createEpisodesTable = """
        CREATE TABLE IF NOT EXISTS podcast_episodes (
            id TEXT PRIMARY KEY,
            feedId TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            content TEXT,
            audioURL TEXT NOT NULL,
            imageURL TEXT,
            duration INTEGER,
            pubDate INTEGER NOT NULL,
            guid TEXT UNIQUE NOT NULL,
            guests TEXT,
            tags TEXT,
            explicit INTEGER DEFAULT 0,
            FOREIGN KEY (feedId) REFERENCES podcast_feeds(id)
        );
        """

        let createFavoritesTable = """
        CREATE TABLE IF NOT EXISTS favorites (
            id TEXT PRIMARY KEY,
            broadcastId TEXT NOT NULL,
            addedAt INTEGER NOT NULL,
            FOREIGN KEY (broadcastId) REFERENCES npo_broadcasts(id)
        );
        """

        let createSubscriptionsTable = """
        CREATE TABLE IF NOT EXISTS subscriptions (
            feedId TEXT PRIMARY KEY,
            subscribedAt INTEGER NOT NULL,
            lastEpisodeRead INTEGER,
            FOREIGN KEY (feedId) REFERENCES podcast_feeds(id)
        );
        """

        executeSQL(createChannelsTable)
        executeSQL(createProgramsTable)
        executeSQL(createBroadcastsTable)
        executeSQL(createItemsTable)
        executeSQL(createFeedsTable)
        executeSQL(createEpisodesTable)
        executeSQL(createFavoritesTable)
        executeSQL(createSubscriptionsTable)
    }

    private func executeSQL(_ sql: String) {
        var errorMessage: UnsafeMutablePointer<CChar>?

        if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
            print("SQL Error: \(String(cString: errorMessage ?? "Unknown error" as CChar))")
            sqlite3_free(errorMessage)
        }
    }

    // MARK: - Channel Operations

    func saveChannel(_ channel: NPOChannel) {
        let sql = """
        INSERT OR REPLACE INTO npo_channels (id, name, description, imageURL, streamURL)
        VALUES (?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, channel.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, channel.name, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, channel.description, -1, SQLITE_TRANSIENT)
            if let imageURL = channel.imageURL?.absoluteString {
                sqlite3_bind_text(statement, 4, imageURL, -1, SQLITE_TRANSIENT)
            }
            if let streamURL = channel.streamURL?.absoluteString {
                sqlite3_bind_text(statement, 5, streamURL, -1, SQLITE_TRANSIENT)
            }

            sqlite3_step(statement)
            sqlite3_finalize(statement)
        }
    }

    func getAllChannels() -> [NPOChannel] {
        let sql = "SELECT * FROM npo_channels ORDER BY name;"
        var channels: [NPOChannel] = []
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let description = String(cString: sqlite3_column_text(statement, 2))
                let imageURLString = String(cString: sqlite3_column_text(statement, 3))
                let streamURLString = String(cString: sqlite3_column_text(statement, 4))

                let channel = NPOChannel(
                    id: id,
                    name: name,
                    description: description,
                    imageURL: URL(string: imageURLString),
                    streamURL: URL(string: streamURLString)
                )
                channels.append(channel)
            }
            sqlite3_finalize(statement)
        }

        return channels
    }

    // MARK: - Broadcast Operations

    func saveBroadcast(_ broadcast: NPOBroadcast) {
        let sql = """
        INSERT OR REPLACE INTO npo_broadcasts
        (id, programId, title, description, startTime, endTime, duration, audioURL, imageURL, broadcasterName, presenters, guests, topics, musicPlayed)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, broadcast.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, broadcast.programId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, broadcast.title, -1, SQLITE_TRANSIENT)
            if let description = broadcast.description {
                sqlite3_bind_text(statement, 4, description, -1, SQLITE_TRANSIENT)
            }
            sqlite3_bind_int64(statement, 5, Int64(broadcast.startTime.timeIntervalSince1970))
            if let endTime = broadcast.endTime {
                sqlite3_bind_int64(statement, 6, Int64(endTime.timeIntervalSince1970))
            }
            sqlite3_bind_int(statement, 7, Int32(broadcast.duration))
            if let audioURL = broadcast.audioURL?.absoluteString {
                sqlite3_bind_text(statement, 8, audioURL, -1, SQLITE_TRANSIENT)
            }
            if let imageURL = broadcast.imageURL?.absoluteString {
                sqlite3_bind_text(statement, 9, imageURL, -1, SQLITE_TRANSIENT)
            }
            sqlite3_bind_text(statement, 10, broadcast.broadcasterName, -1, SQLITE_TRANSIENT)

            // JSON encode presenters, guests, topics, music
            if let presentersJSON = try? JSONEncoder().encode(broadcast.presenters),
               let presentersString = String(data: presentersJSON, encoding: .utf8) {
                sqlite3_bind_text(statement, 11, presentersString, -1, SQLITE_TRANSIENT)
            }

            if let guestsJSON = try? JSONEncoder().encode(broadcast.guests),
               let guestsString = String(data: guestsJSON, encoding: .utf8) {
                sqlite3_bind_text(statement, 12, guestsString, -1, SQLITE_TRANSIENT)
            }

            let topicsJSON = try? JSONEncoder().encode(broadcast.topics)
            if let topicsString = topicsJSON.flatMap({ String(data: $0, encoding: .utf8) }) {
                sqlite3_bind_text(statement, 13, topicsString, -1, SQLITE_TRANSIENT)
            }

            if let musicJSON = try? JSONEncoder().encode(broadcast.musicPlayed),
               let musicString = String(data: musicJSON, encoding: .utf8) {
                sqlite3_bind_text(statement, 14, musicString, -1, SQLITE_TRANSIENT)
            }

            sqlite3_step(statement)
            sqlite3_finalize(statement)
        }
    }

    func getBroadcastsByProgram(_ programId: String) -> [NPOBroadcast] {
        let sql = "SELECT * FROM npo_broadcasts WHERE programId = ? ORDER BY startTime DESC;"
        var broadcasts: [NPOBroadcast] = []
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, programId, -1, SQLITE_TRANSIENT)

            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let programId = String(cString: sqlite3_column_text(statement, 1))
                let title = String(cString: sqlite3_column_text(statement, 2))
                let description = String(cString: sqlite3_column_text(statement, 3) ?? "".cString(using: .utf8)?.first)
                let startTime = Date(timeIntervalSince1970: TimeInterval(sqlite3_column_int64(statement, 4)))
                let duration = Int(sqlite3_column_int(statement, 6))
                let broadcasterName = String(cString: sqlite3_column_text(statement, 9))

                let broadcast = NPOBroadcast(
                    id: id,
                    programId: programId,
                    title: title,
                    description: description.map { String(cString: $0) },
                    startTime: startTime,
                    endTime: nil,
                    duration: duration,
                    audioURL: nil,
                    imageURL: nil,
                    broadcasterName: broadcasterName,
                    presenters: [],
                    guests: [],
                    topics: []
                )
                broadcasts.append(broadcast)
            }
            sqlite3_finalize(statement)
        }

        return broadcasts
    }

    // MARK: - Item Operations

    func saveItem(_ item: NPOItem) {
        let sql = """
        INSERT OR REPLACE INTO npo_items
        (id, broadcastId, title, description, type, startTime, duration, guests, topics, artist, musicTitle, imageURL, teaserText)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, item.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, item.broadcastId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, item.title, -1, SQLITE_TRANSIENT)
            if let description = item.description {
                sqlite3_bind_text(statement, 4, description, -1, SQLITE_TRANSIENT)
            }
            sqlite3_bind_text(statement, 5, item.type.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 6, Int32(item.startTime))
            sqlite3_bind_int(statement, 7, Int32(item.duration))

            if let guests = item.guests, let guestsJSON = try? JSONEncoder().encode(guests),
               let guestsString = String(data: guestsJSON, encoding: .utf8) {
                sqlite3_bind_text(statement, 8, guestsString, -1, SQLITE_TRANSIENT)
            }

            if let topics = item.topics, let topicsJSON = try? JSONEncoder().encode(topics),
               let topicsString = String(data: topicsJSON, encoding: .utf8) {
                sqlite3_bind_text(statement, 9, topicsString, -1, SQLITE_TRANSIENT)
            }

            if let artist = item.artist {
                sqlite3_bind_text(statement, 10, artist, -1, SQLITE_TRANSIENT)
            }

            if let musicTitle = item.musicTitle {
                sqlite3_bind_text(statement, 11, musicTitle, -1, SQLITE_TRANSIENT)
            }

            if let imageURL = item.imageURL?.absoluteString {
                sqlite3_bind_text(statement, 12, imageURL, -1, SQLITE_TRANSIENT)
            }

            if let teaserText = item.teaserText {
                sqlite3_bind_text(statement, 13, teaserText, -1, SQLITE_TRANSIENT)
            }

            sqlite3_step(statement)
            sqlite3_finalize(statement)
        }
    }

    func getItemsByBroadcast(_ broadcastId: String) -> [NPOItem] {
        let sql = "SELECT * FROM npo_items WHERE broadcastId = ? ORDER BY startTime;"
        var items: [NPOItem] = []
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, broadcastId, -1, SQLITE_TRANSIENT)

            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let broadcastId = String(cString: sqlite3_column_text(statement, 1))
                let title = String(cString: sqlite3_column_text(statement, 2))
                let description = String(cString: sqlite3_column_text(statement, 3) ?? "".cString(using: .utf8)?.first)
                let typeString = String(cString: sqlite3_column_text(statement, 4))
                let type = NPOItem.ItemType(rawValue: typeString) ?? .segment
                let startTime = Int(sqlite3_column_int(statement, 5))
                let duration = Int(sqlite3_column_int(statement, 6))

                let item = NPOItem(
                    id: id,
                    broadcastId: broadcastId,
                    title: title,
                    description: description.map { String(cString: $0) },
                    type: type,
                    startTime: startTime,
                    duration: duration,
                    guests: nil,
                    topics: nil,
                    artist: nil,
                    musicTitle: nil,
                    imageURL: nil,
                    teaserText: nil
                )
                items.append(item)
            }
            sqlite3_finalize(statement)
        }

        return items
    }

    deinit {
        sqlite3_close(db)
    }
}
