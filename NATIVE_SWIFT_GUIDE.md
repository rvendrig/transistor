# 🍎 Transistor Native Swift Guide

## ⚡ Quick Start (5 minuten)

### Stap 1: Xcode Project Aanmaken

```bash
# Je hebt al alle Swift files
# Nu moet je ze in Xcode zetten
```

1. Open **Xcode** (Applications → Xcode)
2. File → New → Project
3. **App** template selecteren
4. Instellingen:
   - Product Name: `Transistor`
   - Language: **Swift**
   - Interface: **SwiftUI**

### Stap 2: Files Toevoegen

1. Right-click project in Xcode
2. Add Files to "Transistor"
3. Navigate naar: `/transistor/iOS/Transistor/`
4. Selecteer ALLE `.swift` files
5. ✅ "Copy items if needed"

### Stap 3: Build & Run

```
Cmd + R  (of Product → Run)
```

Selecteer simulator/device → App laadt! 🎉

---

## 🎯 Wat je Krijgt

### Native Swift Features
- ✅ **Pure SwiftUI** - Modern iOS framework
- ✅ **SQLite Database** - Local storage
- ✅ **Dark Theme** - Beautiful design
- ✅ **No Dependencies** - Alles built-in

### Content
- ✅ **6 NPO Channels** - Radio 1-6, 3FM
- ✅ **50+ Programs** - Met presentatoren
- ✅ **Items/Segments** - Per aflevering
  - 🎤 Interviews
  - 🎵 Muziek
  - 📰 Nieuws
  - 📊 Reportages
  - 🏷️ Thema's

### Views
1. **NPO Tab** 
   - Zenders → Programma's → Afleveringen → Items

2. **Discover Tab**
   - Recente afleveringen

3. **Search Tab**
   - Zoeken op onderwerpen, presentatoren, etc.

---

## 📱 Op je iPhone

### Via USB (echte device):
1. iPhone connecteren
2. Xcode: Selecteer je iPhone
3. `Cmd + R` → App installeert
4. Trust the app op je iPhone
5. Open → Transistor laadt! 🚀

### Via Simulator:
1. Xcode: Selecteer `iPhone 15 Pro` (of hoger)
2. `Cmd + R`
3. App laadt direct

---

## 🎨 Dark Theme (Gebouwd-in)

Alle kleuren zijn al ingesteld:
- Achtergrond: `#121212`
- Cards: `#1F1F1F`
- Accent: `#1DB954` (groen)

Geen extra theming nodig! ✨

---

## 📚 Project Files

```
iOS/Transistor/
├── Models/
│   └── Models.swift              # TypeScript van Swift 😄
├── Services/
│   ├── DatabaseService.swift     # SQLite
│   └── NPODataService.swift      # Mock data
├── Views/
│   ├── NPOChannelsView.swift     # Zenders & Programma's
│   ├── DiscoverView.swift        # Recent
│   └── SearchView.swift          # Zoeken
└── TransistorApp.swift           # Main app entry
```

---

## ⚙️ Xcode Instellingen

### Deployment Target
- **Minimum:** iOS 15.0
- **Recommended:** iOS 16.0+

### Team ID (voor echte iPhone)
- Xcode → Signing & Capabilities
- Voeg Apple ID toe

---

## 🚀 Volgende Stappen

### Feature Ideas
- [ ] Audio playback met AVPlayer
- [ ] Favorites opslaan in iCloud
- [ ] Siri shortcuts
- [ ] Watch app
- [ ] Widgets

### Optimization
- [ ] Core Data migration
- [ ] Background refresh
- [ ] Network caching
- [ ] App Store build

---

## 🐛 Problemen?

**App crashes bij startup:**
→ Check Console (Cmd+Shift+2)
→ Kijk voor error messages

**Simulator wil niet starten:**
```bash
xcrun simctl erase all
```

**Build errors:**
→ Product → Clean Build Folder (Cmd+Shift+K)
→ Build opnieuw (Cmd+B)

---

## ✅ Klaar!

Je hebt nu:
- ✓ Pure native iOS app
- ✓ SwiftUI interface
- ✓ SQLite database
- ✓ Complete NPO/podcast content
- ✓ Search & discovery
- ✓ Dark theme
- ✓ Zero external dependencies

**Veel plezier met Transistor!** 🎧📻

---

**Pure Swift. No Expo. Just iOS.** 🍎
