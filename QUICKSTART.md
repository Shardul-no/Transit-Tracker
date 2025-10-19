# Transit Tracker - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Install Dependencies

```bash
npm install
```

### Step 2: Platform-Specific Setup

#### iOS (macOS only)
```bash
cd ios
pod install
cd ..
```

#### Android
No additional setup needed - just ensure Android SDK is installed.

### Step 3: Run the App

#### iOS
```bash
npm run ios
```

#### Android
```bash
npm run android
```

## 📱 First Use

1. **Grant Location Permission** when prompted
2. **Tap the green Start button** to begin tracking
3. **Move around** - the app will detect your mode (walking/driving/train)
4. **Tap the red Stop button** to end tracking
5. **View your trip summary** with statistics

## 🎯 Key Features

- ✅ **No Account Required** - Start using immediately
- ✅ **100% Offline** - All data stored locally
- ✅ **Auto Mode Detection** - Detects walking, driving, or train
- ✅ **Free Maps** - Uses OpenStreetMap
- ✅ **Export Data** - Save as JSON or GPX

## 📊 How It Works

### Transportation Mode Detection

| Speed | Mode | Icon |
|-------|------|------|
| < 10.8 km/h | Walking | 🚶 |
| 10.8 - 79.2 km/h | Driving | 🚗 |
| > 79.2 km/h | Train | 🚆 |

### Screens

1. **Map Screen** - Start/stop tracking, see live route
2. **Summary Screen** - View trip statistics after stopping
3. **History Screen** - Browse all past trips

## 🔧 Troubleshooting

### Location Not Working?
- Ensure location permissions are granted
- Enable GPS on your device
- Use a physical device (not simulator)

### Map Not Loading?
- Check internet connection (needed for map tiles)
- Tiles are cached after first download

### Build Errors?
```bash
# Clear cache
npm start -- --reset-cache

# iOS: Reinstall pods
cd ios && pod deintegrate && pod install && cd ..

# Android: Clean build
cd android && ./gradlew clean && cd ..
```

## 📖 Documentation

- **SETUP.md** - Detailed installation and configuration
- **USAGE_GUIDE.md** - Complete user guide
- **README.md** - Project overview

## 🔒 Privacy

- No user accounts or authentication
- No cloud sync or external servers
- All data stays on your device
- No analytics or tracking

## 🎨 Tech Stack

- React Native 0.73 (TypeScript)
- react-native-maps (OpenStreetMap)
- react-native-geolocation-service
- react-native-sqlite-storage
- Zustand (state management)
- NativeWind (Tailwind CSS)

## 📦 Project Structure

```
src/
├── screens/          # UI screens
│   ├── MapScreen.tsx
│   ├── SummaryScreen.tsx
│   └── HistoryScreen.tsx
├── services/         # Business logic
│   ├── trackingService.ts
│   ├── modeDetector.ts
│   └── storage.ts
├── store/           # State management
│   └── trackingStore.ts
├── types/           # TypeScript types
└── utils/           # Helper functions
```

## 🎯 Next Steps

1. **Test on a real device** for accurate GPS
2. **Take a walk** to test walking mode
3. **Drive or take transit** to test other modes
4. **Export a trip** as JSON or GPX
5. **Check trip history** to see all sessions

## 💡 Tips

- Grant "Always Allow" location for background tracking
- Clear old trips to save storage
- Export important trips before deleting
- Better GPS signal = better accuracy

## 🆘 Need Help?

Check the detailed guides:
- Installation issues → **SETUP.md**
- Usage questions → **USAGE_GUIDE.md**
- Code questions → **README.md**

---

**Ready to track your first trip? Run the app and tap Start!** 🚀
