# Quick Start: Testing Real Content in 5 Minutes

## Prerequisites
- Mac with Xcode installed
- iPhone Simulator (or device)
- Internet connection (for real streams)

---

## Step 1: Create Xcode Project (2 minutes)

```bash
# Navigate to project
cd /transistor/iOS

# Open Xcode
open -a Xcode
```

1. **File → New → Project**
2. **Select: iOS → App**
3. **Configure:**
   - Product Name: `Transistor`
   - Organization Identifier: `com.yourname`
   - Language: **Swift**
   - User Interface: **SwiftUI**
   - Storage: **None**
4. **Create** in `/transistor/iOS/` folder

---

## Step 2: Add Swift Files (1 minute)

1. **Right-click** on project in sidebar
2. **Add Files to Transistor**
3. **Select all** folders:
   ```
   ✓ Models/
   ✓ Views/
   ✓ ViewModels/
   ✓ Services/
   ✓ Providers/
   ```
4. **Ensure "Copy items if needed"** is unchecked
5. **Click Add**

---

## Step 3: Configure Build Settings (1 minute)

1. **Select Project** → Transistor
2. **Build Settings** tab
3. **Search:** `IPHONEOS_DEPLOYMENT_TARGET`
4. **Set to:** `15.0`

---

## Step 4: Build & Run (1 minute)

```bash
# Build
Cmd + B

# Run on simulator
Cmd + R
```

✅ **App should launch with real content!**

---

## Testing Real Content Flow

### Test 1: Live Radio Playback

1. **Navigate:** Browse tab
2. **Tap:** NPO Radio 1
3. **Tap:** Any program (e.g., "Ochtendshow")
4. **Tap:** Any broadcast
5. **Tap:** Play button
6. **Result:** 🎵 **Real NPO stream plays!**

```
Expected:
- Audio starts immediately (after ~2-5s buffering)
- Progress bar updates in real-time
- Circular indicator shows progress percentage
- Play/pause controls work
- Speed control works (0.75x, 1.0x, 1.25x, 1.5x)
```

### Test 2: Listening History

1. **Play** 3-5 different broadcasts
2. **Navigate:** Hub tab
3. **Select:** History
4. **Verify:**
   - All 3-5 sessions appear ✅
   - Topics show correctly ✅
   - Time ago shows "just now" ✅
   - Progress percentage correct ✅

```
History shows:
├─ Ochtendshow - NPO Radio 1 - 45% - just now
├─ Middagcafé - NPO Radio 1 - 22% - 2 min ago
└─ Nachtshow - NPO Radio 1 - 78% - 5 min ago
```

### Test 3: Voice Commands

1. **Navigate:** Hub tab
2. **Select:** Commands
3. **Type:** "Play NPO Radio 1"
4. **Tap:** Send
5. **Result:** Should trigger search/navigation

```
Try these commands:
- "Play NPO Radio 1"
- "Show me news"
- "Browse channels"
- "Show live now"
```

### Test 4: Listening Session Details

1. **In History tab**
2. **Tap:** Any session
3. **View:** Full details including:
   - Topics covered
   - Guests
   - Progress bar with time
   - Add notes option

---

## Real Content Verifications

### ✅ Audio URLs Working

Check console logs:

```
audioUrl = https://www.nporadio.nl/live/npo-radio-1/index.m3u8 ✅
```

### ✅ Database Saving

Check Console:

```
SELECT * FROM listening_sessions LIMIT 5
→ Should show your recent plays
```

### ✅ Real Streams

Test by checking audio quality:
- Streams automatically adjust quality
- Higher bitrate on WiFi
- Lower bitrate on cellular

---

## Common Issues & Fixes

### "No audio playing"

**Cause:** Simulator audio not enabled  
**Fix:**
```bash
# In Simulator
I/O → Audio Input: [Built-in Microphone]
I/O → Audio Output: [Built-in Speakers]
```

### "Cannot find module"

**Cause:** Files not added to target  
**Fix:**
```
Select file in Xcode
→ File Inspector
→ Target Membership → Check "Transistor"
```

### "AVPlayer errors in console"

**Cause:** Bad URL or network issue  
**Fix:**
1. Check internet connection
2. Try different program
3. Check if NPO stream is available
4. Restart simulator

---

## Debug Real Content Setup

Add this to ContentConfiguration.swift and call in app:

```swift
// In your app initialization:
ContentConfig.enableHybridMode()
ContentConfig.printConfiguration()
debugContentSetup()

// Output:
// ═══════════════════════════════════
// 📡 TRANSISTOR CONTENT CONFIGURATION
// ═══════════════════════════════════
// Mode: hybrid
// Channels: 6
// Audio URLs: ✅ Real
// Podcasts: 8 feeds
// ═══════════════════════════════════
```

