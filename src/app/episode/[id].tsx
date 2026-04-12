import React, { useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  Pressable,
  Image,
  Linking,
  Alert,
} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { usePodcastStore } from '@/store/podcastStore';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { formatDistanceToNow } from 'date-fns';

export default function EpisodeDetailScreen() {
  const route = useRoute();
  const router = useRouter();

  const { feeds, currentEpisodes, searchResults } = usePodcastStore();

  const episodeId = (route.params?.id as string) || '';

  // Find episode from either current feed or search results
  const episode = currentEpisodes.find((e) => e.id === episodeId) ||
    searchResults.find((e) => e.id === episodeId);

  const feedData = feeds.find((f) => f.id === episode?.feedId);

  const handleOpenAudio = async () => {
    if (!episode?.audioUrl) {
      Alert.alert('Error', 'No audio URL available');
      return;
    }

    try {
      const supported = await Linking.canOpenURL(episode.audioUrl);
      if (supported) {
        await Linking.openURL(episode.audioUrl);
      } else {
        Alert.alert('Error', 'Cannot open this URL');
      }
    } catch (error) {
      Alert.alert('Error', 'Failed to open audio');
    }
  };

  const handleOpenPodcast = () => {
    if (episode?.feedId) {
      router.push(`/feed/${episode.feedId}`);
    }
  };

  if (!episode) {
    return (
      <View style={{ flex: 1, backgroundColor: '#121212', justifyContent: 'center', alignItems: 'center' }}>
        <Text style={{ color: '#888' }}>Episode not found</Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: '#121212' }}
      contentContainerStyle={{ paddingBottom: 30 }}
    >
      {episode.imageUrl && (
        <Image
          source={{ uri: episode.imageUrl }}
          style={{
            width: '100%',
            height: 300,
          }}
        />
      )}

      <View style={{ padding: 20 }}>
        <Pressable
          onPress={handleOpenPodcast}
          style={{
            flexDirection: 'row',
            alignItems: 'center',
            gap: 10,
            marginBottom: 20,
          }}
        >
          {feedData?.imageUrl && (
            <Image
              source={{ uri: feedData.imageUrl }}
              style={{ width: 50, height: 50, borderRadius: 6 }}
            />
          )}
          <View>
            <Text style={{ color: '#1DB954', fontSize: 12, fontWeight: '600' }}>
              PODCAST
            </Text>
            <Text
              style={{
                color: '#fff',
                fontSize: 14,
                fontWeight: 'bold',
              }}
            >
              {feedData?.title || 'Unknown Podcast'}
            </Text>
          </View>
        </Pressable>

        <Text
          style={{
            color: '#fff',
            fontSize: 22,
            fontWeight: 'bold',
            marginBottom: 12,
            lineHeight: 28,
          }}
        >
          {episode.title}
        </Text>

        <View style={{ flexDirection: 'row', gap: 15, marginBottom: 20 }}>
          {episode.duration && (
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
              <MaterialCommunityIcons name="clock-outline" size={16} color="#888" />
              <Text style={{ color: '#888', fontSize: 12 }}>
                {Math.floor(episode.duration / 60)} min
              </Text>
            </View>
          )}
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
            <MaterialCommunityIcons name="calendar-outline" size={16} color="#888" />
            <Text style={{ color: '#888', fontSize: 12 }}>
              {formatDistanceToNow(episode.pubDate, { addSuffix: true })}
            </Text>
          </View>
        </View>

        {episode.guests && episode.guests.length > 0 && (
          <View style={{ marginBottom: 20 }}>
            <Text style={{ color: '#1DB954', fontSize: 12, fontWeight: '600', marginBottom: 8 }}>
              GUESTS
            </Text>
            <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
              {episode.guests.map((guest, index) => (
                <View
                  key={index}
                  style={{
                    backgroundColor: '#333',
                    paddingHorizontal: 12,
                    paddingVertical: 6,
                    borderRadius: 16,
                  }}
                >
                  <Text style={{ color: '#fff', fontSize: 12 }}>{guest}</Text>
                </View>
              ))}
            </View>
          </View>
        )}

        {episode.tags && episode.tags.length > 0 && (
          <View style={{ marginBottom: 20 }}>
            <Text style={{ color: '#1DB954', fontSize: 12, fontWeight: '600', marginBottom: 8 }}>
              TOPICS
            </Text>
            <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
              {episode.tags.map((tag, index) => (
                <View
                  key={index}
                  style={{
                    backgroundColor: '#1f1f1f',
                    paddingHorizontal: 12,
                    paddingVertical: 6,
                    borderRadius: 16,
                    borderWidth: 1,
                    borderColor: '#333',
                  }}
                >
                  <Text style={{ color: '#bbb', fontSize: 12 }}>{tag}</Text>
                </View>
              ))}
            </View>
          </View>
        )}

        <Pressable
          onPress={handleOpenAudio}
          style={{
            backgroundColor: '#1DB954',
            paddingVertical: 16,
            borderRadius: 8,
            alignItems: 'center',
            flexDirection: 'row',
            justifyContent: 'center',
            gap: 10,
            marginBottom: 20,
          }}
        >
          <MaterialCommunityIcons name="play" size={20} color="#fff" />
          <Text style={{ color: '#fff', fontSize: 16, fontWeight: 'bold' }}>
            Play Episode
          </Text>
        </Pressable>

        {(episode.description || episode.content) && (
          <View>
            <Text style={{ color: '#1DB954', fontSize: 12, fontWeight: '600', marginBottom: 12 }}>
              DESCRIPTION
            </Text>
            <Text
              style={{
                color: '#bbb',
                fontSize: 14,
                lineHeight: 20,
              }}
            >
              {(episode.content || episode.description)?.substring(0, 500)}
              {((episode.content || episode.description)?.length || 0) > 500 ? '...' : ''}
            </Text>
          </View>
        )}
      </View>
    </ScrollView>
  );
}
