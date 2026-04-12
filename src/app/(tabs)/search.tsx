import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  FlatList,
  Pressable,
  Image,
  ScrollView,
} from 'react-native';
import { usePodcastStore } from '@/store/podcastStore';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { formatDistanceToNow } from 'date-fns';

export default function SearchScreen() {
  const router = useRouter();
  const [query, setQuery] = useState('');

  const {
    searchResults,
    isLoading,
    searchEpisodes,
    feeds,
    subscriptions,
    clearSearch,
  } = usePodcastStore();

  const handleSearch = async (text: string) => {
    setQuery(text);
    if (text.trim().length > 2) {
      await searchEpisodes(text);
    } else {
      clearSearch();
    }
  };

  const handleClear = () => {
    setQuery('');
    clearSearch();
  };

  const getFeedTitle = (feedId: string) => {
    return feeds.find((f) => f.id === feedId)?.title || 'Unknown Podcast';
  };

  const isSubscribed = subscriptions.length > 0;

  return (
    <View style={{ flex: 1, backgroundColor: '#121212' }}>
      <View style={{ padding: 15, backgroundColor: '#1f1f1f' }}>
        <View
          style={{
            flexDirection: 'row',
            alignItems: 'center',
            backgroundColor: '#333',
            borderRadius: 24,
            paddingHorizontal: 12,
            gap: 8,
          }}
        >
          <MaterialCommunityIcons name="magnify" size={20} color="#888" />
          <TextInput
            placeholder="Search episodes..."
            placeholderTextColor="#888"
            value={query}
            onChangeText={handleSearch}
            style={{
              flex: 1,
              color: '#fff',
              paddingVertical: 12,
              fontSize: 16,
            }}
          />
          {query.length > 0 && (
            <Pressable onPress={handleClear} style={{ padding: 4 }}>
              <MaterialCommunityIcons name="close" size={20} color="#888" />
            </Pressable>
          )}
        </View>
        {!isSubscribed && (
          <Text
            style={{
              color: '#888',
              fontSize: 12,
              marginTop: 12,
              textAlign: 'center',
            }}
          >
            Subscribe to podcasts to search episodes
          </Text>
        )}
      </View>

      {!isSubscribed ? (
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 }}>
          <MaterialCommunityIcons name="magnify" size={80} color="#888" />
          <Text style={{ color: '#fff', fontSize: 18, fontWeight: 'bold', marginTop: 20 }}>
            No Subscriptions
          </Text>
          <Text
            style={{
              color: '#bbb',
              fontSize: 14,
              marginTop: 10,
              textAlign: 'center',
            }}
          >
            Add podcasts first to search episodes
          </Text>
        </View>
      ) : query.length <= 2 ? (
        <ScrollView
          style={{ flex: 1, padding: 15 }}
          contentContainerStyle={{ paddingBottom: 20 }}
        >
          <Text style={{ color: '#888', fontSize: 14, textAlign: 'center', marginTop: 40 }}>
            Type at least 3 characters to search
          </Text>
        </ScrollView>
      ) : isLoading ? (
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
          <MaterialCommunityIcons name="loading" size={40} color="#1DB954" />
          <Text style={{ color: '#888', fontSize: 14, marginTop: 15 }}>
            Searching...
          </Text>
        </View>
      ) : searchResults.length === 0 ? (
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 }}>
          <MaterialCommunityIcons name="inbox-multiple" size={60} color="#888" />
          <Text style={{ color: '#fff', fontSize: 16, fontWeight: 'bold', marginTop: 15 }}>
            No Results Found
          </Text>
          <Text
            style={{
              color: '#bbb',
              fontSize: 14,
              marginTop: 8,
              textAlign: 'center',
            }}
          >
            Try different keywords
          </Text>
        </View>
      ) : (
        <FlatList
          data={searchResults}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => (
            <Pressable
              onPress={() => router.push(`/episode/${item.id}`)}
              style={{
                padding: 15,
                borderBottomColor: '#222',
                borderBottomWidth: 1,
              }}
            >
              <View style={{ flexDirection: 'row', gap: 12 }}>
                {item.imageUrl && (
                  <Image
                    source={{ uri: item.imageUrl }}
                    style={{ width: 80, height: 80, borderRadius: 8 }}
                  />
                )}
                <View style={{ flex: 1 }}>
                  <Text style={{ color: '#1DB954', fontSize: 12, fontWeight: '600' }}>
                    {getFeedTitle(item.feedId)}
                  </Text>
                  <Text
                    style={{
                      color: '#fff',
                      fontSize: 14,
                      fontWeight: 'bold',
                      marginTop: 4,
                    }}
                    numberOfLines={2}
                  >
                    {item.title}
                  </Text>
                  <View style={{ flexDirection: 'row', gap: 8, marginTop: 8, alignItems: 'center' }}>
                    {item.duration && (
                      <Text style={{ color: '#888', fontSize: 12 }}>
                        {Math.floor(item.duration / 60)} min
                      </Text>
                    )}
                    <Text style={{ color: '#888', fontSize: 12 }}>
                      {formatDistanceToNow(item.pubDate, { addSuffix: true })}
                    </Text>
                  </View>
                </View>
              </View>
            </Pressable>
          )}
          scrollEnabled
          nestedScrollEnabled
        />
      )}
    </View>
  );
}
