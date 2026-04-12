import { useEffect, useState } from 'react';
import { View, Text, ScrollView, RefreshControl, Pressable, Image, FlatList } from 'react-native';
import { usePodcastStore } from '@/store/podcastStore';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { formatDistanceToNow } from 'date-fns';

export default function DiscoverScreen() {
  const router = useRouter();
  const [refreshing, setRefreshing] = useState(false);

  const {
    episodes,
    isFetching,
    getRecentEpisodes,
    feeds,
  } = usePodcastStore();

  useEffect(() => {
    getRecentEpisodes(30).catch((error) => {
      console.error('Failed to load episodes:', error);
    });
  }, []);

  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      await getRecentEpisodes(30);
    } finally {
      setRefreshing(false);
    }
  };

  const getFeedTitle = (feedId: string) => {
    return feeds.find((f) => f.id === feedId)?.title || 'Unknown Podcast';
  };

  return (
    <View style={{ flex: 1, backgroundColor: '#121212' }}>
      {feeds.length === 0 ? (
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 }}>
          <MaterialCommunityIcons name="podcast" size={80} color="#1DB954" />
          <Text style={{ color: '#fff', fontSize: 20, fontWeight: 'bold', marginTop: 20 }}>
            Welcome to Transistor
          </Text>
          <Text
            style={{
              color: '#bbb',
              fontSize: 16,
              marginTop: 10,
              textAlign: 'center',
            }}
          >
            Add your first podcast feed to get started
          </Text>
          <Pressable
            onPress={() => router.push('/add-feed')}
            style={{
              marginTop: 30,
              backgroundColor: '#1DB954',
              paddingHorizontal: 30,
              paddingVertical: 12,
              borderRadius: 24,
              flexDirection: 'row',
              alignItems: 'center',
              gap: 10,
            }}
          >
            <MaterialCommunityIcons name="plus" size={20} color="#fff" />
            <Text style={{ color: '#fff', fontWeight: 'bold', fontSize: 16 }}>Add Feed</Text>
          </Pressable>
        </View>
      ) : (
        <FlatList
          data={episodes}
          keyExtractor={(item) => item.id}
          refreshControl={<RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />}
          ListHeaderComponent={() => (
            <View style={{ padding: 15 }}>
              <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
                <Text style={{ color: '#fff', fontSize: 18, fontWeight: 'bold' }}>
                  Recent Episodes
                </Text>
                <Pressable
                  onPress={() => router.push('/add-feed')}
                  style={{ padding: 8 }}
                >
                  <MaterialCommunityIcons name="plus" size={24} color="#1DB954" />
                </Pressable>
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

      {isFetching && (
        <View
          style={{
            position: 'absolute',
            bottom: 20,
            left: 0,
            right: 0,
            alignItems: 'center',
          }}
        >
          <View
            style={{
              backgroundColor: '#333',
              paddingHorizontal: 15,
              paddingVertical: 8,
              borderRadius: 20,
            }}
          >
            <Text style={{ color: '#fff', fontSize: 12 }}>Fetching new episodes...</Text>
          </View>
        </View>
      )}
    </View>
  );
}