---

## Real Content Sources Verified

### ✅ NPO Radio (Working Now)
```
Radio 1: https://www.nporadio.nl/live/npo-radio-1/index.m3u8
Radio 2: https://www.nporadio.nl/live/npo-radio-2/index.m3u8
3FM: https://www.nporadio.nl/live/npo-3fm/index.m3u8
Radio 4: https://www.nporadio.nl/live/npo-radio-4/index.m3u8
Radio 5: https://www.nporadio.nl/live/npo-radio-5/index.m3u8
Radio 6: https://www.nporadio.nl/live/npo-radio-6/index.m3u8
```

### ✅ Podcasts (Via ContentEnrichmentService)
```
BBC Today: https://podcasts.bbc.co.uk/today/rss.xml
NPR News: https://feeds.npr.org/500005/podcast.xml
Ologies: https://feeds.acast.com/public/shows/ologies
... 5 more popular feeds
```

---

## What You're Testing

| Feature | Status | Real Data |
|---------|--------|-----------|
| Channels | ✅ Works | 6 NPO channels |
| Programs | ✅ Works | Real program names |
| Broadcasts | ✅ Works | Real episode info |
| **Audio URLs** | ✅ **Real** | HLS streams |
| Playback | ✅ Works | AVPlayer with HLS |
| History | ✅ Works | Session database |
| Metadata | ✅ Works | Topics, guests |
| Search | ✅ Works | Multi-provider |

---

## Next Steps After Testing

1. **✅ Confirm playback works**
   - Real audio from NPO
   - Listening sessions created
   - History saved to database

2. **📝 Note any issues**
   - Check console logs
   - Test with different channels
   - Verify metadata displays

3. **🚀 Ready for:**
   - Adding more providers (BBC, Spotify)
   - Implementing markers
   - Adding podcast feeds
   - CarPlay integration

---

## Pro Tips

### Tip 1: Network Monitoring
```
Open Console.app
Search: "nporadio" or "http"
Watch real HTTP requests/responses
```

### Tip 2: Database Inspection
```
Simulator Documents folder:
~/Library/Developer/CoreSimulator/Devices/{UUID}/data/Containers/Data/Application/{UUID}/Documents/transistor.db

Open with: DB Browser for SQLite
```

### Tip 3: Audio Debugging
```
Console logs to watch for:
- AVPlayer state changes
- Stream URL loading
- Error messages
- Progress updates
```

### Tip 4: UI Testing
```
Test all 6 tabs in order:
1. Browse → Load channels/programs
2. Guide → Check schedule
3. Playlists → Empty (unless you add)
4. Hub → History shows sessions
5. Providers → See NPO enabled
6. Search → Cross-provider search
```

---

## Success Criteria

You've successfully set up real content when:

- ✅ Xcode project created
- ✅ All Swift files added
- ✅ App builds without errors
- ✅ App runs in simulator
- ✅ NPO Radio 1 stream loads
- ✅ Real audio plays
- ✅ Listening session created
- ✅ Session appears in history
- ✅ Progress tracked correctly
- ✅ All 6 tabs navigate

---

## Troubleshooting Checklist

If something doesn't work:

```
[ ] Check internet connection
[ ] Restart Xcode
[ ] Cmd+Shift+K to clean build
[ ] Delete derived data:
    rm -rf ~/Library/Developer/Xcode/DerivedData/*
[ ] Restart simulator:
    xcrun simctl erase all
[ ] Check console logs for errors
[ ] Verify file target membership
[ ] Check deployment target (iOS 15.0+)
```

---

## Quick Reference

### Key Commands
```bash
# Build
Cmd + B

# Run
Cmd + R

# Clean
Cmd + Shift + K

# Stop
Cmd + .
```

### Key Classes
```swift
AudioPlayerService.shared.play(broadcast)
ContentViewModel().loadBroadcasts()
ContentEnrichmentService.getNPOStreamURL()
DatabaseService.createListeningSession()
```

### Key URLs
```
NPO Radio: https://www.nporadio.nl/live/npo-radio-1/index.m3u8
Podcasts: https://podcasts.bbc.co.uk/today/rss.xml
```

---

## Support

If you encounter issues:

1. **Check logs** in Xcode Console
2. **Read** REAL_CONTENT_SETUP.md for detailed guide
3. **Review** DATA_FLOW_DIAGRAM.md for architecture
4. **Verify** network connection and stream URLs

---

## Summary

🚀 **In 5 minutes:**
- Create Xcode project
- Add Swift files
- Configure settings
- Build & run app
- Test real content playback

🎵 **Get real audio playing from NPO Radio immediately!**

📊 **Track listening in real-time with full history**

🔄 **Ready for multi-provider expansion**

---

**Ready to go!** Start building now! 🎉
