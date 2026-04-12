import { Tabs } from 'expo-router';
import { MaterialCommunityIcons } from '@expo/vector-icons';

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarStyle: {
          backgroundColor: '#1f1f1f',
          borderTopColor: '#333333',
          borderTopWidth: 1,
        },
        tabBarActiveTintColor: '#1DB954',
        tabBarInactiveTintColor: '#888888',
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
      <Tabs.Screen
        name="index"
        options={{
          title: 'Discover',
          tabBarLabel: 'Discover',
          headerTitle: 'Transistor',
          tabBarIcon: ({ color }) => (
            <MaterialCommunityIcons name="compass" size={24} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="subscriptions"
        options={{
          title: 'Subscriptions',
          tabBarLabel: 'Subscriptions',
          headerTitle: 'Your Podcasts',
          tabBarIcon: ({ color }) => (
            <MaterialCommunityIcons name="bookmark" size={24} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="search"
        options={{
          title: 'Search',
          tabBarLabel: 'Search',
          headerTitle: 'Search Episodes',
          tabBarIcon: ({ color }) => (
            <MaterialCommunityIcons name="magnify" size={24} color={color} />
          ),
        }}
      />
    </Tabs>
  );
}
