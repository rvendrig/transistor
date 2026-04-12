# Transistor 📻

A beautiful, fast podcast and radio program navigation app for iOS and Android.

## Features

- 🎙️ **Browse Podcasts** - Add and manage your favorite podcasts via RSS feeds
- 🔍 **Search & Filter** - Find episodes by title, guest, topics, and more
- 🎯 **Smart Organization** - Filter by subject, guest, music, news, series
- ⏱️ **Episode Management** - Browse episodes with duration and publish date
- 📱 **Cross-Platform** - Works on iOS and Android with the same codebase
- 🎨 **Beautiful UI** - Dark theme optimized for audio consumption

## Tech Stack

- **React Native** with Expo for cross-platform development
- **TypeScript** for type-safe code
- **SQLite** (expo-sqlite) for local episode storage
- **Zustand** for state management
- **Expo Router** for navigation
- **xml2js** for RSS feed parsing

## Getting Started

### Prerequisites

- Node.js (v18 or higher)
- npm or yarn
- Expo CLI (`npm install -g expo-cli`)

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd transistor

# Install dependencies
npm install

# Start the development server
npm start

# For iOS
npm run ios

# For Android
npm run android

# For Web
npm run web
```

## Project Structure

```
src/
├── app/                      # Expo Router app structure
│   ├── (tabs)/              # Main tabbed navigation
│   │   ├── index.tsx        # Discover/Home screen
│   │   ├── subscriptions.tsx # Subscriptions screen
│   │   └── search.tsx       # Search screen
│   ├── feed/[id].tsx        # Podcast detail screen
│   ├── episode/[id].tsx     # Episode detail screen
│   ├── add-feed.tsx         # Add new feed modal
│   └── _layout.tsx          # Root layout
├── services/
│   ├── database.ts          # SQLite database operations
│   └── rssParser.ts         # RSS/Atom feed parser
├── store/
│   └── podcastStore.ts      # Zustand state management
└── types.ts                 # TypeScript interfaces
```

## How to Use

### Add a Podcast

1. Tap the "+" button on the Discover tab or open Add Feed screen
2. Paste your podcast's RSS feed URL
3. The app will fetch and display all episodes

### Find Feed URLs

Most podcasts have an RSS feed available:
- Visit the podcast's website
- Look for "RSS", "Subscribe", or a podcast icon
- Copy the feed URL and add it to Transistor

### Search Episodes

1. Go to the Search tab
2. Type keywords (minimum 3 characters)
3. Results will show episodes from subscribed podcasts

### Manage Subscriptions

- **Subscribe**: Tap "Subscribe" on a podcast detail page
- **Unsubscribe**: Tap the bookmark icon on subscribed podcasts
- **Refresh**: Pull to refresh to get latest episodes

## Database

The app uses SQLite for local storage:

- **Feeds** - Podcast metadata (title, description, image, etc.)
- **Episodes** - Individual episodes with audio URLs
- **Subscriptions** - Tracks which podcasts you're subscribed to

Data is stored locally on your device for offline access.

## Features in Development

- [ ] Audio playback with playback position tracking
- [ ] User accounts and cloud sync
- [ ] Curated podcast recommendations
- [ ] Podcast discovery with categories
- [ ] Custom feed playlists
- [ ] Export/Import subscriptions

## Contributing

This is a Claude Code assisted project. When working on new features:

1. Read the CLAUDE.md guide for development conventions
2. Create a feature branch with clear naming
3. Test thoroughly on both iOS and Android
4. Commit with descriptive messages

## License

MIT

## Support

For issues or questions, please check the troubleshooting section in CLAUDE.md or open an issue on GitHub.

---

**Built with Expo, React Native, and TypeScript**
