import axios from 'axios';
import { parseStringPromise } from 'xml2js';
import { v4 as uuidv4 } from 'uuid';
import { Feed, Episode } from '@/types';

interface RSSFeed {
  rss?: {
    channel?: Array<{
      title?: string[];
      description?: string[];
      image?: Array<{
        url?: string[];
      }>;
      language?: string[];
      author?: string[];
      category?: string[];
      lastBuildDate?: string[];
      item?: Array<any>;
    }>;
  };
  feed?: {
    title?: string[];
    summary?: string[];
    image?: Array<{
      url?: string[];
    }>;
    entry?: Array<any>;
  };
}

export async function parseFeedUrl(url: string): Promise<{ feed: Feed; episodes: Episode[] }> {
  try {
    const response = await axios.get(url, {
      timeout: 10000,
      headers: {
        'User-Agent': 'Transistor/0.1.0',
      },
    });

    const parsed = await parseStringPromise(response.data);

    // Handle RSS 2.0 format
    if (parsed.rss?.channel?.[0]) {
      return parseRSSFeed(url, parsed);
    }

    // Handle Atom format
    if (parsed.feed) {
      return parseAtomFeed(url, parsed);
    }

    throw new Error('Unsupported feed format');
  } catch (error) {
    console.error('Error parsing feed:', error);
    throw error;
  }
}

function parseRSSFeed(url: string, parsed: RSSFeed): { feed: Feed; episodes: Episode[] } {
  const channel = parsed.rss?.channel?.[0];
  if (!channel) {
    throw new Error('Invalid RSS feed structure');
  }

  const feedId = uuidv4();
  const now = new Date();

  const feed: Feed = {
    id: feedId,
    url,
    title: getString(channel.title),
    description: getString(channel.description),
    imageUrl: channel.image?.[0]?.url?.[0],
    language: getString(channel.language),
    author: getString(channel.author),
    category: getString(channel.category),
    createdAt: now,
    lastFetched: now,
  };

  const episodes: Episode[] = (channel.item || []).map((item: any) => {
    const enclosure = item.enclosure?.[0];
    const audioUrl = enclosure?.$.url || item['media:content']?.[0]?.$.url || '';

    return {
      id: uuidv4(),
      feedId,
      title: getString(item.title),
      description: getString(item.description),
      content: getString(item['content:encoded']),
      audioUrl,
      imageUrl: item['media:thumbnail']?.[0]?.$.url || channel.image?.[0]?.url?.[0],
      duration: parseDuration(item['itunes:duration']?.[0]),
      pubDate: new Date(getString(item.pubDate) || now.toISOString()),
      guid: getString(item.guid),
      guests: parseGuests(item),
      tags: parseTags(item),
      explicit: getString(item['itunes:explicit']) === 'yes',
    };
  });

  return { feed, episodes };
}

function parseAtomFeed(url: string, parsed: any): { feed: Feed; episodes: Episode[] } {
  const feedData = parsed.feed;
  if (!feedData) {
    throw new Error('Invalid Atom feed structure');
  }

  const feedId = uuidv4();
  const now = new Date();

  const feed: Feed = {
    id: feedId,
    url,
    title: getString(feedData.title),
    description: getString(feedData.summary),
    imageUrl: feedData.image?.[0]?.url?.[0],
    createdAt: now,
    lastFetched: now,
  };

  const episodes: Episode[] = (feedData.entry || []).map((entry: any) => {
    const link = entry.link?.[0]?.$.href || '';
    const audioLink = entry.link?.find((l: any) =>
      l?.$.type?.includes('audio') || l?.$.rel?.includes('enclosure')
    );
    const audioUrl = audioLink?.$.href || link;

    return {
      id: uuidv4(),
      feedId,
      title: getString(entry.title),
      description: getString(entry.summary),
      content: getString(entry.content),
      audioUrl,
      imageUrl: feedData.image?.[0]?.url?.[0],
      duration: parseDuration(entry['media:duration']?.[0]),
      pubDate: new Date(getString(entry.published) || now.toISOString()),
      guid: getString(entry.id),
      guests: parseGuests(entry),
      tags: parseTags(entry),
      explicit: false,
    };
  });

  return { feed, episodes };
}

function getString(value: string | string[] | undefined): string {
  if (Array.isArray(value)) {
    return value[0] || '';
  }
  return value || '';
}

function parseDuration(value: string | undefined): number | undefined {
  if (!value) return undefined;

  // Format: HH:MM:SS or MM:SS
  const parts = value.split(':').map(Number);
  let seconds = 0;

  if (parts.length === 3) {
    seconds = parts[0] * 3600 + parts[1] * 60 + parts[2];
  } else if (parts.length === 2) {
    seconds = parts[0] * 60 + parts[1];
  } else if (parts.length === 1) {
    seconds = parts[0];
  }

  return seconds > 0 ? seconds : undefined;
}

function parseGuests(item: any): string[] | undefined {
  const guests: Set<string> = new Set();

  // iTunes author tag
  const author = item['itunes:author']?.[0];
  if (author) {
    guests.add(author);
  }

  // Podcast Namespace person tags
  const persons = item['podcast:person'];
  if (Array.isArray(persons)) {
    persons.forEach((person: any) => {
      if (person._) {
        guests.add(person._);
      }
    });
  }

  // Extract from description if mentions specific people
  const description = getString(item.description);
  const guestMatches = description.match(/(featuring|with|guest|host):\s*([^,.]+)/gi);
  if (guestMatches) {
    guestMatches.forEach((match: string) => {
      const name = match.replace(/(featuring|with|guest|host):\s*/i, '').trim();
      if (name.length > 2) {
        guests.add(name);
      }
    });
  }

  return guests.size > 0 ? Array.from(guests) : undefined;
}

function parseTags(item: any): string[] | undefined {
  const tags: Set<string> = new Set();

  // iTunes keywords
  const keywords = item['itunes:keywords']?.[0];
  if (keywords) {
    keywords.split(',').forEach((keyword: string) => {
      const trimmed = keyword.trim();
      if (trimmed.length > 1) {
        tags.add(trimmed);
      }
    });
  }

  // Category tags
  const categories = item.category;
  if (Array.isArray(categories)) {
    categories.forEach((cat: any) => {
      const catText = cat.$.text || cat._;
      if (catText) {
        tags.add(catText);
      }
    });
  }

  return tags.size > 0 ? Array.from(tags) : undefined;
}
