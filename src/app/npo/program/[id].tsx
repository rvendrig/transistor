import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  Pressable,
  Image,
  RefreshControl,
  ScrollView,
  Alert,
} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { useNPOStore } from '@/store/npoStore';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { formatDistanceToNow, format } from 'date-fns';
import { nl } from 'date-fns/locale';

export default function NPOProgramScreen() {
  const route = useRoute();
  const router = useRouter();
  const [refreshing, setRefreshing] = useState(false);

  const {
    programs,
    currentProgram,
    currentBroadcasts,
    selectProgram,
    refreshBroadcasts,
  } = useNPOStore();

  const programId = (route.params?.id as string) || '';

  useEffect(() => {
    if (programId) {
      const program = programs.find((p) => p.id === programId);
      if (program) {
        selectProgram(program).catch((error) => {
          console.error('Error selecting program:', error);
        });
      }
    }
  }, [programId]);

  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      if (programId) {
        await refreshBroadcasts(programId);
      }
    } finally {
      setRefreshing(false);
    }
  };

  if (!currentProgram) {
    return (
      <View style={{ flex: 1, backgroundColor: '#121212', justifyContent: 'center', alignItems: 'center' }}>
        <Text style={{ color: '#888' }}>Programma laden...</Text>
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: '#121212' }}>
      <FlatList
        data={currentBroadcasts}
        keyExtractor={(item) => item.id}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />}
        ListHeaderComponent={() => (
          <View style={{ backgroundColor: '#1f1f1f', padding: 15 }}>
            {currentProgram.image && (
              <Image
                source={{ uri: currentProgram.image }}
                style={{
                  width: '100%',
                  height: 200,
                  borderRadius: 12,
                  marginBottom: 20,
                  backgroundColor: '#333',
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
              {currentProgram.title}
            </Text>

            <Text
              style={{
                color: '#1DB954',
                fontSize: 12,
                fontWeight: '600',
                marginBottom: 10,
              }}
            >
              {currentProgram.broadcaster.name}
            </Text>

            <Text
              style={{
                color: '#bbb',
                fontSize: 13,
                marginBottom: 15,
                lineHeight: 18,
              }}
            >
              {currentProgram.description}
            </Text>

            {currentProgram.presenters && currentProgram.presenters.length > 0 && (
              <View style={{ marginBottom: 15 }}>
                <Text style={{ color: '#1DB954', fontSize: 11, fontWeight: '600', marginBottom: 8 }}>
                  PRESENTATOREN
                </Text>
                <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
                  {currentProgram.presenters.map((presenter, index) => (
                    <View
                      key={index}
                      style={{
                        backgroundColor: '#333',
                        paddingHorizontal: 12,
                        paddingVertical: 6,
                        borderRadius: 16,
                      }}
                    >
                      <Text style={{ color: '#fff', fontSize: 12 }}>{presenter}</Text>
                    </View>
                  ))}
                </View>
              </View>
            )}

            {currentProgram.genre && currentProgram.genre.length > 0 && (
              <View style={{ marginBottom: 20 }}>
                <Text style={{ color: '#1DB954', fontSize: 11, fontWeight: '600', marginBottom: 8 }}>
                  GENRE
                </Text>
                <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
                  {currentProgram.genre.map((genre, index) => (
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
                      <Text style={{ color: '#bbb', fontSize: 12 }}>{genre}</Text>
                    </View>
                  ))}
                </View>
              </View>
            )}

            <View style={{ paddingTop: 20, borderTopWidth: 1, borderTopColor: '#333' }}>
              <Text style={{ color: '#1DB954', fontSize: 13, fontWeight: 'bold', marginBottom: 15 }}>
                RECENTE UITZENDINGEN ({currentBroadcasts.length})
              </Text>
            </View>
          </View>
        )}
        renderItem={({ item }) => (
          <Pressable
            onPress={() => router.push(`/npo/broadcast/${item.id}`)}
            style={{
              padding: 15,
              borderBottomColor: '#222',
              borderBottomWidth: 1,
            }}
          >
            <View style={{ flexDirection: 'row', gap: 12 }}>
              {item.image && (
                <Image
                  source={{ uri: item.image }}
                  style={{ width: 70, height: 70, borderRadius: 6, backgroundColor: '#333' }}
                />
              )}
              <View style={{ flex: 1 }}>
                <Text
                  style={{
                    color: '#fff',
                    fontSize: 13,
                    fontWeight: 'bold',
                    marginBottom: 6,
                  }}
                  numberOfLines={2}
                >
                  {item.title}
                </Text>

                <View style={{ flexDirection: 'row', gap: 8, alignItems: 'center', marginBottom: 6 }}>
                  {item.duration && (
                    <View
                      style={{
                        backgroundColor: '#333',
                        paddingHorizontal: 8,
                        paddingVertical: 2,
                        borderRadius: 4,
                      }}
                    >
                      <Text style={{ color: '#1DB954', fontSize: 10, fontWeight: '600' }}>
                        {Math.floor(item.duration / 60)} min
                      </Text>
                    </View>
                  )}
                  <Text style={{ color: '#888', fontSize: 11 }}>
                    {format(item.startTime, 'd MMM yyyy HH:mm', { locale: nl })}
                  </Text>
                </View>

                {item.presenters && item.presenters.length > 0 && (
                  <Text style={{ color: '#888', fontSize: 10 }}>
                    {item.presenters.map((p) => p.name).join(', ')}
                  </Text>
                )}

                {item.topics && item.topics.length > 0 && (
                  <View style={{ flexDirection: 'row', gap: 4, flexWrap: 'wrap', marginTop: 6 }}>
                    {item.topics.slice(0, 2).map((topic, index) => (
                      <View
                        key={index}
                        style={{
                          backgroundColor: '#1DB954',
                          paddingHorizontal: 6,
                          paddingVertical: 2,
                          borderRadius: 3,
                        }}
                      >
                        <Text style={{ color: '#fff', fontSize: 9, fontWeight: '600' }}>
                          {topic}
                        </Text>
                      </View>
                    ))}
                  </View>
                )}
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
