import { create } from 'zustand';
import { NPOProgram, NPOBroadcast, NPOChannel } from '@/types/npo';
import * as npoAPI from '@/services/npoAPI';
import * as npoDb from '@/services/npoDatabase';

interface NPOState {
  // Data
  channels: NPOChannel[];
  programs: NPOProgram[];
  broadcasts: NPOBroadcast[];
  currentProgram: NPOProgram | null;
  currentBroadcasts: NPOBroadcast[];
  favorites: NPOBroadcast[];
  selectedChannel: string | null;

  // Loading states
  isLoading: boolean;
  isFetching: boolean;
  error: string | null;

  // Search
  searchQuery: string;
  searchResults: NPOBroadcast[];

  // Actions
  initializeNPO: () => Promise<void>;
  loadChannels: () => Promise<void>;
  selectChannel: (channelId: string) => Promise<void>;
  loadPrograms: (channelId: string) => Promise<void>;
  selectProgram: (program: NPOProgram) => Promise<void>;
  refreshBroadcasts: (programId: string) => Promise<void>;
  searchBroadcasts: (query: string) => Promise<void>;
  loadFavorites: () => Promise<void>;
  addFavorite: (broadcast: NPOBroadcast) => Promise<void>;
  removeFavorite: (broadcastId: string) => Promise<void>;
  isFavoriteBroadcast: (broadcastId: string) => Promise<boolean>;
  clearSearch: () => void;
  setError: (error: string | null) => void;
}

export const useNPOStore = create<NPOState>((set, get) => ({
  // Initial state
  channels: Object.values(npoAPI.NPO_CHANNELS),
  programs: [],
  broadcasts: [],
  currentProgram: null,
  currentBroadcasts: [],
  favorites: [],
  selectedChannel: null,
  isLoading: false,
  isFetching: false,
  error: null,
  searchQuery: '',
  searchResults: [],

  // Actions
  initializeNPO: async () => {
    try {
      set({ isLoading: true, error: null });
      await npoDb.initNPODatabase();

      // Save all channels to database
      for (const channel of Object.values(npoAPI.NPO_CHANNELS)) {
        await npoDb.saveChannel(channel);
      }

      await get().loadFavorites();
      set({ isLoading: false });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to initialize NPO';
      set({ error: errorMessage, isLoading: false });
      throw error;
    }
  },

  loadChannels: async () => {
    try {
      const channels = await npoDb.getChannels();
      set({ channels });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to load channels';
      set({ error: errorMessage });
    }
  },

  selectChannel: async (channelId: string) => {
    try {
      set({ selectedChannel: channelId, isLoading: true, error: null });
      await get().loadPrograms(channelId);
      set({ isLoading: false });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to select channel';
      set({ error: errorMessage, isLoading: false });
    }
  },

  loadPrograms: async (channelId: string) => {
    try {
      set({ isLoading: true, error: null });

      // First try to load from database
      let programs = await npoDb.getProgramsByChannel(channelId);

      // If empty, fetch from API
      if (programs.length === 0) {
        programs = await npoAPI.getNPOPrograms(channelId);
        for (const program of programs) {
          await npoDb.saveProgram(program, channelId);
        }
      }

      set({ programs, isLoading: false });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to load programs';
      set({ error: errorMessage, isLoading: false });
      throw error;
    }
  },

  selectProgram: async (program: NPOProgram) => {
    try {
      set({ currentProgram: program, isLoading: true, error: null });

      // Load broadcasts for this program
      let broadcasts = await npoDb.getBroadcastsByProgram(program.id, 50);

      // If empty, fetch from API
      if (broadcasts.length === 0) {
        broadcasts = await npoAPI.getNPOBroadcasts(program.id, 50);
        for (const broadcast of broadcasts) {
          await npoDb.saveBroadcast(broadcast);
        }
      }

      set({ currentBroadcasts: broadcasts, isLoading: false });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to load broadcasts';
      set({ error: errorMessage, isLoading: false });
      throw error;
    }
  },

  refreshBroadcasts: async (programId: string) => {
    try {
      set({ isFetching: true, error: null });

      // Fetch from API
      const broadcasts = await npoAPI.getNPOBroadcasts(programId, 50);

      // Save to database
      for (const broadcast of broadcasts) {
        await npoDb.saveBroadcast(broadcast);
      }

      set({ currentBroadcasts: broadcasts, isFetching: false });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to refresh broadcasts';
      set({ error: errorMessage, isFetching: false });
      throw error;
    }
  },

  searchBroadcasts: async (query: string) => {
    try {
      set({ isLoading: true, error: null, searchQuery: query });

      // First search in database
      let results = await npoDb.searchBroadcasts(query);

      // If limited results, fetch from API
      if (results.length < 5) {
        const apiResults = await npoAPI.searchNPOBroadcasts(query);
        for (const broadcast of apiResults) {
          await npoDb.saveBroadcast(broadcast);
        }
        results = apiResults;
      }

      set({ searchResults: results, isLoading: false });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to search broadcasts';
      set({ error: errorMessage, isLoading: false });
      throw error;
    }
  },

  loadFavorites: async () => {
    try {
      const favorites = await npoDb.getFavorites();
      set({ favorites });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to load favorites';
      set({ error: errorMessage });
    }
  },

  addFavorite: async (broadcast: NPOBroadcast) => {
    try {
      await npoDb.addFavorite(broadcast.id);
      const favorites = await npoDb.getFavorites();
      set({ favorites });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to add favorite';
      set({ error: errorMessage });
      throw error;
    }
  },

  removeFavorite: async (broadcastId: string) => {
    try {
      await npoDb.removeFavorite(broadcastId);
      const favorites = await npoDb.getFavorites();
      set({ favorites });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to remove favorite';
      set({ error: errorMessage });
      throw error;
    }
  },

  isFavoriteBroadcast: async (broadcastId: string) => {
    try {
      return await npoDb.isFavorite(broadcastId);
    } catch (error) {
      return false;
    }
  },

  clearSearch: () => {
    set({ searchQuery: '', searchResults: [] });
  },

  setError: (error: string | null) => {
    set({ error });
  },
}));
