import React, { useEffect } from 'react';
import {
  View,
  Text,
  FlatList,
  Pressable,
  Image,
  ScrollView,
} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { useNPOStore } from '@/store/npoStore';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';

const ITEM_TYPE_ICONS = {
  interview: 'microphone',
  music: 'music',
  news: 'newspaper',
  report: 'file-document',
  segment: 'bookmark',
  topic: 'tag',
};

const ITEM_TYPE_COLORS = {
  interview: '#1DB954',
  music: '#FF6B9D',
  news: '#4169E1',
  report: '#FF8C00',
  segment: '#9370DB',
  topic: '#20B2AA',
};

function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
}

export default function BroadcastItemsScreen() {
  const route = useRoute();
  const router = useRouter();

  const { currentItems, currentBroadcasts, isLoading, loadBroadcastItems } = useNPOStore();

  const broadcastId = (route.params?.broadcastId as string) || '';
  const broadcast = currentBroadcasts.find((b) => b.id === broadcastId);

  useEffect(() => {
    if (broadcastId) {
      loadBroadcastItems(broadcastId).catch((error) => {
        console.error('Error loading items:', error);
      });
    }
  }, [broadcastId]);

  if (!broadcast) {
    return (
      <View style={{ flex: 1, backgroundColor: '#121212', justifyContent: 'center', alignItems: 'center' }}>
        <Text style={{ color: '#888' }}>Uitzending niet gevonden</Text>
      </View>
    );
  }

  if (isLoading && currentItems.length === 0) {
    return (
      <View style={{ flex: 1, backgroundColor: '#121212', justifyContent: 'center', alignItems: 'center' }}>
        <MaterialCommunityIcons name="loading" size={40} color="#1DB954" />
        <Text style={{ color: '#888', marginTop: 15 }}>Onderdelen laden...</Text>
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: '#121212' }}>
      <FlatList
        data={currentItems}
        keyExtractor={(item) => item.id}
        ListHeaderComponent={() => (
          <View style={{ backgroundColor: '#1f1f1f', padding: 15 }}>
            <Text
              style={{
                color: '#fff',
                fontSize: 20,
                fontWeight: 'bold',
                marginBottom: 8,
              }}
            >
              Onderdelen van de uitzending
            </Text>

            <Text
              style={{
                color: '#bbb',
                fontSize: 13,
                marginBottom: 15,
                lineHeight: 18,
              }}
            >
              {broadcast.title}
            </Text>

            <View
              style={{
                backgroundColor: '#333',
                borderRadius: 8,
                padding: 12,
                marginBottom: 15,
              }}
            >
              <Text style={{ color: '#1DB954', fontSize: 11, fontWeight: '600' }}>
                TOTAAL ONDERDELEN: {currentItems.length}
              </Text>
              <Text
                style={{
                  color: '#bbb',
                  fontSize: 12,
                  marginTop: 8,
                  lineHeight: 16,
                }}
              >
                Deze uitzending bevat {currentItems.length} onderdelen, elk met eigen onderwerpen en sprekers.
              </Text>
            </View>
          </View>
        )}
        renderItem={({ item, index }) => (
          <View
            style={{
              padding: 15,
              borderBottomColor: '#222',
              borderBottomWidth: 1,
            }}
          >
            {/* Item number and type */}
            <View
              style={{
                flexDirection: 'row',
                alignItems: 'center',
                gap: 10,
                marginBottom: 10,
              }}
            >
              <View
                style={{
                  width: 32,
                  height: 32,
                  borderRadius: 16,
                  backgroundColor: ITEM_TYPE_COLORS[item.type as keyof typeof ITEM_TYPE_COLORS],
                  justifyContent: 'center',
                  alignItems: 'center',
                }}
              >
                <MaterialCommunityIcons
                  name={ITEM_TYPE_ICONS[item.type as keyof typeof ITEM_TYPE_ICONS] || 'bookmark'}
                  size={16}
                  color="#fff"
                />
              </View>
              <Text
                style={{
                  color: '#1DB954',
                  fontSize: 11,
                  fontWeight: '600',
                  flex: 1,
                }}
              >
                {item.type.toUpperCase()} • ONDERDEEL {index + 1}
              </Text>
              <View
                style={{
                  backgroundColor: '#333',
                  paddingHorizontal: 8,
                  paddingVertical: 4,
                  borderRadius: 4,
                }}
              >
                <Text style={{ color: '#fff', fontSize: 11, fontWeight: '600' }}>
                  {formatTime(item.startTime)} - {formatTime(item.startTime + item.duration)}
                </Text>
              </View>
            </View>

            {/* Title */}
            <Text
              style={{
                color: '#fff',
                fontSize: 15,
                fontWeight: 'bold',
                marginBottom: 8,
              }}
            >
              {item.title}
            </Text>

            {/* Image if available */}
            {item.imageUrl && (
              <Image
                source={{ uri: item.imageUrl }}
                style={{
                  width: '100%',
                  height: 120,
                  borderRadius: 8,
                  marginBottom: 10,
                  backgroundColor: '#333',
                }}
              />
            )}

            {/* Description */}
            {item.description && (
              <Text
                style={{
                  color: '#bbb',
                  fontSize: 12,
                  lineHeight: 16,
                  marginBottom: 10,
                }}
              >
                {item.description}
              </Text>
            )}

            {/* Teaser text */}
            {item.teaserText && (
              <View
                style={{
                  backgroundColor: 'rgba(29, 185, 84, 0.1)',
                  paddingHorizontal: 10,
                  paddingVertical: 8,
                  borderLeftWidth: 3,
                  borderLeftColor: '#1DB954',
                  marginBottom: 10,
                  borderRadius: 4,
                }}
              >
                <Text
                  style={{
                    color: '#1DB954',
                    fontSize: 12,
                    fontStyle: 'italic',
                  }}
                >
                  "{item.teaserText}"
                </Text>
              </View>
            )}

            {/* Duration */}
            <View
              style={{
                flexDirection: 'row',
                alignItems: 'center',
                gap: 8,
                marginBottom: 10,
              }}
            >
              <MaterialCommunityIcons name="clock" size={14} color="#888" />
              <Text style={{ color: '#888', fontSize: 11 }}>
                {Math.floor(item.duration / 60)} minuten {(item.duration % 60) > 0 ? `${item.duration % 60}s` : ''}
              </Text>
            </View>

            {/* Guests */}
            {item.guests && item.guests.length > 0 && (
              <View style={{ marginBottom: 10 }}>
                <Text style={{ color: '#1DB954', fontSize: 10, fontWeight: '600', marginBottom: 6 }}>
                  SPREKERS
                </Text>
                <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 6 }}>
                  {item.guests.map((guest, guestIndex) => (
                    <View
                      key={guestIndex}
                      style={{
                        backgroundColor: '#333',
                        paddingHorizontal: 10,
                        paddingVertical: 4,
                        borderRadius: 4,
                      }}
                    >
                      <Text style={{ color: '#fff', fontSize: 10 }}>{guest}</Text>
                    </View>
                  ))}
                </View>
              </View>
            )}

            {/* Topics/Tags */}
            {item.topics && item.topics.length > 0 && (
              <View style={{ marginBottom: 10 }}>
                <Text style={{ color: '#1DB954', fontSize: 10, fontWeight: '600', marginBottom: 6 }}>
                  ONDERWERPEN
                </Text>
                <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 6 }}>
                  {item.topics.map((topic, topicIndex) => (
                    <View
                      key={topicIndex}
                      style={{
                        backgroundColor: 'rgba(29, 185, 84, 0.15)',
                        paddingHorizontal: 8,
                        paddingVertical: 3,
                        borderRadius: 3,
                        borderWidth: 1,
                        borderColor: '#1DB954',
                      }}
                    >
                      <Text style={{ color: '#1DB954', fontSize: 9 }}>{topic}</Text>
                    </View>
                  ))}
                </View>
              </View>
            )}

            {/* Music info */}
            {item.type === 'music' && (item.musicTitle || item.artist) && (
              <View
                style={{
                  backgroundColor: '#1f1f1f',
                  padding: 10,
                  borderRadius: 6,
                  borderLeftWidth: 3,
                  borderLeftColor: '#FF6B9D',
                }}
              >
                {item.musicTitle && (
                  <Text style={{ color: '#fff', fontSize: 12, fontWeight: '600' }}>
                    {item.musicTitle}
                  </Text>
                )}
                {item.artist && (
                  <Text style={{ color: '#bbb', fontSize: 11, marginTop: 2 }}>
                    van {item.artist}
                  </Text>
                )}
              </View>
            )}
          </View>
        )}
        scrollEnabled
        nestedScrollEnabled
      />
    </View>
  );
}
