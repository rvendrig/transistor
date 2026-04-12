import * as SQLite from 'expo-sqlite';
import { Feed, Episode, Subscription } from '@/types';

const DB_NAME = 'transistor.db';

interface SQLiteDatabase {
  exec(
    sql: string[],
    success?: () => void,
    error?: (err: Error) => void
  ): void;
  transaction(callback: (tx: any) => void): void;
}

let db: any = null;

export async function initDatabase() {
  try {
    db = await SQLite.openDatabaseAsync(DB_NAME);
    await db.execAsync(`
      CREATE TABLE IF NOT EXISTS feeds (
        id TEXT PRIMARY KEY,
        url TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        imageUrl TEXT,
        language TEXT,
        author TEXT,
        category TEXT,
        createdAt INTEGER NOT NULL,
        lastFetched INTEGER NOT NULL
      );

      CREATE TABLE IF NOT EXISTS episodes (
        id TEXT PRIMARY KEY,
        feedId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        content TEXT,
        audioUrl TEXT NOT NULL,
        imageUrl TEXT,
        duration INTEGER,
        pubDate INTEGER NOT NULL,
        guid TEXT UNIQUE NOT NULL,
        guests TEXT,
        tags TEXT,
        explicit INTEGER,
        FOREIGN KEY (feedId) REFERENCES feeds(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS subscriptions (
        feedId TEXT PRIMARY KEY,
        subscribedAt INTEGER NOT NULL,
        lastEpisodeRead INTEGER,
        FOREIGN KEY (feedId) REFERENCES feeds(id) ON DELETE CASCADE
      );

      CREATE INDEX IF NOT EXISTS idx_episodes_feedId ON episodes(feedId);
      CREATE INDEX IF NOT EXISTS idx_episodes_pubDate ON episodes(pubDate);
      CREATE INDEX IF NOT EXISTS idx_episodes_title ON episodes(title);
    `);
    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Failed to initialize database:', error);
    throw error;
  }
}

// Feed operations
export async function addFeed(feed: Feed): Promise<void> {
  try {
    await db.runAsync(
      `INSERT INTO feeds (id, url, title, description, imageUrl, language, author, category, createdAt, lastFetched)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        feed.id,
        feed.url,
        feed.title,
        feed.description,
        feed.imageUrl || null,
        feed.language || null,
        feed.author || null,
        feed.category || null,
        feed.createdAt.getTime(),
        feed.lastFetched.getTime(),
      ]
    );
  } catch (error) {
    console.error('Error adding feed:', error);
    throw error;
  }
}

export async function getFeed(id: string): Promise<Feed | null> {
  try {
    const result = await db.getFirstAsync(
      'SELECT * FROM feeds WHERE id = ?',
      [id]
    );
    return result ? dbRowToFeed(result) : null;
  } catch (error) {
    console.error('Error getting feed:', error);
    throw error;
  }
}

export async function getAllFeeds(): Promise<Feed[]> {
  try {
    const results = await db.getAllAsync('SELECT * FROM feeds ORDER BY createdAt DESC');
    return results.map(dbRowToFeed);
  } catch (error) {
    console.error('Error getting feeds:', error);
    throw error;
  }
}

export async function updateFeedLastFetched(id: string, date: Date): Promise<void> {
  try {
    await db.runAsync(
      'UPDATE feeds SET lastFetched = ? WHERE id = ?',
      [date.getTime(), id]
    );
  } catch (error) {
    console.error('Error updating feed:', error);
    throw error;
  }
}

export async function deleteFeed(id: string): Promise<void> {
  try {
    await db.runAsync('DELETE FROM feeds WHERE id = ?', [id]);
  } catch (error) {
    console.error('Error deleting feed:', error);
    throw error;
  }
}

// Episode operations
export async function addEpisode(episode: Episode): Promise<void> {
  try {
    await db.runAsync(
      `INSERT OR IGNORE INTO episodes (id, feedId, title, description, content, audioUrl, imageUrl, duration, pubDate, guid, guests, tags, explicit)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        episode.id,
        episode.feedId,
        episode.title,
        episode.description,
        episode.content || null,
        episode.audioUrl,
        episode.imageUrl || null,
        episode.duration || null,
        episode.pubDate.getTime(),
        episode.guid,
        episode.guests ? JSON.stringify(episode.guests) : null,
        episode.tags ? JSON.stringify(episode.tags) : null,
        episode.explicit ? 1 : 0,
      ]
    );
  } catch (error) {
    console.error('Error adding episode:', error);
    throw error;
  }
}

