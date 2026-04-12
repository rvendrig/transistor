import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  Pressable,
  Image,
  Linking,
  Alert,
  FlatList,
} from 'react-native';
import { useRoute } from '@react-navigation/native';
import { useNPOStore } from '@/store/npoStore';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { format } from 'date-fns';
import { nl } from 'date-fns/locale';

export default function NPOBroadcastScreen() {
  const route = useRoute();
  const router = useRouter();
  const [isFavorite, setIsFavorite] = useState(false);

  const {
    currentBroadcasts,
    favorites,
    addFavorite,
    removeFavorite,
    isFavoriteBroadcast,
  } = useNPOStore();

  const broadcastId = (route.params?.id as string) || '';
  const broadcast = currentBroadcasts.find((b) => b.id === broadcastId);

  useEffect(() => {
    if (broadcastId) {
      isFavoriteBroadcast(broadcastId).then(setIsFavorite);
    }
  }, [broadcastId]);

  const handleToggleFavorite = async () => {
    try {
      if (isFavorite) {
        await removeFavorite(broadcastId);
      } else if (broadcast) {
        await addFavorite(broadcast);
      }
      setIsFavorite(!isFavorite);
    } catch (error) {
      Alert.alert('Error', 'Failed to update favorite');
    }
  };

  const handleOpenAudio = async () => {
    if (!broadcast?.audioUrl) {
      Alert.alert('Info', 'Audio-URL is niet beschikbaar');
      return;
    }

    try {
      const supported = await Linking.canOpenURL(broadcast.audioUrl);
      if (supported) {
        await Linking.openURL(broadcast.audioUrl);
      } else {
        Alert.alert('Error', 'Kan deze URL niet openen');
      }
    } catch (error) {
      Alert.alert('Error', 'Fout bij openen van audio');
    }
  };

  if (!broadcast) {
    return (
      <View style={{ flex: 1, backgroundColor: '#121212', justifyContent: 'center', alignItems: 'center' }}>
        <Text style={{ color: '#888' }}>Uitzending niet gevonden</Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: '#121212' }}
      contentContainerStyle={{ paddingBottom: 30 }}
    >
      {broadcast.image && (
        <Image
          source={{ uri: broadcast.image }}
          style={{
            width: '100%',
            height: 300,
            backgroundColor: '#333',
          }}
        />
      )}

      <View style={{ padding: 20 }}>
        {/* Header info */}
        <View style={{ marginBottom: 20 }}>
          <Text
            style={{
              color: '#1DB954',
              fontSize: 11,
              fontWeight: '600',
              marginBottom: 8,
            }}
          >
            {broadcast.broadcaster.name}
          </Text>
          <Text
            style={{
              color: '#fff',
              fontSize: 24,
              fontWeight: 'bold',
              marginBottom: 12,
              lineHeight: 30,
            }}
          >
            {broadcast.title}
          </Text>

          <View style={{ flexDirection: 'row', gap: 10, alignItems: 'center' }}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
              <MaterialCommunityIcons name="calendar" size={14} color="#888" />
              <Text style={{ color: '#888', fontSize: 12 }}>
                {format(broadcast.startTime, 'd MMM yyyy', { locale: nl })}
              </Text>
            </View>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
              <MaterialCommunityIcons name="clock-outline" size={14} color="#888" />
              <Text style={{ color: '#888', fontSize: 12 }}>
                {format(broadcast.startTime, 'HH:mm', { locale: nl })} - {Math.floor(broadcast.duration / 60)} min
              </Text>
            </View>
          </View>
        </View>

        {/* Action buttons */}
        <View style={{ flexDirection: 'row', gap: 10, marginBottom: 20 }}>
          <Pressable
            onPress={handleOpenAudio}
            disabled={!broadcast.audioUrl}
            style={{
              flex: 1,
              backgroundColor: broadcast.audioUrl ? '#1DB954' : '#555',
              paddingVertical: 14,
              borderRadius: 8,
              alignItems: 'center',
              flexDirection: 'row',
              justifyContent: 'center',
              gap: 8,
            }}
          >
            <MaterialCommunityIcons name="play" size={18} color="#fff" />
            <Text style={{ color: '#fff', fontSize: 15, fontWeight: 'bold' }}>
              Afspelen
            </Text>
          </Pressable>

          <Pressable
            onPress={handleToggleFavorite}
            style={{
              paddingHorizontal: 16,
              paddingVertical: 14,
              borderRadius: 8,
              backgroundColor: isFavorite ? '#1DB954' : '#333',
              justifyContent: 'center',
              alignItems: 'center',
            }}
          >
            <MaterialCommunityIcons
              name={isFavorite ? 'heart' : 'heart-outline'}
              size={20}
              color={isFavorite ? '#fff' : '#1DB954'}
            />
          </Pressable>
        </View>

        {/* Items section */}
        <Pressable
          onPress={() => router.push(`/npo/broadcast-items/${broadcast.id}`)}
          style={{
            backgroundColor: '#1f1f1f',
            padding: 15,
            borderRadius: 8,
            marginBottom: 20,
            borderWidth: 1,
            borderColor: '#333',
          }}
        >
          <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
            <View style={{ flex: 1 }}>
              <Text style={{ color: '#1DB954', fontSize: 11, fontWeight: '600', marginBottom: 4 }}>
                ONDERDELEN VAN DE UITZENDING
              </Text>
              <Text style={{ color: '#fff', fontSize: 14, fontWeight: 'bold' }}>
                Bekijk alle segmenten
              </Text>
              <Text style={{ color: '#888', fontSize: 12, marginTop: 4 }}>
                Interviews, muziek, nieuws en reportages
              </Text>
            </View>
            <MaterialCommunityIcons name="chevron-right" size={24} color="#1DB954" />
          </View>
        </Pressable>

        {/* Description */}
        {broadcast.description && (
          <View style={{ marginBottom: 25 }}>
            <Text style={{ color: '#1DB954', fontSize: 11, fontWeight: '600', marginBottom: 10 }}>
              OMSCHRIJVING
            </Text>
            <Text
              style={{
                color: '#bbb',
                fontSize: 13,
                lineHeight: 18,
              }}
            >
              {broadcast.description}
            </Text>
          </View>
        )}

        {/* Presenters */}
        {broadcast.presenters && broadcast.presenters.length > 0 && (
          <View style={{ marginBottom: 25 }}>
            <Text style={{ color: '#1DB954', fontSize: 11, fontWeight: '600', marginBottom: 10 }}>
              PRESENTATOREN ({broadcast.presenters.length})
            </Text>
            <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
              {broadcast.presenters.map((presenter, index) => (
                <View
                  key={index}
                  style={{
                    backgroundColor: '#333',
                    paddingHorizontal: 12,
                    paddingVertical: 8,
                    borderRadius: 8,
                  }}
                >
                  <Text style={{ color: '#fff', fontSize: 12, fontWeight: '500' }}>
                    {presenter.name}
                  </Text>
                </View>
              ))}
            </View>
          </View>
        )}

        {/* Guests */}
        {broadcast.guests && broadcast.guests.length > 0 && (
          <View style={{ marginBottom: 25 }}>
            <Text style={{ color: '#1DB954', fontSize: 11, fontWeight: '600', marginBottom: 10 }}>
              GASTEN ({broadcast.guests.length})
            </Text>
            <View style={{ gap: 10 }}>
              {broadcast.guests.map((guest, index) => (
                <View
                  key={index}
                  style={{
                    backgroundColor: '#1f1f1f',
                    paddingHorizontal: 12,
                    paddingVertical: 10,
                    borderRadius: 8,
                    borderLeftWidth: 3,
                    borderLeftColor: '#1DB954',
                  }}
                >
                  <Text style={{ color: '#fff', fontSize: 13, fontWeight: '600' }}>
                    {guest.name}
                  </Text>
                  {guest.role && (
                    <Text style={{ color: '#888', fontSize: 11, marginTop: 4 }}>
                      {guest.role}
                      {guest.affiliation ? ` - ${guest.affiliation}` : ''}
                    </Text>
                  )}
                </View>
              ))}
            </View>
          </View>
        )}

        {/* Topics */}
        {broadcast.topics && broadcast.topics.length > 0 && (
          <View style={{ marginBottom: 25 }}>
            <Text style={{ color: '#1DB954', fontSize: 11, fontWeight: '600', marginBottom: 10 }}>
              ONDERWERPEN
            </Text>
            <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
              {broadcast.topics.map((topic, index) => (
                <View
                  key={index}
                  style={{
                    backgroundColor: 'rgba(29, 185, 84, 0.15)',
                    paddingHorizontal: 12,
                    paddingVertical: 6,
                    borderRadius: 16,
                    borderWidth: 1,
                    borderColor: '#1DB954',
                  }}
                >
                  <Text style={{ color: '#1DB954', fontSize: 12 }}>{topic}</Text>
                </View>
              ))}
            </View>
          </View>
        )}

        {/* Music played */}
        {broadcast.musicPlayed && broadcast.musicPlayed.length > 0 && (
          <View>
            <Text style={{ color: '#1DB954', fontSize: 11, fontWeight: '600', marginBottom: 10 }}>
              MUZIEK ({broadcast.musicPlayed.length})
            </Text>
            <FlatList
              data={broadcast.musicPlayed}
              keyExtractor={(item, index) => `music-${index}`}
              scrollEnabled={false}
              renderItem={({ item }) => (
                <View
                  style={{
                    paddingVertical: 10,
                    borderBottomColor: '#222',
                    borderBottomWidth: 1,
                  }}
                >
                  <Text style={{ color: '#fff', fontSize: 12, fontWeight: '600' }}>
                    {item.title}
                  </Text>
                  <Text style={{ color: '#888', fontSize: 11, marginTop: 4 }}>
                    {item.artist}
                  </Text>
                </View>
              )}
            />
          </View>
        )}
      </View>
    </ScrollView>
  );
}
