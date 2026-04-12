import React, { useState } from 'react';
import { View, Text, FlatList, Pressable, Image, RefreshControl } from 'react-native';
import { usePodcastStore } from '@/store/podcastStore';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter, useFocusEffect } from 'expo-router';
import { formatDistanceToNow } from 'date-fns';

export default function SubscriptionsScreen() {
  const router = useRouter();
  const [refreshing, setRefreshing] = useState(false);

  const {
    feeds,
    subscriptions,
    loadSubscriptions,
    refreshFeeds,
    unsubscribe,
  } = usePodcastStore();

  useFocusEffect(
    React.useCallback(() => {
      loadSubscriptions().catch((error) => {
        console.error('Failed to load subscriptions:', error);
      });
    }, [])
  );

  const subscribedFeeds = feeds.filter((f) =>
    subscriptions.some((s) => s.feedId === f.id)
  );

  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshFeeds();
    } finally {
      setRefreshing(false);
    }
  };

  const handleUnsubscribe = async (feedId: string) => {
    try {
      await unsubscribe(feedId);
    } catch (error) {
      console.error('Failed to unsubscribe:', error);
    }
  };

  return (
    <View style={{ flex: 1, backgroundColor: '#121212' }}>
      {subscribedFeeds.length === 0 ? (
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 }}>
          <MaterialCommunityIcons name="bookmark-outline" size={80} color="#888" />
          <Text style={{ color: '#fff', fontSize: 20, fontWeight: 'bold', marginTop: 20 }}>
            No Subscriptions Yet
          </Text>
          <Text
            style={{
              color: '#bbb',
              fontSize: 16,
              marginTop: 10,
              textAlign: 'center',
            }}
          >
            Subscribe to podcasts to see them here
          </Text>
        </View>
      ) : (
        <FlatList
          data={subscribedFeeds}
          keyExtractor={(item) => item.id}
          refreshControl={<RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />}
          renderItem={({ item }) => (
            <Pressable
              onPress={() => router.push(`/feed/${item.id}`)}
              style={{
                padding: 15,
                borderBottomColor: '#222',
                borderBottomWidth: 1,
                flexDirection: 'row',
                gap: 12,
              }}
            >
              {item.imageUrl && (
                <Image
                  source={{ uri: item.imageUrl }}
                  style={{ width: 100, height: 100, borderRadius: 8 }}
                />
              )}
              <View style={{ flex: 1, justifyContent: 'space-between' }}>
                <View>
                  <Text
                    style={{
                      color: '#fff',
                      fontSize: 16,
                      fontWeight: 'bold',
                    }}
                    numberOfLines={2}
                  >
                    {item.title}
                  </Text>
                  <Text
                    style={{
                      color: '#bbb',
                      fontSize: 12,
                      marginTop: 6,
                    }}
                    numberOfLines={2}
                  >
                    {item.description}
                  </Text>
                </View>
                <Text style={{ color: '#888', fontSize: 11, marginTop: 8 }}>
                  Updated {formatDistanceToNow(item.lastFetched, { addSuffix: true })}
                </Text>
              </View>
              <Pressable
                onPress={() => handleUnsubscribe(item.id)}
                style={{ padding: 10, justifyContent: 'center' }}
              >
                <MaterialCommunityIcons name="bookmark" size={24} color="#1DB954" />
              </Pressable>
            </Pressable>
          )}
        />
      )}
    </View>
  );
}
