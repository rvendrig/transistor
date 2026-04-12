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

1. **Vind een echte NPO data-bron** — de fake API is de grootste blocker
2. **Verifieer audio stream URLs** — test of HLS URLs resolven
3. **Verwijder legacy NPO views** — `NPOChannelsViewUpdated.swift` kan vervangen worden door `BrowseView`
4. **Voeg een tweede provider toe** (BBC Sounds, Spotify) om het multi-provider model te valideren
