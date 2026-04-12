import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  FlatList,
  Pressable,
  RefreshControl,
  ScrollView,
  Dimensions,
  Image,
} from 'react-native';
import { useNPOStore } from '@/store/npoStore';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { formatDistanceToNow } from 'date-fns';
import { nl } from 'date-fns/locale';

const { width } = Dimensions.get('window');
const CHANNEL_WIDTH = (width - 30) / 2;

export default function NPOScreen() {
  const router = useRouter();
  const [refreshing, setRefreshing] = useState(false);

  const {
    channels,
    programs,
    selectedChannel,
    isLoading,
    isFetching,
    initializeNPO,
    selectChannel,
    loadPrograms,
  } = useNPOStore();

  useEffect(() => {
    initializeNPO().catch((error) => {
      console.error('Failed to initialize NPO:', error);
    });
  }, []);

  const handleChannelPress = async (channelId: string) => {
    try {
      await selectChannel(channelId);
    } catch (error) {
      console.error('Error selecting channel:', error);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    try {
      if (selectedChannel) {
        await loadPrograms(selectedChannel);
      }
    } finally {
      setRefreshing(false);
    }
  };

  const getChannelColor = (channelId: string) => {
    const colors: Record<string, string> = {
      radio1: '#004B87',
      radio2: '#E31E24',
      radio4: '#007934',
      radio5: '#9E1B32',
      radio6: '#007AFF',
    };
    return colors[channelId] || '#333';
  };

  if (isLoading && !selectedChannel) {
    return (
      <View style={{ flex: 1, backgroundColor: '#121212', justifyContent: 'center', alignItems: 'center' }}>
        <MaterialCommunityIcons name="radio-tower" size={60} color="#1DB954" />
        <Text style={{ color: '#fff', marginTop: 15, fontSize: 16 }}>
          NPO laden...
        </Text>
      </View>
    );
  }

  if (!selectedChannel) {
    return (
      <View style={{ flex: 1, backgroundColor: '#121212' }}>
        <View style={{ padding: 15 }}>
          <Text style={{ color: '#bbb', fontSize: 12, marginBottom: 15, fontWeight: '600' }}>
            KIES EEN ZENDER
          </Text>
        </View>
        <FlatList
          data={channels}
          keyExtractor={(item) => item.id}
          numColumns={2}
          columnWrapperStyle={{ gap: 15, paddingHorizontal: 15, marginBottom: 15 }}
          renderItem={({ item }) => (
            <Pressable
              onPress={() => handleChannelPress(item.id)}
              style={{
                width: CHANNEL_WIDTH,
                backgroundColor: getChannelColor(item.id),
                borderRadius: 12,
                padding: 15,
                justifyContent: 'flex-end',
                minHeight: 120,
              }}
            >
              <Text
                style={{
                  color: '#fff',
                  fontSize: 16,
                  fontWeight: 'bold',
                  marginBottom: 6,
                }}
              >
                {item.name}
              </Text>
              <Text style={{ color: 'rgba(255,255,255,0.8)', fontSize: 12 }}>
                {item.description}
              </Text>
            </Pressable>
          )}
          scrollEnabled
          nestedScrollEnabled
        />
      </View>
    );
  }

  const selectedChannelData = channels.find((c) => c.id === selectedChannel);

  return (
    <View style={{ flex: 1, backgroundColor: '#121212' }}>
      <FlatList
        data={programs}
        keyExtractor={(item) => item.id}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />}
        ListHeaderComponent={() => (
          <View style={{ backgroundColor: '#1f1f1f', padding: 15 }}>
            <Pressable
              onPress={() => useNPOStore.setState({ selectedChannel: null })}
              style={{
                flexDirection: 'row',
                alignItems: 'center',
                gap: 10,
                marginBottom: 20,
              }}
            >
              <View
                style={{
                  width: 60,
                  height: 60,
                  borderRadius: 30,
                  backgroundColor: getChannelColor(selectedChannel),
                  justifyContent: 'center',
                  alignItems: 'center',
                }}
              >
                <MaterialCommunityIcons name="radio" size={32} color="#fff" />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={{ color: '#1DB954', fontSize: 11, fontWeight: '600' }}>
                  HUIDIGE ZENDER
                </Text>
                <Text
                  style={{
                    color: '#fff',
                    fontSize: 18,
                    fontWeight: 'bold',
                  }}
                >
                  {selectedChannelData?.name}
                </Text>
              </View>
              <MaterialCommunityIcons name="chevron-right" size={24} color="#888" />
            </Pressable>

            <View style={{ paddingTop: 20, borderTopWidth: 1, borderTopColor: '#333' }}>
              <Text style={{ color: '#1DB954', fontSize: 13, fontWeight: 'bold', marginBottom: 15 }}>
                PROGRAMMA'S
              </Text>
            </View>
          </View>
        )}
        renderItem={({ item }) => (
          <Pressable
            onPress={() => router.push(`/npo/program/${item.id}`)}
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
                  style={{ width: 80, height: 80, borderRadius: 8, backgroundColor: '#333' }}
                />
              )}
              <View style={{ flex: 1, justifyContent: 'space-between' }}>
                <View>
                  <Text
                    style={{
                      color: '#fff',
                      fontSize: 15,
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
                      lineHeight: 16,
                    }}
                    numberOfLines={2}
                  >
                    {item.description}
                  </Text>
                </View>
                {item.presenters && item.presenters.length > 0 && (
                  <Text style={{ color: '#888', fontSize: 11, marginTop: 8 }}>
                    Presentator: {item.presenters.join(', ')}
                  </Text>
                )}
              </View>
            </View>
          </Pressable>
        )}
        scrollEnabled
        nestedScrollEnabled
      />

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
            <Text style={{ color: '#fff', fontSize: 12 }}>Programma's laden...</Text>
          </View>
        </View>
      )}
    </View>
  );
}
