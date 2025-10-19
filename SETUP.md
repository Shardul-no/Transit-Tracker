# Transit Tracker - Setup Guide

## Prerequisites

- Node.js (v18 or higher)
- React Native development environment set up
- For iOS: Xcode and CocoaPods
- For Android: Android Studio and Android SDK

## Installation Steps

### 1. Install Dependencies

```bash
npm install
```

### 2. iOS Setup (macOS only)

```bash
cd ios
pod install
cd ..
```

### 3. Android Setup

Make sure you have Android SDK installed and `ANDROID_HOME` environment variable set.

## Running the App

### iOS

```bash
npm run ios
```

Or open `ios/TransitTracker.xcworkspace` in Xcode and run from there.

### Android

```bash
npm run android
```

Or open the `android` folder in Android Studio and run from there.

## Permissions Setup

### Android

The app requires the following permissions (already configured in `AndroidManifest.xml`):
- `ACCESS_FINE_LOCATION` - For precise GPS tracking
- `ACCESS_COARSE_LOCATION` - For general location
- `ACCESS_BACKGROUND_LOCATION` - For tracking when app is in background
- `INTERNET` - For downloading map tiles

### iOS

The app requires location permissions (already configured in `Info.plist`):
- Location When In Use
- Location Always (for background tracking)

## OpenStreetMap Configuration

The app uses OpenStreetMap tiles by default. The MapView component is configured to use OSM tiles.

**Note**: For production use, consider:
1. Using a tile server with proper caching
2. Adding proper OSM attribution
3. Respecting OSM tile usage policy
4. Consider self-hosting tiles or using a commercial provider for high-volume usage

## Database

The app uses SQLite for local storage via `react-native-sqlite-storage`. The database is automatically initialized on first launch.

Database file location:
- **iOS**: `Library/LocalDatabase/TransitTracker.db`
- **Android**: `/data/data/com.transittracker/databases/TransitTracker.db`

## Troubleshooting

### Common Issues

1. **Location not updating**
   - Check that location permissions are granted
   - Ensure GPS is enabled on the device
   - Try running on a physical device (simulator GPS can be unreliable)

2. **Map not showing**
   - Check internet connection (needed for tile downloads)
   - Verify that `INTERNET` permission is granted

3. **Build errors**
   - Clear cache: `npm start -- --reset-cache`
   - Clean builds:
     - iOS: `cd ios && pod deintegrate && pod install`
     - Android: `cd android && ./gradlew clean`

4. **SQLite errors**
   - Uninstall and reinstall the app to reset database
   - Check device storage space

## Development

### Project Structure

```
src/
├── components/       # Reusable UI components
├── screens/         # Screen components
│   ├── MapScreen.tsx
│   ├── SummaryScreen.tsx
│   └── HistoryScreen.tsx
├── services/        # Business logic
│   ├── trackingService.ts
│   ├── modeDetector.ts
│   └── storage.ts
├── store/          # State management (Zustand)
│   └── trackingStore.ts
├── types/          # TypeScript type definitions
│   └── index.ts
└── utils/          # Utility functions
    └── calculations.ts
```

### Adding New Features

1. **New Transportation Mode**
   - Update `TransportMode` enum in `src/types/index.ts`
   - Modify speed thresholds in `src/services/modeDetector.ts`
   - Update UI to display new mode

2. **Custom Map Tiles**
   - Modify the MapView `urlTemplate` prop in `MapScreen.tsx`
   - Example: `urlTemplate="https://your-tile-server.com/{z}/{x}/{y}.png"`

3. **Export Formats**
   - Add new export methods in `src/services/storage.ts`
   - Update SummaryScreen to include new export buttons

## Testing

### Manual Testing Checklist

- [ ] Start tracking session
- [ ] GPS points are recorded
- [ ] Mode detection works (walk, drive, train)
- [ ] Stop tracking and view summary
- [ ] Summary shows correct statistics
- [ ] View history of past sessions
- [ ] Delete a session
- [ ] Export session as JSON
- [ ] Export session as GPX
- [ ] App works offline (after initial map tile download)
- [ ] Background tracking works
- [ ] Permissions are requested properly

## Performance Tips

1. **Battery Optimization**
   - The app uses adaptive GPS update intervals
   - Slower updates when stationary
   - Faster updates when moving

2. **Storage Management**
   - Regularly delete old sessions to save space
   - Each GPS point takes ~100 bytes
   - A 1-hour trip with 5-second intervals = ~720 points = ~72KB

3. **Map Tile Caching**
   - Map tiles are cached by the OS
   - Clear app cache to free up space if needed

## Privacy & Data

- **No Cloud Sync**: All data stays on device
- **No Analytics**: No tracking or analytics
- **No Account**: No user registration or login
- **Local Only**: SQLite database is local to the device

## License

MIT License - See LICENSE file for details

## Support

For issues or questions, please open an issue on the GitHub repository.
