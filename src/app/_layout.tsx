import { useEffect } from 'react';
import { Stack } from 'expo-router';
import { usePodcastStore } from '@/store/podcastStore';

export default function RootLayout() {
  const initializeDatabase = usePodcastStore((state) => state.initializeDatabase);

  useEffect(() => {
    initializeDatabase().catch((error) => {
      console.error('Failed to initialize app:', error);
    });
  }, []);

  return (
    <Stack
      screenOptions={{
        headerShown: true,
        headerStyle: {
          backgroundColor: '#1f1f1f',
        },
        headerTintColor: '#fff',
        headerTitleStyle: {
          fontWeight: 'bold',
          fontSize: 20,
        },
        contentStyle: {
          backgroundColor: '#121212',
        },
      }}
    >
      <Stack.Screen
        name="(tabs)"
        options={{
          headerShown: false,
        }}
      />
      <Stack.Screen
        name="feed/[id]"
        options={{
          title: 'Podcast',
          headerShown: true,
        }}
      />
      <Stack.Screen
        name="episode/[id]"
        options={{
          title: 'Episode',
          headerShown: true,
        }}
      />
      <Stack.Screen
        name="add-feed"
        options={{
          title: 'Add Feed',
          headerShown: true,
          presentation: 'modal',
        }}
      />
    </Stack>
  );
}
