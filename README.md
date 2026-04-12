# Transistor 📻

A beautiful, fast podcast and radio program navigation app for iOS and Android.

## 🎯 Versions

**Transistor** now has two implementations:

### 1. **Native iOS** (Recommended) ⭐
Pure native SwiftUI app for iPhone with no external dependencies.
- **Location**: `/iOS/Transistor/`
- **Platform**: iOS 15+ (iPhone 12+)
- **Tech**: Swift, SwiftUI, SQLite3
- **Features**: Full offline support, fast, native feel
- **Setup**: 5 minutes in Xcode
- **Status**: ✅ Production Ready

👉 **[See iOS Setup Guide →](./iOS/README.md)**

### 2. **React Native / Expo** (Cross-Platform)
Web and cross-platform version using React Native.
- **Tech**: React Native, Expo, TypeScript
- **Platforms**: iOS, Android, Web
- **Note**: Expo is not recommended for production use

**Use the Native iOS version for best experience!**

## Features

- 🎙️ **Browse Podcasts** - Add and manage your favorite podcasts via RSS feeds
- 📻 **NPO Integration** - Browse all Netherlands Public Broadcasting (NPO) radio programs
- 🔍 **Search & Filter** - Find episodes by title, guest, topics, and more
- 🎯 **Smart Organization** - Filter by subject, guest, music, news, series
- ⏱️ **Episode Management** - Browse episodes with duration and publish date
- 👥 **Presenter & Guest Info** - See who hosts and who's being interviewed
- 🎵 **Music Tracking** - View songs played during radio broadcasts
- ❤️ **Favorites** - Save your favorite broadcasts and episodes
- 📱 **Cross-Platform** - Native iOS + Web support
- 🎨 **Beautiful UI** - Dark theme optimized for audio consumption

## Tech Stack (iOS)

- **Swift** native language
- **SwiftUI** modern UI framework
- **SQLite3** for local storage
- **Async/await** for async operations
- **MVVM** architecture pattern
- **Zero External Dependencies** - Built-in frameworks only

## Getting Started

### 🍎 For iOS (Native, Recommended)

See detailed setup instructions: **[iOS Setup Guide](./iOS/README.md)**

Quick start:
```bash
# Open Xcode
open -a Xcode iOS/Transistor

# In Xcode:
# 1. Select iPhone 15 Pro (or newer)
# 2. Press Cmd + R to build and run
```

**Requirements:**
- macOS 13.0+
- Xcode 15.0+
- iOS 15.0+ target

### 🌐 For Web / Cross-Platform (React Native + Expo)

**Prerequisites:**
- Node.js (v18 or higher)
- npm or yarn
- Expo CLI (`npm install -g expo-cli`)

**Installation:**
```bash
# Clone the repository
git clone <repo-url>
cd transistor

# Install dependencies
npm install

# Start the development server
npm start

# For iOS (Expo)
npm run ios

# For Android (Expo)
npm run android

# For Web
npm run web
```

⚠️ **Note**: Expo is not recommended for production. Use the native iOS version instead.

## Project Structure

```
src/
├── app/                           # Expo Router app structure
│   ├── (tabs)/                   # Main tabbed navigation
│   │   ├── index.tsx             # Discover/Home screen
│   │   ├── subscriptions.tsx      # Subscriptions screen
│   │   ├── search.tsx            # Search screen
│   │   └── npo.tsx               # NPO programs browser
│   ├── feed/[id].tsx             # Podcast detail screen
│   ├── episode/[id].tsx          # Episode detail screen
│   ├── add-feed.tsx              # Add new feed modal
│   ├── npo/
│   │   ├── program/[id].tsx      # Program broadcasts
│   │   ├── broadcast/[id].tsx    # Broadcast details
│   │   └── broadcast-items/[id]  # Broadcast segments
│   └── _layout.tsx               # Root layout
├── services/
│   ├── database.ts               # SQLite database operations
│   ├── rssParser.ts              # RSS/Atom feed parser
│   ├── npoAPI.ts                 # NPO API & mock data
│   ├── npoDatabase.ts            # NPO SQLite operations
│   └── database.ts               # Shared database setup
├── store/
│   ├── podcastStore.ts           # Zustand state for podcasts
│   └── npoStore.ts               # Zustand state for NPO
├── types/
│   ├── types.ts                  # Podcast TypeScript interfaces
│   └── npo.ts                    # NPO TypeScript interfaces
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

## Content Hierarchy

**Transistor** organizes content in a hierarchical structure:

### Podcasts
```
Channel/Podcast
├── Episode (with RSS metadata)
```

### NPO Radio Programs
```
Radio Channel (Radio 1-6, 3FM)
├── Program (Show with presenters)
│   └── Broadcast (Episode/Airing)
│       └── Item (Segment/Part)
│           ├── Interview
│           ├── Music
│           ├── News
│           ├── Report
│           └── Topic
```

Each **Item** is a distinct segment within a broadcast with:
- Start time and duration
- Guests/speakers
- Topics and subjects
- Images and descriptions
- Type-specific metadata (music artist, news content, etc.)

## Database

The app uses SQLite for local storage:

### Custom Podcasts
- **Feeds** - Podcast metadata (title, description, image, etc.)
- **Episodes** - Individual episodes with audio URLs
- **Subscriptions** - Tracks which podcasts you're subscribed to

### NPO Radio Programs
- **Channels** - NPO radio channels (Radio 1-6, 3FM)
- **Programs** - Radio shows with presenters and genres
- **Broadcasts** - Individual broadcast episodes with full metadata
- **Items** - Segments within broadcasts (interviews, music, news, reports)
- **Favorites** - User's favorite NPO broadcasts

Data is stored locally on your device for offline access.

## NPO Radio Channels

**Transistor** provides full access to all major NPO radio channels and podcasts:

### Radio Channels

| Channel | Description | Focus |
|---------|-------------|-------|
| **NPO Radio 1** | News and culture | Current affairs, interviews, documentaries |
| **NPO Radio 2** | Pop and rock | Music, nostalgia, entertainment |
| **3FM** | Pop & youth | Modern music, young talent, entertainment |
| **NPO Radio 4** | Classical music | Classical, opera, orchestral music |
| **NPO Radio 5** | World music | International music, world cultures |
| **NPO Radio 6** | Jazz | Jazz, blues, improvisation |

### Podcasts by Channel

- **NPO Radio 1**: Eo Verantwoording (interviews & debates)
- **NPO Radio 2**: Luistergoud (personal stories & culture)
- **3FM**: 
  - Funx (Hip hop & R&B)
  - Tomorrow Land Stories (Electronic music festival)
- **NPO Radio 4**: De Wereld van Opera (Classical deep dives)
- **NPO Radio 5**: Reizen rond de wereld (Travel & culture stories)
- **NPO Radio 6**: Jazz Talk (Jazz musician interviews)

### Features for Each Program

- Browse all available broadcasts/episodes
- View presenter information
- See guest appearances and interviews
- Track music played during broadcasts
- Check broadcast schedules and dates
- Save favorite broadcasts
- Full episode descriptions
- Topic and subject tags
- Duration and timing information

## Current Features

### NPO Integration
- ✅ Browse all NPO radio channels (Radio 1, 2, 3FM, 4, 5, 6)
- ✅ Access dedicated NPO podcast section
- ✅ View program schedules and details
- ✅ See presenter and guest information
- ✅ Track music played during broadcasts
- ✅ Search across all NPO content
- ✅ Save favorite broadcasts
- ✅ Filter by channel, genre, presenter
- ✅ Browse podcasts across all channels

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
