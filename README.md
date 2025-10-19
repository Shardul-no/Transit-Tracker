# Transit Tracker

A React Native mobile app that tracks user movement and transportation mode entirely offline, with no account or sign-in required.

## Features

- ✅ **Offline-First**: All data stored locally in SQLite
- 🗺️ **Free Maps**: Uses OpenStreetMap tiles
- 🚶 **Mode Detection**: Automatically detects walking, driving, or train
- 📊 **Session Summaries**: View detailed trip statistics
- 🔒 **Privacy**: No authentication, no cloud sync, all data stays on device
- 🔋 **Battery Optimized**: Adaptive location updates

## Tech Stack

- React Native (TypeScript)
- react-native-maps (OpenStreetMap)
- react-native-geolocation-service
- react-native-sqlite-storage
- react-native-permissions
- Zustand (state management)
- NativeWind (Tailwind CSS)

## Installation

```bash
# Install dependencies
npm install

# iOS only - install pods
cd ios && pod install && cd ..

# Run on Android
npm run android

# Run on iOS
npm run ios
```

## Permissions

The app requires location permissions to function:
- **Android**: Location permissions (foreground and background)
- **iOS**: Location permissions (when in use and always)

## Transportation Mode Detection

Speed-based classification:
- **Walking**: < 3 m/s (~10.8 km/h)
- **Driving**: 3-22 m/s (~10.8-79.2 km/h)
- **Train**: > 22 m/s (~79.2 km/h)

## Data Storage

All session data is stored locally in SQLite:
- GPS points (timestamp, latitude, longitude, speed, mode)
- Session metadata (start time, end time, total distance, etc.)
- No cloud backup or sync

## Export (Stretch Goal)

Export trips as GPX or JSON files for backup or analysis.

## License

MIT