export async function getEpisodesByFeed(feedId: string): Promise<Episode[]> {
  try {
    const results = await db.getAllAsync(
      'SELECT * FROM episodes WHERE feedId = ? ORDER BY pubDate DESC',
      [feedId]
    );
    return results.map(dbRowToEpisode);
  } catch (error) {
    console.error('Error getting episodes:', error);
    throw error;
  }
}

export async function searchEpisodes(
  query: string,
  feedIds?: string[]
): Promise<Episode[]> {
  try {
    const whereClause = feedIds && feedIds.length > 0
      ? `(title LIKE ? OR description LIKE ? OR guests LIKE ?) AND feedId IN (${feedIds.map(() => '?').join(',')})`
      : '(title LIKE ? OR description LIKE ? OR guests LIKE ?)';

    const searchTerm = `%${query}%`;
    const params = feedIds && feedIds.length > 0
      ? [searchTerm, searchTerm, searchTerm, ...feedIds]
      : [searchTerm, searchTerm, searchTerm];

    const results = await db.getAllAsync(
      `SELECT * FROM episodes WHERE ${whereClause} ORDER BY pubDate DESC`,
      params
    );
    return results.map(dbRowToEpisode);
  } catch (error) {
    console.error('Error searching episodes:', error);
    throw error;
  }
}

export async function getRecentEpisodes(limit: number = 50): Promise<Episode[]> {
  try {
    const results = await db.getAllAsync(
      'SELECT * FROM episodes ORDER BY pubDate DESC LIMIT ?',
      [limit]
    );
    return results.map(dbRowToEpisode);
  } catch (error) {
    console.error('Error getting recent episodes:', error);
    throw error;
  }
}

// Subscription operations
export async function addSubscription(feedId: string): Promise<void> {
  try {
    await db.runAsync(
      'INSERT OR IGNORE INTO subscriptions (feedId, subscribedAt) VALUES (?, ?)',
      [feedId, new Date().getTime()]
    );
  } catch (error) {
    console.error('Error adding subscription:', error);
    throw error;
  }
}

export async function getSubscriptions(): Promise<Subscription[]> {
  try {
    const results = await db.getAllAsync('SELECT * FROM subscriptions ORDER BY subscribedAt DESC');
    return results.map((row) => ({
      feedId: row.feedId,
      subscribedAt: new Date(row.subscribedAt),
      lastEpisodeRead: row.lastEpisodeRead ? new Date(row.lastEpisodeRead) : undefined,
    }));
  } catch (error) {
    console.error('Error getting subscriptions:', error);
    throw error;
  }
}

export async function removeSubscription(feedId: string): Promise<void> {
  try {
    await db.runAsync('DELETE FROM subscriptions WHERE feedId = ?', [feedId]);
  } catch (error) {
    console.error('Error removing subscription:', error);
    throw error;
  }
}

// Helper functions
function dbRowToFeed(row: any): Feed {
  return {
    id: row.id,
    url: row.url,
    title: row.title,
    description: row.description,
    imageUrl: row.imageUrl,
    language: row.language,
    author: row.author,
    category: row.category,
    createdAt: new Date(row.createdAt),
    lastFetched: new Date(row.lastFetched),
  };
}

function dbRowToEpisode(row: any): Episode {
  return {
    id: row.id,
    feedId: row.feedId,
    title: row.title,
    description: row.description,
    content: row.content,
    audioUrl: row.audioUrl,
    imageUrl: row.imageUrl,
    duration: row.duration,
    pubDate: new Date(row.pubDate),
    guid: row.guid,
    guests: row.guests ? JSON.parse(row.guests) : undefined,
    tags: row.tags ? JSON.parse(row.tags) : undefined,
    explicit: row.explicit === 1,
  };
}
