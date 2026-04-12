import { create } from 'zustand';
import { Feed, Episode, Subscription, SearchFilter } from '@/types';
import * as db from '@/services/database';
import { parseFeedUrl } from '@/services/rssParser';

interface PodcastState {
  // Data
  feeds: Feed[];
  episodes: Episode[];
  subscriptions: Subscription[];
  currentFeed: Feed | null;
  currentEpisodes: Episode[];

  // Loading states
  isLoading: boolean;
  isFetching: boolean;
  error: string | null;

  // Search and filtering
  searchQuery: string;
  searchFilter: SearchFilter;
  searchResults: Episode[];

  // Actions
  initializeDatabase: () => Promise<void>;
  addFeed: (url: string) => Promise<void>;
  loadFeeds: () => Promise<void>;
  loadSubscriptions: () => Promise<void>;
  selectFeed: (feedId: string) => Promise<void>;
  subscribe: (feedId: string) => Promise<void>;
  unsubscribe: (feedId: string) => Promise<void>;
  removeFeed: (feedId: string) => Promise<void>;
  refreshFeeds: () => Promise<void>;
  refreshFeed: (feedId: string) => Promise<void>;
  searchEpisodes: (query: string) => Promise<void>;
  getRecentEpisodes: (limit?: number) => Promise<void>;
  setSearchFilter: (filter: SearchFilter) => void;
  clearSearch: () => void;
  setError: (error: string | null) => void;
}

export const usePodcastStore = create<PodcastState>((set, get) => ({
  // Initial state
  feeds: [],
  episodes: [],
  subscriptions: [],
  currentFeed: null,
  currentEpisodes: [],
  isLoading: false,
  isFetching: false,
  error: null,
  searchQuery: '',
  searchFilter: {},
  searchResults: [],

  // Actions
  initializeDatabase: async () => {
    try {
      set({ isLoading: true, error: null });
      await db.initDatabase();
      await get().loadFeeds();
      await get().loadSubscriptions();
      set({ isLoading: false });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to initialize database';
      set({ error: errorMessage, isLoading: false });
      throw error;
    }
  },

  addFeed: async (url: string) => {
    try {
      set({ isFetching: true, error: null });

      const { feed, episodes } = await parseFeedUrl(url);

      // Save feed to database
      await db.addFeed(feed);

      // Save episodes
      for (const episode of episodes) {
        await db.addEpisode(episode);
      }

      // Reload feeds
      await get().loadFeeds();

      set({ isFetching: false });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to add feed';
      set({ error: errorMessage, isFetching: false });
      throw error;
    }
  },

  loadFeeds: async () => {
    try {
      const feeds = await db.getAllFeeds();
      set({ feeds });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to load feeds';
      set({ error: errorMessage });
      throw error;
    }
  },

  loadSubscriptions: async () => {
    try {
      const subscriptions = await db.getSubscriptions();
      set({ subscriptions });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to load subscriptions';
      set({ error: errorMessage });
      throw error;
    }
  },

  selectFeed: async (feedId: string) => {
    try {
      set({ isLoading: true, error: null });

      const feed = await db.getFeed(feedId);
      const episodes = await db.getEpisodesByFeed(feedId);

      set({
        currentFeed: feed,
        currentEpisodes: episodes,
        isLoading: false,
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to load feed';
      set({ error: errorMessage, isLoading: false });
      throw error;
    }
  },

  subscribe: async (feedId: string) => {
    try {
      await db.addSubscription(feedId);
      await get().loadSubscriptions();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to subscribe';
      set({ error: errorMessage });
      throw error;
    }
  },

  unsubscribe: async (feedId: string) => {
    try {
      await db.removeSubscription(feedId);
      await get().loadSubscriptions();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to unsubscribe';
      set({ error: errorMessage });
      throw error;
    }
  },

  removeFeed: async (feedId: string) => {
    try {
      await db.unsubscribe(feedId);
      await db.deleteFeed(feedId);
      await get().loadFeeds();
      await get().loadSubscriptions();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to remove feed';
      set({ error: errorMessage });
      throw error;
    }
  },

  refreshFeeds: async () => {
    try {
      set({ isFetching: true, error: null });

      const state = get();
      const feeds = state.feeds;

      for (const feed of feeds) {
        try {
          const { episodes } = await parseFeedUrl(feed.url);

          for (const episode of episodes) {
            await db.addEpisode(episode);
          }

          await db.updateFeedLastFetched(feed.id, new Date());
        } catch (error) {
          console.error(`Failed to refresh feed ${feed.id}:`, error);
        }
      }

      await get().loadFeeds();
      set({ isFetching: false });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to refresh feeds';
      set({ error: errorMessage, isFetching: false });
      throw error;
    }
  },

  refreshFeed: async (feedId: string) => {
    try {
      set({ isFetching: true, error: null });

      const feed = await db.getFeed(feedId);
      if (!feed) {
        throw new Error('Feed not found');
      }

      const { episodes } = await parseFeedUrl(feed.url);

      for (const episode of episodes) {
        await db.addEpisode(episode);
      }

      await db.updateFeedLastFetched(feedId, new Date());

      // Reload current episodes if this is the selected feed
      const state = get();
      if (state.currentFeed?.id === feedId) {
        await get().selectFeed(feedId);
      }

      set({ isFetching: false });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to refresh feed';
      set({ error: errorMessage, isFetching: false });
      throw error;
    }
  },

  searchEpisodes: async (query: string) => {
    try {
      set({ isLoading: true, error: null, searchQuery: query });

      const state = get();
      const subscribedFeedIds = state.subscriptions.map((s) => s.feedId);

      const results = await db.searchEpisodes(query, subscribedFeedIds);

      set({
        searchResults: results,
        isLoading: false,
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to search episodes';
      set({ error: errorMessage, isLoading: false });
      throw error;
    }
  },

  getRecentEpisodes: async (limit = 50) => {
    try {
      set({ isLoading: true, error: null });

      const episodes = await db.getRecentEpisodes(limit);

      set({
        episodes,
        isLoading: false,
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to load recent episodes';
      set({ error: errorMessage, isLoading: false });
      throw error;
    }
  },

  setSearchFilter: (filter: SearchFilter) => {
    set({ searchFilter: filter });
  },

  clearSearch: () => {
    set({
      searchQuery: '',
      searchFilter: {},
      searchResults: [],
    });
  },

  setError: (error: string | null) => {
    set({ error });
  },
}));
