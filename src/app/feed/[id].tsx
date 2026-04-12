import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  Pressable,
  Image,
  RefreshControl,
  Alert,
  ScrollView,
} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { usePodcastStore } from '@/store/podcastStore';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { formatDistanceToNow } from 'date-fns';

export default function FeedDetailScreen() {
  const route = useRoute();
  const router = useRouter();
  const [refreshing, setRefreshing] = useState(false);

  const {
    currentFeed,
    currentEpisodes,
    subscriptions,
    selectFeed,
    refreshFeed,
    subscribe,
    unsubscribe,
    removeFeed,
  } = usePodcastStore();

  const feedId = (route.params?.id as string) || '';

  useEffect(() => {
    if (feedId) {
      selectFeed(feedId).catch((error) => {
        console.error('Failed to load feed:', error);
      });
    }
  }, [feedId]);

  const isSubscribed = subscriptions.some((s) => s.feedId === feedId);

  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshFeed(feedId);
    } finally {
      setRefreshing(false);
    }
  };

  const handleToggleSubscription = async () => {
    try {
      if (isSubscribed) {
        await unsubscribe(feedId);
      } else {
        await subscribe(feedId);
      }
    } catch (error) {
      Alert.alert('Error', 'Failed to update subscription');
    }
  };

  const handleRemoveFeed = async () => {
    Alert.alert(
      'Remove Podcast',
      'Are you sure you want to remove this podcast?',
      [
        {
          text: 'Cancel',
          onPress: () => {},
        },
        {
          text: 'Remove',
          onPress: async () => {
            try {
              await removeFeed(feedId);
              router.back();
            } catch (error) {
              Alert.alert('Error', 'Failed to remove feed');
            }
          },
          style: 'destructive',
        },
      ]
    );
  };

  if (!currentFeed) {
    return (
      <View style={{ flex: 1, backgroundColor: '#121212', justifyContent: 'center', alignItems: 'center' }}>
        <Text style={{ color: '#888' }}>Loading...</Text>
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: '#121212' }}>
      <FlatList
        data={currentEpisodes}
        keyExtractor={(item) => item.id}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />}
        ListHeaderComponent={() => (
          <View style={{ backgroundColor: '#1f1f1f', padding: 15 }}>
            {currentFeed.imageUrl && (
              <Image
                source={{ uri: currentFeed.imageUrl }}
                style={{
                  width: '100%',
                  height: 200,
                  borderRadius: 12,
                  marginBottom: 20,
                }}
              />
            )}

            <Text
              style={{
                color: '#fff',
                fontSize: 22,
                fontWeight: 'bold',
                marginBottom: 8,
              }}
            >
              {currentFeed.title}
            </Text>

            <Text
              style={{
                color: '#bbb',
                fontSize: 13,
                marginBottom: 20,
                lineHeight: 18,
              }}
            >
              {currentFeed.description}
            </Text>

            <View style={{ flexDirection: 'row', gap: 10, marginBottom: 15 }}>
              <Pressable
                onPress={handleToggleSubscription}
                style={{
                  flex: 1,
                  backgroundColor: isSubscribed ? '#1DB954' : '#333',
                  paddingVertical: 12,
                  borderRadius: 8,
                  alignItems: 'center',
                  flexDirection: 'row',
                  justifyContent: 'center',
                  gap: 8,
                }}
              >
                <MaterialCommunityIcons
                  name={isSubscribed ? 'bookmark' : 'bookmark-outline'}
                  size={18}
                  color={isSubscribed ? '#fff' : '#1DB954'}
                />
                <Text
                  style={{
                    color: isSubscribed ? '#fff' : '#1DB954',
                    fontWeight: 'bold',
                  }}
                >
                  {isSubscribed ? 'Subscribed' : 'Subscribe'}
                </Text>
              </Pressable>

              <Pressable
                onPress={handleRemoveFeed}
                style={{
                  paddingHorizontal: 15,
                  paddingVertical: 12,
                  borderRadius: 8,
                  backgroundColor: '#333',
                  justifyContent: 'center',
                }}
              >
                <MaterialCommunityIcons name="trash-can-outline" size={18} color="#ff6b6b" />
              </Pressable>
            </View>

            {currentFeed.author && (
              <Text style={{ color: '#888', fontSize: 12, marginBottom: 8 }}>
                By {currentFeed.author}
              </Text>
            )}

            <Text style={{ color: '#888', fontSize: 12 }}>
              {currentEpisodes.length} episodes
            </Text>

            <View style={{ marginTop: 20, paddingTop: 20, borderTopWidth: 1, borderTopColor: '#333' }}>
              <Text style={{ color: '#1DB954', fontSize: 14, fontWeight: 'bold' }}>
                Episodes
              </Text>
            </View>
          </View>
        )}
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
                  style={{ width: 70, height: 70, borderRadius: 6 }}
                />
              )}
              <View style={{ flex: 1 }}>
                <Text
                  style={{
                    color: '#fff',
                    fontSize: 13,
                    fontWeight: 'bold',
                  }}
                  numberOfLines={2}
                >
                  {item.title}
                </Text>
                <View style={{ flexDirection: 'row', gap: 8, marginTop: 8, alignItems: 'center' }}>
                  {item.duration && (
                    <Text style={{ color: '#888', fontSize: 11 }}>
                      {Math.floor(item.duration / 60)} min
                    </Text>
                  )}
                  <Text style={{ color: '#888', fontSize: 11 }}>
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
    </View>
  );
}
