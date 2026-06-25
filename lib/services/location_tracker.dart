import 'dart:async';
import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationTracker {
  StreamSubscription<Position>? _subscription;

  Future<Position> getCurrentLocation() async {
    await _ensureLocationPermission(requireBackground: false);

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
  }

  Future<StreamSubscription<Position>> start({
    required void Function(Position position) onData,
    required void Function(Object error) onError,
  }) async {
    await _ensureLocationPermission(requireBackground: true);

    final settings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
      intervalDuration: const Duration(seconds: 5),
      forceLocationManager: true,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Transit Pulse is tracking',
        notificationText: 'Your trip is being recorded in the background.',
        notificationChannelName: 'Transit tracking',
        setOngoing: true,
        enableWakeLock: true,
      ),
    );

    _subscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      onData,
      onError: onError,
      cancelOnError: false,
    );

    return _subscription!;
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _ensureLocationPermission({
    required bool requireBackground,
  }) async {
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        final notificationResult = await Permission.notification.request();
        if (!notificationResult.isGranted) {
          throw StateError(
            'Notification permission is required so Android can keep the tracking service alive.',
          );
        }
      }
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('Location services are disabled.');
    }

    final whenInUseStatus = await Permission.locationWhenInUse.request();
    if (!whenInUseStatus.isGranted) {
      throw StateError('Location permission was denied.');
    }

    if (requireBackground) {
      final backgroundStatus = await Permission.locationAlways.request();
      if (!backgroundStatus.isGranted) {
        throw StateError(
          'Background location permission is required for trip tracking. Open app settings and allow location access "all the time".',
        );
      }
    }

    final geolocatorPermission = await Geolocator.checkPermission();
    if (geolocatorPermission == LocationPermission.denied ||
        geolocatorPermission == LocationPermission.deniedForever) {
      throw StateError('Location permission was denied.');
    }
  }
}
