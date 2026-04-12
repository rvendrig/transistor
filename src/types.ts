// Podcast Feed Types
export interface Feed {
  id: string;
  url: string;
  title: string;
  description: string;
  imageUrl?: string;
  language?: string;
  author?: string;
  category?: string;
  createdAt: Date;
  lastFetched: Date;
}

export interface Episode {
  id: string;
  feedId: string;
  title: string;
  description: string;
  content?: string;
  audioUrl: string;
  imageUrl?: string;
  duration?: number;
  pubDate: Date;
  guid: string;
  guests?: string[];
  tags?: string[];
  explicit?: boolean;
}

export interface SearchFilter {
  query?: string;
  category?: string;
  guests?: string[];
  tags?: string[];
  fromDate?: Date;
  toDate?: Date;
}

export interface FeedMetadata {
  lastBuildDate?: Date;
  language?: string;
  copyright?: string;
  author?: string;
}

export interface Subscription {
  feedId: string;
  subscribedAt: Date;
  lastEpisodeRead?: Date;
}
