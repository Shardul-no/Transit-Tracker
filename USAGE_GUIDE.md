# Transit Tracker - User Guide

## Overview

Transit Tracker is a privacy-focused mobile app that tracks your movement and automatically detects your mode of transportation (walking, driving, or train). All data is stored locally on your device with no account required.

## Features

### 🗺️ Real-time Tracking
- Start and stop tracking with a single tap
- See your route on an interactive map
- Real-time mode detection
- Live statistics (distance, duration, speed)

### 📊 Session Summaries
- Detailed trip statistics
- Time spent in each transportation mode
- Total distance and duration
- Average speed

### 📋 Trip History
- View all past trips
- Tap to see detailed summary
- Long-press to delete trips

### 💾 Export Options
- Export trips as JSON
- Export trips as GPX (GPS Exchange Format)
- Share via any app

## Getting Started

### First Launch

1. **Grant Permissions**
   - The app will request location permissions
   - Choose "Allow While Using App" or "Always Allow"
   - Background location is needed for continuous tracking

2. **Map View**
   - You'll see a map centered on your current location
   - The large circular button at the bottom is for starting/stopping tracking

### Starting a Trip

1. Tap the green **Start** button
2. The button turns red and shows **Stop**
3. A top bar appears showing:
   - Current transportation mode (🚶 Walking, 🚗 Driving, 🚆 Train)
   - Elapsed time
   - Distance traveled
   - Current speed

### During Tracking

- **Map Updates**: Your route is drawn in blue on the map
- **Mode Detection**: The app automatically detects your transportation mode based on speed:
  - Walking: < 10.8 km/h
  - Driving: 10.8 - 79.2 km/h
  - Train: > 79.2 km/h
- **Battery Optimization**: GPS updates adapt to your movement
  - Faster when moving
  - Slower when stationary

### Stopping a Trip

1. Tap the red **Stop** button
2. You'll be taken to the **Summary Screen**
3. Review your trip statistics

## Summary Screen

After stopping a trip, you'll see:

### Main Statistics
- **Total Distance**: How far you traveled
- **Total Duration**: How long the trip took
- **Average Speed**: Your average speed
- **Start/End Time**: When the trip began and ended

### Transportation Modes
- Time spent walking 🚶
- Time spent driving 🚗
- Time spent on train 🚆

### Route Details
- Number of GPS points recorded

### Export Options
- **Export as JSON**: Raw data in JSON format
- **Export as GPX**: Standard GPS format (compatible with most GPS apps)

## History Screen

Access your trip history by tapping the **📋 History** button on the map screen.

### Viewing Past Trips
- Trips are listed newest first
- Each card shows:
  - Date and time
  - Distance and duration
  - Transportation modes used

### Actions
- **Tap**: View detailed summary
- **Long-press**: Delete trip (with confirmation)

## Tips & Best Practices

### For Best Results

1. **Location Accuracy**
   - Enable "High Accuracy" location mode in device settings
   - Use on a physical device (not simulator)
   - Ensure clear view of sky for GPS signal

2. **Battery Life**
   - The app uses adaptive GPS updates to save battery
   - Consider using a power bank for very long trips
   - Close other apps to reduce battery drain

3. **Data Storage**
   - Each trip takes minimal storage (~72KB per hour)
   - Regularly delete old trips you don't need
   - Export important trips before deleting

### Privacy & Security

- ✅ **No Account Required**: No sign-up or login
- ✅ **Offline First**: Works completely offline (except map tiles)
- ✅ **Local Storage**: All data stays on your device
- ✅ **No Cloud Sync**: Your data never leaves your phone
- ✅ **No Analytics**: No tracking or data collection

## Transportation Mode Detection

The app uses GPS speed to detect your mode of transportation:

| Mode | Speed Range | Icon |
|------|-------------|------|
| Walking | 0 - 10.8 km/h | 🚶 |
| Driving | 10.8 - 79.2 km/h | 🚗 |
| Train | > 79.2 km/h | 🚆 |

**Note**: Detection is automatic and happens in real-time. The mode shown is based on your current speed.

## Exporting Data

### JSON Format
```json
{
  "id": 1,
  "startTime": 1234567890000,
  "endTime": 1234571490000,
  "totalDistance": 5420.5,
  "totalDuration": 3600,
  "averageSpeed": 1.5,
  "walkingTime": 1800,
  "drivingTime": 1800,
  "trainTime": 0,
  "points": [...]
}
```

### GPX Format
Standard GPS Exchange Format compatible with:
- Google Earth
- Strava
- Garmin devices
- Most GPS applications

## Troubleshooting

### Location Not Updating

**Problem**: GPS location isn't updating during tracking

**Solutions**:
1. Check location permissions are granted
2. Enable "High Accuracy" location mode
3. Ensure GPS is enabled
4. Move to an area with clear sky view
5. Restart the app

### Map Not Loading

**Problem**: Map tiles aren't loading

**Solutions**:
1. Check internet connection
2. Verify internet permission is granted
3. Try switching between WiFi and mobile data
4. Clear app cache

### Mode Detection Incorrect

**Problem**: Wrong transportation mode is detected

**Solutions**:
1. This is based on GPS speed, which can be inaccurate
2. Speed detection improves with better GPS signal
3. Mode is calculated in real-time and may fluctuate
4. Summary shows total time per mode, which is more accurate

### App Crashes

**Problem**: App crashes or freezes

**Solutions**:
1. Restart the app
2. Clear app cache
3. Reinstall the app (data will be lost)
4. Check device storage space
5. Update to latest version

### Battery Draining Fast

**Problem**: App uses too much battery

**Solutions**:
1. The app is designed to be battery-efficient
2. Close other apps running in background
3. Reduce screen brightness
4. Use battery saver mode (may affect GPS accuracy)

## Frequently Asked Questions

### Q: Does this app require internet?

**A**: Only for downloading map tiles. GPS tracking works completely offline. Once map tiles are cached, you can use the app without internet.

### Q: Can I use this app without creating an account?

**A**: Yes! No account or sign-up required. The app is completely anonymous.

### Q: Where is my data stored?

**A**: All data is stored locally on your device in a SQLite database. Nothing is sent to any server.

### Q: Can I backup my trips?

**A**: Export your trips as JSON or GPX files and save them to cloud storage manually.

### Q: How accurate is the tracking?

**A**: Accuracy depends on GPS signal quality. Typically 5-10 meters in open areas, less accurate in buildings or tunnels.

### Q: Does tracking work in the background?

**A**: Yes, if you grant "Always Allow" location permission. The app will continue tracking even when minimized.

### Q: How much storage does the app use?

**A**: Very little. A 1-hour trip with 5-second GPS intervals uses approximately 72KB.

### Q: Can I edit or merge trips?

**A**: Not currently. This feature may be added in future versions.

### Q: Is my location data shared with anyone?

**A**: No. All data stays on your device. The app has no analytics, no tracking, and no cloud sync.

## Support

For issues, questions, or feature requests, please visit the GitHub repository or contact support.

## Version History

### v1.0.0 (Current)
- Initial release
- GPS tracking with mode detection
- Offline SQLite storage
- OpenStreetMap integration
- Trip summaries and history
- JSON and GPX export
