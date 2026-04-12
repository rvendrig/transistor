import * as SQLite from 'expo-sqlite';
import { NPOProgram, NPOBroadcast, NPOChannel } from '@/types/npo';
import { v4 as uuidv4 } from 'uuid';

let db: any = null;

export async function initNPODatabase() {
  try {
    db = await SQLite.openDatabaseAsync('transistor.db');
    await db.execAsync(`
      CREATE TABLE IF NOT EXISTS npo_channels (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        image TEXT,
        url TEXT,
        streamUrl TEXT
      );

      CREATE TABLE IF NOT EXISTS npo_programs (
        id TEXT PRIMARY KEY,
        channelId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        image TEXT,
        presenters TEXT,
        genre TEXT,
        schedule TEXT,
        FOREIGN KEY (channelId) REFERENCES npo_channels(id)
      );

      CREATE TABLE IF NOT EXISTS npo_broadcasts (
        id TEXT PRIMARY KEY,
        programId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        startTime INTEGER NOT NULL,
        endTime INTEGER,
        duration INTEGER,
        audioUrl TEXT,
        image TEXT,
        broadcasterName TEXT,
        presenters TEXT,
        guests TEXT,
        topics TEXT,
        musicPlayed TEXT,
        savedAt INTEGER,
        FOREIGN KEY (programId) REFERENCES npo_programs(id)
      );

      CREATE TABLE IF NOT EXISTS npo_favorites (
        id TEXT PRIMARY KEY,
        broadcastId TEXT NOT NULL,
        addedAt INTEGER NOT NULL,
        FOREIGN KEY (broadcastId) REFERENCES npo_broadcasts(id)
      );

      CREATE INDEX IF NOT EXISTS idx_npo_programs_channelId ON npo_programs(channelId);
      CREATE INDEX IF NOT EXISTS idx_npo_broadcasts_programId ON npo_broadcasts(programId);
      CREATE INDEX IF NOT EXISTS idx_npo_broadcasts_startTime ON npo_broadcasts(startTime);
    `);
    console.log('NPO database initialized successfully');
  } catch (error) {
    console.error('Failed to initialize NPO database:', error);
    throw error;
  }
}

// Channel operations
export async function saveChannel(channel: NPOChannel): Promise<void> {
  try {
    await db.runAsync(
      `INSERT OR REPLACE INTO npo_channels (id, name, description, image, url, streamUrl)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [channel.id, channel.name, channel.description, channel.image, channel.url, channel.streamUrl]
    );
  } catch (error) {
    console.error('Error saving channel:', error);
    throw error;
  }
}

export async function getChannels(): Promise<NPOChannel[]> {
  try {
    const results = await db.getAllAsync('SELECT * FROM npo_channels ORDER BY name');
    return results;
  } catch (error) {
    console.error('Error getting channels:', error);
    throw error;
  }
}

// Program operations
export async function saveProgram(program: NPOProgram, channelId: string): Promise<void> {
  try {
    await db.runAsync(
      `INSERT OR REPLACE INTO npo_programs (id, channelId, title, description, image, presenters, genre, schedule)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        program.id,
        channelId,
        program.title,
        program.description,
        program.image,
        JSON.stringify(program.presenters || []),
        JSON.stringify(program.genre || []),
        JSON.stringify(program.schedule || {}),
      ]
    );
  } catch (error) {
    console.error('Error saving program:', error);
    throw error;
  }
}

export async function getProgramsByChannel(channelId: string): Promise<NPOProgram[]> {
  try {
    const results = await db.getAllAsync(
      'SELECT * FROM npo_programs WHERE channelId = ? ORDER BY title',
      [channelId]
    );
    return results.map(dbRowToProgram);
  } catch (error) {
    console.error('Error getting programs:', error);
    throw error;
  }
}

export async function getProgram(id: string): Promise<NPOProgram | null> {
  try {
    const result = await db.getFirstAsync(
      'SELECT * FROM npo_programs WHERE id = ?',
      [id]
    );
    return result ? dbRowToProgram(result) : null;
  } catch (error) {
    console.error('Error getting program:', error);
    throw error;
  }
}

