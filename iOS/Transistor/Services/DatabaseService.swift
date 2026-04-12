import Foundation
import SQLite3

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
    }

    // MARK: - Database Setup

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }

    private func createTables() {
        let createChannelsTable = """
        CREATE TABLE IF NOT EXISTS npo_channels (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            logo_url TEXT
        )
        """

        let createProgramsTable = """
        CREATE TABLE IF NOT EXISTS npo_programs (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            presenters TEXT,
            image TEXT,
            genre TEXT,
            channel_id TEXT,
            FOREIGN KEY(channel_id) REFERENCES npo_channels(id)
        )
        """

        let createBroadcastsTable = """
        CREATE TABLE IF NOT EXISTS npo_broadcasts (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            program_id TEXT NOT NULL,
            start_time TEXT NOT NULL,
            duration INTEGER,
            description TEXT,
            image TEXT,
            FOREIGN KEY(program_id) REFERENCES npo_programs(id)
        )
        """

        let createItemsTable = """
        CREATE TABLE IF NOT EXISTS npo_items (
            id TEXT PRIMARY KEY,
            broadcast_id TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            type TEXT,
            duration INTEGER,
            guests TEXT,
            topics TEXT,
            start_offset INTEGER,
            FOREIGN KEY(broadcast_id) REFERENCES npo_broadcasts(id)
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

        let createFavoritesTable = """
        CREATE TABLE IF NOT EXISTS favorites (
            id TEXT PRIMARY KEY,
            item_id TEXT NOT NULL,
            item_type TEXT,
            added_at TEXT
        )
        """

        let createSubscriptionsTable = """
        CREATE TABLE IF NOT EXISTS subscriptions (
            id TEXT PRIMARY KEY,
            program_id TEXT NOT NULL,
            subscribed_at TEXT,
            FOREIGN KEY(program_id) REFERENCES npo_programs(id)
        )
        """

        for createTableSQL in [
            createChannelsTable,
            createProgramsTable,
            createBroadcastsTable,
            createItemsTable,
            createPodcastFeedsTable,
            createPodcastEpisodesTable,
            createFavoritesTable,
            createSubscriptionsTable
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

    // MARK: - Channel Operations

    func saveChannel(_ channel: NPOChannel) {
        let query = """
        INSERT OR REPLACE INTO npo_channels (id, name, description, logo_url)
        VALUES (?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, channel.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, channel.name, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, channel.description, -1, SQLITE_TRANSIENT)
            if let logoURL = channel.logoURL {
                sqlite3_bind_text(statement, 4, logoURL, -1, SQLITE_TRANSIENT)
            }

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving channel")
            }
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Program Operations

    func saveProgram(_ program: NPOProgram) {
        let query = """
        INSERT OR REPLACE INTO npo_programs (id, title, description, presenters, image, genre, channel_id)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, program.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, program.title, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, program.description, -1, SQLITE_TRANSIENT)

            let presentersJSON = try? JSONSerialization.data(withJSONObject: program.presenters)
            if let data = presentersJSON {
                sqlite3_bind_blob(statement, 4, (data as NSData).bytes, Int32(data.count), SQLITE_TRANSIENT)
            }

            if let image = program.image {
                sqlite3_bind_text(statement, 5, image, -1, SQLITE_TRANSIENT)
            }
            if let genre = program.genre {
                sqlite3_bind_text(statement, 6, genre, -1, SQLITE_TRANSIENT)
            }
            if let channelId = program.channelId {
                sqlite3_bind_text(statement, 7, channelId, -1, SQLITE_TRANSIENT)
            }

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving program")
            }
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Broadcast Operations

    func saveBroadcast(_ broadcast: NPOBroadcast) {
        let query = """
        INSERT OR REPLACE INTO npo_broadcasts (id, title, program_id, start_time, duration, description, image)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, broadcast.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, broadcast.title, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, broadcast.programId, -1, SQLITE_TRANSIENT)

            let dateFormatter = ISO8601DateFormatter()
            let dateString = dateFormatter.string(from: broadcast.startTime)
            sqlite3_bind_text(statement, 4, dateString, -1, SQLITE_TRANSIENT)

            sqlite3_bind_int(statement, 5, Int32(broadcast.duration))

            if let description = broadcast.description {
                sqlite3_bind_text(statement, 6, description, -1, SQLITE_TRANSIENT)
            }
            if let image = broadcast.image {
                sqlite3_bind_text(statement, 7, image, -1, SQLITE_TRANSIENT)
            }

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving broadcast")
            }
        }
        sqlite3_finalize(statement)
    }

    func getBroadcastsByProgram(_ programId: String) -> [NPOBroadcast] {
        var broadcasts: [NPOBroadcast] = []
        let query = "SELECT id, title, program_id, start_time, duration, description, image FROM npo_broadcasts WHERE program_id = ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, programId, -1, SQLITE_TRANSIENT)

            let dateFormatter = ISO8601DateFormatter()
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let title = String(cString: sqlite3_column_text(statement, 1))
                let programId = String(cString: sqlite3_column_text(statement, 2))
                let dateString = String(cString: sqlite3_column_text(statement, 3))
                let duration = Int(sqlite3_column_int(statement, 4))
                let description = sqlite3_column_text(statement, 5).map { String(cString: $0) }
                let image = sqlite3_column_text(statement, 6).map { String(cString: $0) }

                if let startTime = dateFormatter.date(from: dateString) {
                    let broadcast = NPOBroadcast(
                        id: id,
                        title: title,
                        programId: programId,
                        startTime: startTime,
                        duration: duration,
                        description: description,
                        image: image
                    )
                    broadcasts.append(broadcast)
                }
            }
        }
        sqlite3_finalize(statement)
        return broadcasts
    }

    // MARK: - Item Operations

    func saveItem(_ item: NPOItem) {
        let query = """
        INSERT OR REPLACE INTO npo_items (id, broadcast_id, title, description, type, duration, guests, topics, start_offset)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, item.id, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, item.broadcastId, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, item.title, -1, SQLITE_TRANSIENT)
            if let description = item.description {
                sqlite3_bind_text(statement, 4, description, -1, SQLITE_TRANSIENT)
            }
            sqlite3_bind_text(statement, 5, item.type.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 6, Int32(item.duration))

            if let guestsJSON = try? JSONSerialization.data(withJSONObject: item.guests) {
                sqlite3_bind_blob(statement, 7, (guestsJSON as NSData).bytes, Int32(guestsJSON.count), SQLITE_TRANSIENT)
            }

            if let topicsJSON = try? JSONSerialization.data(withJSONObject: item.topics) {
                sqlite3_bind_blob(statement, 8, (topicsJSON as NSData).bytes, Int32(topicsJSON.count), SQLITE_TRANSIENT)
            }

            if let startOffset = item.startOffset {
                sqlite3_bind_int(statement, 9, Int32(startOffset))
            }

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving item")
            }
        }
        sqlite3_finalize(statement)
    }

    func getItemsByBroadcast(_ broadcastId: String) -> [NPOItem] {
        var items: [NPOItem] = []
        let query = "SELECT id, broadcast_id, title, description, type, duration, guests, topics, start_offset FROM npo_items WHERE broadcast_id = ?"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, broadcastId, -1, SQLITE_TRANSIENT)

            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let broadcastId = String(cString: sqlite3_column_text(statement, 1))
                let title = String(cString: sqlite3_column_text(statement, 2))
                let description = sqlite3_column_text(statement, 3).map { String(cString: $0) }
                let typeString = String(cString: sqlite3_column_text(statement, 4))
                let type = NPOItem.ItemType(rawValue: typeString) ?? .segment
                let duration = Int(sqlite3_column_int(statement, 5))

                var guests: [String] = []
                if let data = sqlite3_column_blob(statement, 6) {
                    let length = sqlite3_column_bytes(statement, 6)
                    let nsData = NSData(bytes: data, length: Int(length))
                    if let parsed = try? JSONSerialization.jsonObject(with: nsData as Data) as? [String] {
                        guests = parsed
                    }
                }

                var topics: [String] = []
                if let data = sqlite3_column_blob(statement, 7) {
                    let length = sqlite3_column_bytes(statement, 7)
                    let nsData = NSData(bytes: data, length: Int(length))
                    if let parsed = try? JSONSerialization.jsonObject(with: nsData as Data) as? [String] {
                        topics = parsed
                    }
                }

                let startOffset = sqlite3_column_int(statement, 8) > 0 ? Int(sqlite3_column_int(statement, 8)) : nil

                let item = NPOItem(
                    id: id,
                    broadcastId: broadcastId,
                    title: title,
                    description: description,
                    type: type,
                    duration: duration,
                    guests: guests,
                    topics: topics,
                    startOffset: startOffset
                )
                items.append(item)
            }
        }
        sqlite3_finalize(statement)
        return items
    }

    // MARK: - Deinit

    deinit {
        sqlite3_close(db)
    }
}
