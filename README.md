# Transit Pulse

Transit Pulse is an Android-only Flutter app for recording trips offline on-device.

## What it does

- Starts and stops GPS trip recording
- Detects walking, driving, and train based on speed
- Draws the route on an OpenStreetMap-backed map
- Stores sessions locally in SQLite
- Shows trip history and trip summaries
- Exports trips as JSON or GPX

## Tech stack

- Flutter
- geolocator
- flutter_map
- sqflite
- google_fonts
- share_plus

## Run it

```bash
flutter pub get
flutter run
```

## Notes

- Android only
- Background tracking uses a foreground service notification on Android
- Location and notification permissions are required for best results