// Broadcast operations
export async function saveBroadcast(broadcast: NPOBroadcast): Promise<void> {
  try {
    await db.runAsync(
      `INSERT OR REPLACE INTO npo_broadcasts
       (id, programId, title, description, startTime, endTime, duration, audioUrl, image, broadcasterName, presenters, guests, topics, musicPlayed, savedAt)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        broadcast.id,
        broadcast.programId,
        broadcast.title,
        broadcast.description,
        broadcast.startTime.getTime(),
        broadcast.endTime?.getTime() || null,
        broadcast.duration,
        broadcast.audioUrl || null,
        broadcast.image || null,
        broadcast.broadcaster.name,
        JSON.stringify(broadcast.presenters || []),
        JSON.stringify(broadcast.guests || []),
        JSON.stringify(broadcast.topics || []),
        JSON.stringify(broadcast.musicPlayed || []),
        new Date().getTime(),
      ]
    );
  } catch (error) {
    console.error('Error saving broadcast:', error);
    throw error;
  }
}

export async function getBroadcastsByProgram(
  programId: string,
  limit: number = 50
): Promise<NPOBroadcast[]> {
  try {
    const results = await db.getAllAsync(
      'SELECT * FROM npo_broadcasts WHERE programId = ? ORDER BY startTime DESC LIMIT ?',
      [programId, limit]
    );
    return results.map(dbRowToBroadcast);
  } catch (error) {
    console.error('Error getting broadcasts:', error);
    throw error;
  }
}

export async function getRecentBroadcasts(limit: number = 100): Promise<NPOBroadcast[]> {
  try {
    const results = await db.getAllAsync(
      'SELECT * FROM npo_broadcasts ORDER BY startTime DESC LIMIT ?',
      [limit]
    );
    return results.map(dbRowToBroadcast);
  } catch (error) {
    console.error('Error getting recent broadcasts:', error);
    throw error;
  }
}

export async function searchBroadcasts(query: string): Promise<NPOBroadcast[]> {
  try {
    const searchTerm = `%${query}%`;
    const results = await db.getAllAsync(
      `SELECT * FROM npo_broadcasts
       WHERE title LIKE ? OR description LIKE ? OR topics LIKE ? OR presenters LIKE ?
       ORDER BY startTime DESC`,
      [searchTerm, searchTerm, searchTerm, searchTerm]
    );
    return results.map(dbRowToBroadcast);
  } catch (error) {
    console.error('Error searching broadcasts:', error);
    throw error;
  }
}

// Favorites
export async function addFavorite(broadcastId: string): Promise<void> {
  try {
    const id = uuidv4();
    await db.runAsync(
      'INSERT OR IGNORE INTO npo_favorites (id, broadcastId, addedAt) VALUES (?, ?, ?)',
      [id, broadcastId, new Date().getTime()]
    );
  } catch (error) {
    console.error('Error adding favorite:', error);
    throw error;
  }
}

export async function removeFavorite(broadcastId: string): Promise<void> {
  try {
    await db.runAsync(
      'DELETE FROM npo_favorites WHERE broadcastId = ?',
      [broadcastId]
    );
  } catch (error) {
    console.error('Error removing favorite:', error);
    throw error;
  }
}

export async function getFavorites(): Promise<NPOBroadcast[]> {
  try {
    const results = await db.getAllAsync(`
      SELECT nb.* FROM npo_broadcasts nb
      INNER JOIN npo_favorites nf ON nb.id = nf.broadcastId
      ORDER BY nf.addedAt DESC
    `);
    return results.map(dbRowToBroadcast);
  } catch (error) {
    console.error('Error getting favorites:', error);
    throw error;
  }
}

export async function isFavorite(broadcastId: string): Promise<boolean> {
  try {
    const result = await db.getFirstAsync(
      'SELECT id FROM npo_favorites WHERE broadcastId = ?',
      [broadcastId]
    );
    return !!result;
  } catch (error) {
    console.error('Error checking favorite:', error);
    return false;
  }
}

// Helper functions
function dbRowToProgram(row: any): NPOProgram {
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    image: row.image,
    broadcaster: {
      id: row.channelId,
      name: row.channelId.toUpperCase(),
    },
    presenters: row.presenters ? JSON.parse(row.presenters) : [],
    genre: row.genre ? JSON.parse(row.genre) : [],
    schedule: row.schedule ? JSON.parse(row.schedule) : undefined,
  };
}

function dbRowToBroadcast(row: any): NPOBroadcast {
  return {
    id: row.id,
    programId: row.programId,
    title: row.title,
    description: row.description,
    startTime: new Date(row.startTime),
    endTime: row.endTime ? new Date(row.endTime) : undefined,
    duration: row.duration,
    audioUrl: row.audioUrl,
    image: row.image,
    broadcaster: {
      id: 'npo',
      name: row.broadcasterName || 'NPO',
    },
    presenters: row.presenters ? JSON.parse(row.presenters) : [],
    guests: row.guests ? JSON.parse(row.guests) : [],
    topics: row.topics ? JSON.parse(row.topics) : [],
    musicPlayed: row.musicPlayed ? JSON.parse(row.musicPlayed) : [],
  };
}
