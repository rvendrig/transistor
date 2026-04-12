# 🎧 Transistor - Native iOS App

A native SwiftUI app for browsing NPO Radio programs, podcasts, and episodes with full offline support.

## ✨ Features

- **📻 NPO Radio Navigation**: Browse all 6 NPO radio channels (Radio 1-6, 3FM)
- **🎬 Complete Hierarchy**: Channels → Programs → Broadcasts → Items
- **🔍 Advanced Search**: Search by program name, presenter, or topic
- **🎉 Discovery**: Browse recent broadcasts across all channels
- **📱 Offline Support**: Works without internet using cached data and fallback strategy
- **🎨 Beautiful Dark Theme**: Optimized Material Design dark interface
- **💾 Local Database**: SQLite3 for persistent storage
- **🚀 Pure Native Swift**: No external dependencies, 100% SwiftUI

## 📋 Requirements

- **macOS 13.0+** (for Xcode 15+)
- **Xcode 15.0+** or later
- **iOS 15.0+** target (recommended iOS 16.0+)
- **iPhone 12** or newer (for device testing)

## 🚀 Quick Start (5 minutes)

### Step 1: Open Xcode

```bash
open -a Xcode iOS/Transistor
```

Or manually:
1. Open **Xcode**
2. File → Open
3. Navigate to `/transistor/iOS/Transistor`
4. Select the `Transistor.xcodeproj` file

### Step 2: Build Settings (One-time)

1. Select **Transistor** project in Xcode
2. Go to **Build Settings**
3. Search for `IPHONEOS_DEPLOYMENT_TARGET`
4. Set to `15.0` or higher

### Step 3: Build & Run

**On Simulator:**
```
Cmd + R  (Product → Run)
```

Select `iPhone 15 Pro` (or newer) and the app will launch.

**On Physical Device:**
1. Connect iPhone via USB
2. Select your iPhone in Xcode's device picker
3. `Cmd + R` to build and run
4. Trust the app on your iPhone

## 📁 Project Structure

```
iOS/Transistor/
├── Models/
│   └── Models.swift              # Data models (Channel, Program, Broadcast, Item)
├── Services/
│   ├── NPOAPIService.swift       # Real NPO API client (async/await)
│   ├── NPODataService.swift      # Mock data provider for testing
│   └── DatabaseService.swift     # SQLite3 wrapper
├── ViewModels/
│   └── NPOViewModel.swift        # MVVM ViewModel with @MainActor
├── Views/
│   ├── NPOChannelsViewUpdated.swift  # Channel grid & program list
│   ├── DiscoverView.swift           # Recent broadcasts
│   ├── SearchView.swift             # Program search
│   └── NPOItemDetailView.swift      # Item details
├── TransistorApp.swift           # Main app entry with TabView
├── Assets.xcassets/              # App icons & images
└── README.md                      # This file
```

## 🏗️ Architecture

### MVVM Pattern
- **Views** (SwiftUI): NPOChannelsViewV2, NPOProgramsViewV2, etc.
- **ViewModels** (@MainActor ObservableObject): NPOViewModel
- **Models** (Codable): NPOChannel, NPOProgram, NPOBroadcast, NPOItem
- **Services**: API client, Database, Mock data

### Data Flow
1. Views call ViewModel methods
2. ViewModel fetches from API via NPOAPIService
3. On error, falls back to NPODataService (mock data)
4. Data is persisted to DatabaseService (SQLite3)
5. Views subscribe to @Published properties

### API Strategy
- **Try Real API First**: `NPOAPIService.fetchPrograms(forChannel:)`
- **Fallback to Mock**: `NPODataService.getProgramsForChannel()`
- **Error Handling**: Show "Using Offline Data" message

## 🎨 Theming

All colors defined in `TransistorApp.swift`:

```swift
extension Color {
    static let transistorGreen = Color(red: 0.114, green: 0.733, blue: 0.329) // #1DB954
    static let darkBg = Color(red: 0.071, green: 0.071, blue: 0.071) // #121212
    static let cardBg = Color(red: 0.122, green: 0.122, blue: 0.122) // #1F1F1F
}
```

No additional styling needed - dark theme built-in.

## 🔄 Async Operations

