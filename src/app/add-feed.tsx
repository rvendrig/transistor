import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  Pressable,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { usePodcastStore } from '@/store/podcastStore';
import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';

export default function AddFeedScreen() {
  const router = useRouter();
  const [url, setUrl] = useState('');
  const { addFeed, isFetching, error } = usePodcastStore();

  const handleAddFeed = async () => {
    if (!url.trim()) {
      Alert.alert('Error', 'Please enter a feed URL');
      return;
    }

    try {
      await addFeed(url.trim());
      Alert.alert('Success', 'Feed added successfully!');
      setUrl('');
      router.back();
    } catch (err) {
      Alert.alert('Error', error || 'Failed to add feed. Please check the URL.');
    }
  };

  return (
    <View style={{ flex: 1, backgroundColor: '#121212' }}>
      <ScrollView
        contentContainerStyle={{ padding: 20 }}
        keyboardShouldPersistTaps="handled"
      >
        <Text
          style={{
            color: '#fff',
            fontSize: 24,
            fontWeight: 'bold',
            marginBottom: 10,
          }}
        >
          Add Podcast Feed
        </Text>

        <Text style={{ color: '#bbb', fontSize: 14, marginBottom: 20 }}>
          Enter the RSS feed URL of your favorite podcast
        </Text>

        <View
          style={{
            backgroundColor: '#1f1f1f',
            borderRadius: 12,
            paddingHorizontal: 15,
            paddingVertical: 12,
            marginBottom: 20,
            borderWidth: 1,
            borderColor: '#333',
          }}
        >
          <TextInput
            placeholder="https://example.com/feed.xml"
            placeholderTextColor="#666"
            value={url}
            onChangeText={setUrl}
            editable={!isFetching}
            style={{
              color: '#fff',
              fontSize: 14,
            }}
            autoCapitalize="none"
            autoCorrect={false}
          />
        </View>

        {error && (
          <View
            style={{
              backgroundColor: '#3f1010',
              borderRadius: 8,
              padding: 12,
              marginBottom: 20,
              flexDirection: 'row',
              gap: 10,
              alignItems: 'flex-start',
            }}
          >
            <MaterialCommunityIcons name="alert" size={20} color="#ff6b6b" />
            <Text
              style={{
                color: '#ff6b6b',
                fontSize: 12,
                flex: 1,
              }}
            >
              {error}
            </Text>
          </View>
        )}

        <Pressable
          onPress={handleAddFeed}
          disabled={isFetching || !url.trim()}
          style={{
            backgroundColor: isFetching || !url.trim() ? '#555' : '#1DB954',
            paddingVertical: 15,
            borderRadius: 8,
            alignItems: 'center',
            flexDirection: 'row',
            justifyContent: 'center',
            gap: 10,
            marginBottom: 15,
          }}
        >
          {isFetching ? (
            <ActivityIndicator color="#fff" />
          ) : (
            <MaterialCommunityIcons name="plus" size={20} color="#fff" />
          )}
          <Text
            style={{
              color: '#fff',
              fontSize: 16,
              fontWeight: 'bold',
            }}
          >
            {isFetching ? 'Adding Feed...' : 'Add Feed'}
          </Text>
        </Pressable>

        <View
          style={{
            backgroundColor: '#1f1f1f',
            borderRadius: 12,
            padding: 15,
            marginTop: 30,
          }}
        >
          <Text
            style={{
              color: '#1DB954',
              fontSize: 14,
              fontWeight: 'bold',
              marginBottom: 10,
            }}
          >
            Need a feed URL?
          </Text>
          <Text style={{ color: '#bbb', fontSize: 13, lineHeight: 20 }}>
            1. Visit your podcast's website{'\n'}
            2. Look for "RSS Feed" or subscribe button{'\n'}
            3. Copy the feed URL{'\n'}
            4. Paste it here
          </Text>
        </View>

        <View
          style={{
            backgroundColor: '#1f1f1f',
            borderRadius: 12,
            padding: 15,
            marginTop: 15,
          }}
        >
          <Text
            style={{
              color: '#1DB954',
              fontSize: 14,
              fontWeight: 'bold',
              marginBottom: 10,
            }}
          >
            Popular Podcasts
          </Text>
          <Text style={{ color: '#bbb', fontSize: 12 }}>
            {/* Example feeds could be added here */}
            Supported formats: RSS 2.0, Atom
          </Text>
        </View>
      </ScrollView>
    </View>
  );
}
