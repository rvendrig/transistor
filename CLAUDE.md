# CLAUDE.md - Transistor Development Guide

## What This Is

**Transistor** is a provider-agnostic podcast and radio navigation app for iOS, built with SwiftUI.
Repository: `rvendrig/transistor` | Default branch: `main`

## Data Model (taxonomie)

```
Network (boeket: NPO, BBC, ...)
  └── Channel (Radio 1, 3FM, ...)

Show (onafhankelijk van channel, many-to-many via broadcasts)
  └── Season (optioneel)
        └── Broadcast (= show + channel + tijdstip)   ← radio
            Episode  (= show + publicatiedatum)        ← podcast
              ├── Segment (structureel format-onderdeel)
              ├── Clip (willekeurig fragment)
              └── Marker (gebruiker-geplaatst)
```

- **Titled protocol**: Show, Channel, Network, Season hebben `titles: [TitledPeriod]` voor tijdgebonden namen ("3FM" → "NPO 3FM")
- **titleOverride**: Broadcast/Episode kan per-uitzending naam hebben ("DWDD met Barack Obama")
- **Provider mapping**: elke provider mapt eigen terminologie → generiek model (gedocumenteerd bovenaan provider file)

## Architecture

### Provider-agnostic design
- `ContentProvider` protocol — alle providers implementeren dezelfde interface
- `ProviderStore` — registry, providers worden geregistreerd in `TransistorApp.init()`
- NPO is gewoon één provider, niet hardcoded in de app-shell

### File structure
```
iOS/Transistor/
  Models/
    GenericModels.swift     ← Network, Channel, Show, Season, Broadcast, Episode, Segment, Clip, Marker, etc.
    Models.swift            ← NPO-specifieke types (NPOChannel, NPOBroadcast, etc.)
    ScheduleModels.swift
  Providers/
    ContentProvider.swift   ← Protocol + ProviderStore + AudioContent + ContentType
    NPOProvider.swift       ← NPO implementatie (met POMS mapping docs)
    PodcastFeedProvider.swift ← RSS/Podcast feed provider
  Services/
    DatabaseService.swift   ← SQLite3, generieke tabellen (channels, shows, broadcasts, segments, etc.)
    AudioPlayerService.swift ← AVPlayer
    NPOAPIService.swift     ← NPO API client (fake endpoints)
    NPODataService.swift    ← NPO mock data
    ContentEnrichmentService.swift ← Podcast feeds + test URLs
    ContentConfiguration.swift
  ViewModels/
    ContentViewModel.swift  ← Generiek: channels, shows, broadcasts, search, playlists, markers, favorites
    NPOViewModel.swift      ← Slank: alleen NPO data-fetching (~100 regels)
  Views/
    BrowseView.swift        ← Generieke browse (Networks → Channels → Shows → Broadcasts)
    SearchView.swift        ← Generieke search (UnifiedSearchResult)
    NPOChannelsViewUpdated.swift  ← NPO-specifieke browse (legacy, nog in gebruik)
    NPOItemDetailView.swift       ← NPO-specifieke item detail
    [overige generieke views]
```

### What Works
- **DatabaseService** — generieke tabellen (networks, channels, shows, seasons, broadcasts, segments, clips, playlists, markers, favorites, listening_sessions)
- **AudioPlayerService** — AVPlayer, play/pause/seek/speed
- **UI** — 6-tab app, generieke browse + search, dark theme
- **Playlists, markers, favorites** — end-to-end persistence via ContentViewModel

### What Doesn't Work
- **NPOAPIService** — fake API (`nporadio.nl/api/v3` bestaat niet), valt terug op mock data
- **Live stream URLs** — geraden, niet geverifieerd
- **On-demand playback** — geen echte broadcast audio URLs

## Building

