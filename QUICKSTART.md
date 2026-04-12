# Transistor - Quick Start Guide

## 🚀 Eerste Start

### 1. Start de Development Server

```bash
npm start
```

Dit zal de Expo development server starten. Je ziet een QR code in de terminal.

### 2. Op je telefoon

#### iOS (iPhone)
1. Open de **Expo Go** app
2. Scan de QR code
3. App laadt automatisch

#### Android
1. Open de **Expo Go** app
2. Scan de QR code
3. App laadt automatisch

#### Web (PC/Browser)
```bash
npm run web
```

## 📱 Beschikbare Commands

```bash
# Start development server
npm start

# Run op iOS simulator (Mac only)
npm run ios

# Run op Android emulator
npm run android

# Run in browser
npm run web

# Run tests
npm test

# Lint code
npm run lint
```

## 🎯 Wat je kunt doen

### NPO Tab
1. Kies een radio zender (Radio 1, 2, 3FM, 4, 5, 6)
2. Blader door beschikbare programma's
3. Tik op een programma om alle afleveringen te zien
4. Tik op een aflevering voor details
5. Blader door onderdelen (Items) van de aflevering

### Discover Tab
1. Zie recente afleveringen van je abonnementen
2. Blader door episode details
3. Bekijk presentatoren en gasten

### Search Tab
1. Zoek op keywords (minimum 3 karakters)
2. Filter resultaten
3. Bekijk episode details

### Subscriptions Tab
1. Beheer je podcastabonnementen
2. Volg nieuwe afleveringen
3. Pull-to-refresh voor updates

## 🔍 Hierarchie

```
Zender (Channel)
└── Programma (Program)
    └── Aflevering/Uitzending (Broadcast)
        └── Onderdeel/Segment (Item)
            ├── Interviews
            ├── Muziek
            ├── Nieuws
            ├── Reportages
            └── Thema's
```

## 🗄️ Lokale Data

Alles wordt lokaal opgeslagen in SQLite:
- Feeds en afleveringen
- NPO programma's en uitzendingen
- Favorieten en abonnementen

Geen internet nodig na eerste sync!

## 📝 Toevoegen van Feeds

### Via RSS URL
1. Ga naar "Discover" tab
2. Tik op "+" knop
3. Plak RSS feed URL
4. Feed wordt automatisch ingeladen

### Populaire Podcasts
- NPO podcasts (direct beschikbaar via NPO tab)
- Andere podcasts via RSS feeds

## 🐛 Troubleshooting

### App laadt niet
- Sluit Expo Go app
- Zet WiFi uit en aan
- Scan QR code opnieuw

### Data laadt niet
- Check internet verbinding
- Herstart Expo Go
- Wis cache: Settings → Clear Cache

### Fout meldingen
- Controleer console logs
- Herstart development server
- Update naar nieuwste Expo Go versie

## 📞 Help

Voor issues:
- Check CLAUDE.md voor development guidelines
- Controleer console output voor errors
- File issue op GitHub

---

**Happy listening! 🎧**
