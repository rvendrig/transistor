# Transistor 📻

A beautiful, fast podcast and radio program navigation app for iOS and Android.

## Features

- 🎙️ **Browse Podcasts** - Add and manage your favorite podcasts via RSS feeds
- 📻 **NPO Integration** - Browse all Netherlands Public Broadcasting (NPO) radio programs
- 🔍 **Search & Filter** - Find episodes by title, guest, topics, and more
- 🎯 **Smart Organization** - Filter by subject, guest, music, news, series
- ⏱️ **Episode Management** - Browse episodes with duration and publish date
- 👥 **Presenter & Guest Info** - See who hosts and who's being interviewed
- 🎵 **Music Tracking** - View songs played during radio broadcasts
- ❤️ **Favorites** - Save your favorite broadcasts and episodes
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

### Explore NPO Radio Programs

1. Go to the **NPO** tab
2. Select a radio channel (Radio 1, 2, 4, 5, or 6)
3. Browse available programs
4. Tap a program to see recent broadcasts
5. View full broadcast details with:
   - Presenters and guests
   - Topics discussed
   - Music played
   - Duration and schedule

### Add Custom Podcast Feeds

1. Tap the "+" button on the Discover tab or open Add Feed screen
2. Paste your podcast's RSS feed URL
3. The app will fetch and display all episodes

### Find Feed URLs

Most podcasts have an RSS feed available:
- Visit the podcast's website
- Look for "RSS", "Subscribe", or a podcast icon
- Copy the feed URL and add it to Transistor

### Search Episodes

1. Go to the **Search** tab
2. Type keywords (minimum 3 characters)
3. Results will show episodes from subscribed podcasts

### Manage Subscriptions

- **Subscribe**: Tap "Subscribe" on a podcast detail page
- **Unsubscribe**: Tap the bookmark icon on subscribed podcasts
- **Refresh**: Pull to refresh to get latest episodes

### Save Favorites

- Tap the heart icon on any NPO broadcast to save it
- Access your favorite broadcasts from the Favorites section

## Database

The app uses SQLite for local storage:

### Custom Podcasts
- **Feeds** - Podcast metadata (title, description, image, etc.)
- **Episodes** - Individual episodes with audio URLs
- **Subscriptions** - Tracks which podcasts you're subscribed to

### NPO Radio Programs
- **Channels** - NPO radio channels (Radio 1-6)
- **Programs** - Radio shows with presenters and genres
- **Broadcasts** - Individual broadcast episodes with full metadata
- **Favorites** - User's favorite NPO broadcasts

Data is stored locally on your device for offline access.

## NPO Radio Channels

**Transistor** provides full access to all major NPO radio channels:

| Channel | Description | Focus |
|---------|-------------|-------|
| **NPO Radio 1** | News and culture | Current affairs, interviews, documentaries |
| **NPO Radio 2** | Pop and rock | Music, nostalgia, entertainment |
| **NPO Radio 4** | Classical music | Classical, opera, orchestral music |
| **NPO Radio 5** | World music | International music, world cultures |
| **NPO Radio 6** | Jazz | Jazz, blues, improvisation |

Each channel offers:
- Browse all available programs
- View presenter information
- See guest appearances
- Track music played during broadcasts
- Check broadcast schedules
- Save favorite broadcasts

## Current Features

### NPO Integration
- ✅ Browse all NPO radio channels
- ✅ View program schedules and details
- ✅ See presenter and guest information
- ✅ Track music played during broadcasts
- ✅ Search across all NPO content
- ✅ Save favorite broadcasts

### Custom Podcasts
- ✅ Add podcasts via RSS feed URLs
- ✅ Search episodes by keyword
- ✅ Subscribe/unsubscribe management
- ✅ Guest and topic extraction
- ✅ Pull-to-refresh for updates

## Features in Development

- [ ] Audio playback with playback position tracking
- [ ] User accounts and cloud sync
- [ ] Curated podcast recommendations
- [ ] Podcast discovery with categories
- [ ] Custom feed playlists
- [ ] Export/Import subscriptions
- [ ] Offline episode downloads
- [ ] Listening history and recommendations

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