```bash
cd iOS
xcodegen generate
xcodebuild -target Transistor -sdk iphoneos26.4 -configuration Debug build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

## Multi-Agent Workflow

1. Always pull before starting work
2. Work on feature branches: `claude/<description>-<suffix>`
3. Update this file when making architectural changes
4. Don't trust SESSION_SUMMARY.md etc. — trust the code and this file

## Provider Mapping Template

Bij het toevoegen van een nieuwe provider, documenteer de mapping bovenaan het provider-bestand:
```
// <Provider> Mapping → Transistor Model
// ──────────────────────────────────────
// <hun term>  → Network
// <hun term>  → Channel
// <hun term>  → Show
// <hun term>  → Season
// <hun term>  → Broadcast / Episode
// <hun term>  → Segment
// <hun term>  → Clip
```

## What To Work On Next

### Phase 1: Verification & Real Content (Priority: HIGH)

**Goal**: Verify the app compiles, runs, and plays real content

1. **Build & Test on macOS**
   - `xcode build` the Transistor.xcodeproj to verify zero compilation errors
   - Run on simulator to verify app launches without crashes
   - Test tab navigation: Browse → Playlists → Log → Search → Settings
   - Verify mini player appears when content plays

2. **Real NPO Radio Streams**
   - Current state: `NPOProvider.fetchBroadcasts()` returns broadcasts with `audioUrl` field
   - `ContentEnrichmentService` injects real HLS URLs from `RealContentSeed.npoStreamUrls`
   - **Test**: Pick a broadcast, verify it has a valid audioUrl, attempt playback
   - **Expected**: Audio plays without buffering errors
   - If URLs fail: NPO Radio streams are behind IP-block or require authentication

3. **Listening Session Auto-Creation**
   - Current: `AudioPlayerService.play()` calls `startSession()` which creates ListeningSession in DB
   - `AudioPlayerService.currentSessionId` tracks the active session
   - Progress updates via periodic time observer
   - **Test**: Play content, check LogView, verify session appears with correct start time and progress
   - **Expected**: Session auto-created, progress updates every 500ms, ends when playback stops

### Phase 2: Completion & Polish (Priority: MEDIUM)

4. **UI/UX Refinements**
   - **BrowseView**: Test day navigation in schedule view, verify date picker works
   - **LogView**: Verify date grouping ("Vandaag", "Gisteren", dates). Test marker display
   - **SearchView**: Test search across shows/broadcasts/episodes, verify presenter display
   - **Mini Player**: Verify LIVE indicator shows for live streams, artwork loads, play/pause works
   - **Color scheme**: Verify dark theme is consistent across all tabs (use `Color.darkBg`, `Color.cardBg`, `Color.transistorGreen`)

5. **Playlist Integration**
   - PlaylistsView, PlaylistDetailView, AddToPlaylistView are created but may need:
     - Verify "Add to Playlist" button works from SearchView, BrowseView detail screens
     - Test creating new playlist with name/description
     - Test adding items, verify item count updates
     - Test removing items from playlist

6. **Marker & Favorites**
   - Verify markers can be created during playback (timestamp + tags)
   - Verify favorites button works in detail views
   - Test that both persist to SQLite and reload on app restart

### Phase 3: Second Provider (Priority: MEDIUM)

7. **Add BBC Sounds Provider**
   - Create `BBCProvider: ContentProvider` in `Providers/BBCProvider.swift`
   - Implement required methods: `fetchChannels()`, `fetchShows()`, `fetchBroadcasts()`
   - BBC Sounds API: https://www.bbc.co.uk/sounds/api/bbc/live (or equivalent)
   - Document mapping at top of file (see Provider Mapping Template below)
   - Register in `TransistorApp.init()`: `ProviderStore.shared.registerProvider(BBCProvider())`
   - **Test**: Toggle BBC provider on in Settings, verify BBC channels appear in BrowseView

### Phase 4: Cleanup (Priority: LOW)

8. **Remove Legacy Views**
   - `NPOChannelsViewUpdated.swift` — functionality now in `BrowseView`
   - `NPOItemDetailView.swift` — may be replaced by generic broadcast/episode detail
   - `NPOViewModel.swift` — mostly deprecated, only used for legacy compatibility
   - Check references in `TransistorApp.swift` before deleting

9. **Documentation**
   - Update this file with any architectural changes
   - Document any new provider integrations (BBC, Spotify, etc.)
   - Add troubleshooting section if compilation issues arise

---

## Step-by-Step Checklist for Next Agent

### Start of Session
- [ ] `git fetch origin && git checkout main` (or stay on feature branch if continuing work)
- [ ] Verify HEAD is at commit 422acea (latest)
- [ ] Open iOS/Transistor.xcodeproj in Xcode
- [ ] Build & run on simulator

### Phase 1 Testing
- [ ] App launches, no crashes
- [ ] Tab navigation works (Browse → Playlists → Log → Search → Settings)
- [ ] BrowseView shows radio channels grid
- [ ] Tap a channel, verify show list appears (or schedule with day navigation)
- [ ] Search works: type "news", verify broadcasts appear
- [ ] Play a broadcast: verify mini player appears, audio plays
- [ ] Stop playback, check LogView: verify listening session exists with correct progress
- [ ] Tap Settings, toggle provider on/off, verify UI updates

### Phase 2 Refinements
- [ ] Create a playlist from SearchView
- [ ] Add a broadcast to playlist
- [ ] Verify playlist appears in PlaylistsView
- [ ] Create a marker during playback (if marker UI exists)
- [ ] Favorite a broadcast
- [ ] App restart, verify playlists/markers/favorites persist

### Phase 3 New Provider
- [ ] Create BBCProvider.swift with basic channel fetching
- [ ] Register in TransistorApp
- [ ] Toggle BBC on in Settings
- [ ] Verify BBC channels appear in BrowseView

### Before Committing
- [ ] `git status` — verify only intended files changed
- [ ] `swift build` or `xcodebuild` — zero warnings
- [ ] Test on both light & dark theme
- [ ] Commit with clear message: `git commit -m "Feature: description"`
- [ ] Push: `git push -u origin claude/<description>-<suffix>`

---

## Known Limitations

### Current Issues
- **NPOAPIService** uses hardcoded test endpoints (nporadio.nl/api/v3 doesn't exist)
- **HLS URLs** are injected via ContentEnrichmentService, may be blocked by IP/auth
- **Podcast feeds** partially implemented, some RSS parsing may fail
- **Schedule view** only shows one day at a time, no multi-day view

### Future Work
- Real NPO API integration (possibly via web scraping or official API)
- BBC Sounds, Spotify, other radio networks
- Transcript/text overlay for broadcasts
- Push notifications for live broadcasts
- Watch OS app
- CarPlay support

---

## Debugging Tips

**App won't build:**
- Check Xcode build settings: iOS 15.0+ required, Swift 5.5+
- Verify all imports: SwiftUI, AVFoundation, SQLite3

**Audio won't play:**
- Check AVAudioSession setup in AudioPlayerService.setupAudioSession()
- Verify URL is valid: print(audioUrl) before playback
- Check Audio Playback & Recording capability in Signing & Capabilities

**UI looks wrong:**
- Colors defined as extensions in TransistorApp: `Color.darkBg`, `Color.cardBg`, `Color.transistorGreen`
- Dark theme forced in TransistorApp: `.preferredColorScheme(.dark)`
- If colors missing: add extensions to Color

**Listening session not created:**
- Check `AudioPlayerService.startSession()` is called
- Verify `DatabaseService.createListeningSession()` returns non-nil
- Check SQLite database file exists at `~/Library/Documents/transistor.db`

**Provider not showing:**
- Verify provider registered in `TransistorApp.init()`
- Verify `ProviderStore.shared.activeProviders` contains provider id
- Check SettingsView toggles work correctly
