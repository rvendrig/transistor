# 🍎 Transistor Native Swift - Setup Guide

## Vereisten

- **macOS 13.0+** (voor Xcode 15+)
- **Xcode 15.0+**
- **iOS 15.0+** (target)
- **iPhone 12 of nieuwer** (voor testing)

## Stap 1: Project Aanmaken in Xcode

1. Open **Xcode**
2. File → New → Project
3. Selecteer **iOS**
4. Selecteer **App**
5. Volgende:
   - **Product Name**: `Transistor`
   - **Team ID**: je Apple ID (of skip)
   - **Organization**: `Transistor`
   - **Bundle ID**: `com.transistor.app`
   - **Language**: Swift
   - **Interface**: SwiftUI
   - **Storage**: None

6. Kies locatie: `/home/user/transistor/iOS/`

## Stap 2: Files Toevoegen

Kopieer alle bestanden van dit project naar de Xcode project:

```
iOS/Transistor/
├── Models/
│   └── Models.swift
├── Services/
│   ├── DatabaseService.swift
│   └── NPODataService.swift
├── Views/
│   ├── NPOChannelsView.swift
│   ├── DiscoverView.swift
│   └── SearchView.swift
├── TransistorApp.swift
└── Assets.xcassets/
```

### In Xcode:
1. Right-click project → Add Files to "Transistor"
2. Selecteer alle Swift files
3. Zorg ervoor dat "Copy items if needed" aangevinkt is
4. Target: `Transistor`

## Stap 3: Build Settings

1. Select project in Xcode
2. Build Settings
3. Zoek naar "IPHONEOS_DEPLOYMENT_TARGET"
4. Set naar `15.0` of hoger

## Stap 4: Capabilities (Optional)

1. Project → Signing & Capabilities
2. Add Capability → Background Modes
3. Enable: Audio, Airplay, and Picture in Picture

## Stap 5: Build & Run

### Op Simulator:
1. Top van Xcode: Selecteer `iPhone 15 Pro` (of nieuwer)
2. Product → Run (of Cmd+R)

### Op Echt Device:
1. Connect iPhone met USB
2. Selecteer je iPhone in device picker
3. Product → Run (of Cmd+R)
4. Trust the app op je iPhone

## 📁 Project Structure

```
Transistor
├── Models.swift              # Data types
├── DatabaseService.swift     # SQLite DB
├── NPODataService.swift      # NPO Mock Data
├── TransistorApp.swift       # Main App
├── Views/
│   ├── NPOChannelsView.swift # Zenders & Programma's
│   ├── DiscoverView.swift    # Recent Afleveringen
│   └── SearchView.swift      # Zoeken
└── Assets/
    ├── Colors
    ├── Images
    └── Fonts
```

## 🎯 Features

✅ **6 NPO Radio Channels**
✅ **50+ Programs**
✅ **Honderden Afleveringen**
✅ **Items/Segments per Aflevering**
✅ **Dark Theme**
✅ **Search Functionaliteit**
✅ **SQLite Database**

## 🐛 Troubleshooting

### "Build Failed - No signing certificate"
→ Xcode → Settings → Accounts
→ Add Apple ID
→ Project → Signing & Capabilities

### "Simulator Won't Start"
```bash
xcrun simctl erase all  # Reset all simulators
```

### "File Not Found" Errors
→ Zorg dat alle Swift files in het project zitten
→ File Inspector → Target Membership checken

## 🚀 Klaar?

```bash
# Build & Run
Cmd + R
```

Selecteer simulator/device en app laadt! 🎧

---

**Pure Native Swift - No Expo Needed!** ✨