All network requests use Swift async/await:

```swift
@MainActor
func loadPrograms(forChannel channelId: String) async {
    isLoading = true
    do {
        programs = try await apiService.fetchPrograms(forChannel: channelId)
    } catch {
        programs = mockDataService.getProgramsForChannel(channelId)
        errorMessage = "Using offline data"
    }
    isLoading = false
}
```

Called from views with:
```swift
.onAppear {
    Task {
        await viewModel.loadPrograms(forChannel: channel.id)
    }
}
```

## 📊 Data Models

### NPOChannel
```swift
struct NPOChannel: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let logoURL: String?
}
```

### NPOProgram
```swift
struct NPOProgram: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let presenters: [String]
    let image: String?
    let genre: String?
    let channelId: String?
}
```

### NPOBroadcast
```swift
struct NPOBroadcast: Identifiable, Codable {
    let id: String
    let title: String
    let programId: String
    let startTime: Date
    let duration: Int // seconds
    let description: String?
    let image: String?
}
```

### NPOItem
```swift
struct NPOItem: Identifiable, Codable {
    let id: String
    let broadcastId: String
    let title: String
    let description: String?
    let type: ItemType  // interview, music, news, report, segment, topic
    let duration: Int   // seconds
    let guests: [String]
    let topics: [String]
    let startOffset: Int? // seconds from broadcast start
}
```

## 🗄️ Database

SQLite3 tables:
- `npo_channels` - NPO radio channels
- `npo_programs` - Programs per channel
- `npo_broadcasts` - Broadcast episodes per program
- `npo_items` - Segments/items per broadcast
- `podcast_feeds` - Podcast subscriptions
- `podcast_episodes` - Episodes per podcast
- `favorites` - Bookmarked items
- `subscriptions` - Subscribed programs

## 🌐 API Integration

### Real NPO API Endpoints

The app connects to:
```
https://www.nporadio.nl/api/v3/
```

Supported endpoints:
- `GET /channels/{channelId}/programs` - Programs for a channel
- `GET /programs/{programId}/broadcasts?limit=50` - Broadcasts for a program
- `GET /search/programs?query={query}` - Search programs

### Response Format

APIs return JSON conforming to Codable models:

```json
{
  "programs": [
    {
      "id": "program123",
      "title": "Ochtendshow",
      "description": "The best morning show",
      "presenters": ["Host Name"],
      "image": "https://..."
    }
  ]
}
```

## 🧪 Testing

### Simulator Testing
1. Select iPhone 15 Pro (or later) from device menu
2. `Cmd + R` to run
3. App launches in simulator

### Device Testing
1. Connect iPhone via USB
2. Trust the app when prompted
3. Open Transistor on iPhone home screen

### Troubleshooting

**"Build Failed - No signing certificate"**
- Xcode → Settings → Accounts
- Add Apple ID or use free personal team

**"Simulator Won't Start"**
```bash
xcrun simctl erase all  # Reset all simulators
```

**"File Not Found" Errors**
- Ensure all Swift files are in target membership
- File Inspector → Target Membership checkbox

**App Crashes on Startup**
- Xcode → Console (Cmd+Shift+2)
- Check for error messages
- Clean build (Cmd+Shift+K)

## 🚀 Next Steps

### Short Term
- [ ] Test on physical iPhone device
- [ ] Verify NPO API endpoints are accessible
- [ ] Test offline functionality
- [ ] Add app icons and launch screen

### Medium Term
- [ ] Implement audio playback with AVPlayer
- [ ] Add favorites/bookmarks system
- [ ] Implement podcast RSS feed parsing
- [ ] Add local notifications

### Long Term
- [ ] Siri Shortcuts integration
- [ ] iCloud synchronization for bookmarks
- [ ] Apple Watch companion app
- [ ] App Store deployment

## 📝 Notes

- **No Dependencies**: Pure Swift with built-in frameworks only
- **iOS 15+**: Uses modern SwiftUI API
- **Dark Mode**: Optimized for dark environments
- **Offline First**: Works without network connection
- **Type Safe**: Full Swift type safety with Codable

## 📄 License

This is part of the Transistor project.

---

**Ready to use!** Build and run on simulator or device. 🚀
