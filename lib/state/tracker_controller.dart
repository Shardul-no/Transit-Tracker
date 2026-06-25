import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/trip_models.dart';
import '../services/location_tracker.dart';
import '../services/trip_database.dart';
import '../utils/formatters.dart';
import '../utils/geo_math.dart';

class TrackerController extends ChangeNotifier {
  TrackerController({
    TripDatabase? database,
    LocationTracker? locationTracker,
  })  : _database = database ?? TripDatabase.instance,
        _locationTracker = locationTracker ?? LocationTracker();

  final TripDatabase _database;
  final LocationTracker _locationTracker;

  TripSnapshot _snapshot = TripSnapshot.idle();
  TripSnapshot get snapshot => _snapshot;

  final List<TripPoint> _currentPoints = <TripPoint>[];
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _sessionStart;

  Future<void> initialize() async {
    await _database.init();

    final activeSession = await _database.getActiveSession();
    if (activeSession != null) {
      _snapshot = _snapshot.copyWith(
        activeSessionId: activeSession.id,
        isBusy: false,
        statusMessage:
            'Found a stale active session. Tap Stop to close it or start fresh.',
      );
      notifyListeners();
    }
  }

  Future<void> refreshCurrentLocation() async {
    try {
      final position = await _locationTracker.getCurrentLocation();

      _snapshot = _snapshot.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        currentFixTime: position.timestamp,
        statusMessage: _snapshot.isTracking
            ? 'GPS warmed up. Waiting for live fixes.'
            : 'Showing your current location.',
      );
      notifyListeners();
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        statusMessage: 'Could not get current location: $error',
      );
      notifyListeners();
    }
  }

  Future<void> startTracking() async {
    if (_snapshot.isTracking || _snapshot.isBusy) return;

    _snapshot = _snapshot.copyWith(
      isBusy: true,
      statusMessage: 'Arming GPS and starting a new trip...',
    );
    notifyListeners();

    try {
      final sessionId = await _database.createSession();
      _sessionStart = DateTime.now();
      _currentPoints.clear();

      _snapshot = TripSnapshot(
        isTracking: true,
        isBusy: false,
        activeSessionId: sessionId,
        currentMode: TransportMode.unknown,
        currentSpeedMps: 0,
        totalDistanceMeters: 0,
        elapsed: Duration.zero,
        currentFixTime: null,
        latitude: null,
        longitude: null,
        route: const <LatLng>[],
        statusMessage: 'Tracking started. Waiting for the first GPS fix.',
      );
      notifyListeners();

      await refreshCurrentLocation();

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_snapshot.isTracking) return;
        final startedAt = _sessionStart;
        if (startedAt == null) return;
        _snapshot = _snapshot.copyWith(
          elapsed: DateTime.now().difference(startedAt),
        );
        notifyListeners();
      });

      _positionSubscription = await _locationTracker.start(
        onData: _handlePosition,
        onError: (error) {
          _snapshot = _snapshot.copyWith(
            statusMessage: 'Location error: $error',
            isBusy: false,
          );
          notifyListeners();
        },
      );
    } catch (error) {
      _timer?.cancel();
      _timer = null;
      _snapshot = TripSnapshot.idle().copyWith(
        statusMessage: 'Could not start tracking: $error',
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<int?> stopTracking() async {
    if (!_snapshot.isTracking && _snapshot.activeSessionId == null) {
      return null;
    }

    _snapshot = _snapshot.copyWith(
      isBusy: true,
      statusMessage: 'Finishing your trip...',
    );
    notifyListeners();

    final sessionId = _snapshot.activeSessionId;
    if (sessionId == null) {
      _snapshot = TripSnapshot.idle().copyWith(
        statusMessage: 'No active session found.',
      );
      notifyListeners();
      return null;
    }

    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _locationTracker.stop();
    _timer?.cancel();
    _timer = null;

    final summary = _buildSummary();
    await _database.completeSession(
      sessionId: sessionId,
      endTime: DateTime.now(),
      totalDistanceMeters: summary.totalDistanceMeters,
      totalDuration: summary.totalDuration,
      averageSpeedMps: summary.averageSpeedMps,
      walkingTime: summary.walkingTime,
      drivingTime: summary.drivingTime,
      trainTime: summary.trainTime,
    );

    _snapshot = TripSnapshot.idle().copyWith(
      statusMessage:
          'Trip saved. ${formatDistanceMeters(summary.totalDistanceMeters)} in ${formatDuration(summary.totalDuration)}.',
    );
    notifyListeners();

    _currentPoints.clear();
    _sessionStart = null;
    return sessionId;
  }

  Future<List<TripSession>> loadHistory() async {
    return _database.getHistory();
  }

  Future<TripSessionDetails?> loadSessionDetails(int sessionId) {
    return _database.getSessionDetails(sessionId);
  }

  Future<void> deleteSession(int sessionId) async {
    await _database.deleteSession(sessionId);
  }

  Future<void> clearHistory() async {
    await _database.clearHistory();
  }

  Future<String> exportSessionAsJson(int sessionId) {
    return _database.exportSessionAsJson(sessionId);
  }

  Future<String> exportSessionAsGpx(int sessionId) {
    return _database.exportSessionAsGpx(sessionId);
  }

  void _handlePosition(Position position) async {
    if (!_snapshot.isTracking || _snapshot.activeSessionId == null) {
      return;
    }

    final actualSpeed = position.speed < 0 ? 0.0 : position.speed;
    final mode = _detectMode(actualSpeed);
    final point = TripPoint(
      sessionId: _snapshot.activeSessionId!,
      timestamp: position.timestamp,
      latitude: position.latitude,
      longitude: position.longitude,
      speedMps: actualSpeed,
      mode: mode,
    );

    double additionalDistance = 0;
    if (_currentPoints.isNotEmpty) {
      final lastPoint = _currentPoints.last;
      additionalDistance = haversineDistanceMeters(
        lastPoint.latitude,
        lastPoint.longitude,
        point.latitude,
        point.longitude,
      );
    }

    _currentPoints.add(point);
    await _database.addPoint(point);

    final nextRoute = List<LatLng>.from(_snapshot.route)
      ..add(LatLng(point.latitude, point.longitude));

    _snapshot = _snapshot.copyWith(
      currentMode: mode,
      currentSpeedMps: actualSpeed,
      totalDistanceMeters: _snapshot.totalDistanceMeters + additionalDistance,
      currentFixTime: point.timestamp,
      latitude: point.latitude,
      longitude: point.longitude,
      route: nextRoute,
      statusMessage: 'GPS fix captured. ${mode.label} at ${formatSpeedMps(actualSpeed)}.',
    );
    notifyListeners();
  }

  TripSession _buildSummary() {
    if (_currentPoints.isEmpty || _sessionStart == null) {
      final now = DateTime.now();
      return TripSession(
        startTime: _sessionStart ?? now,
        endTime: now,
        totalDistanceMeters: 0,
        totalDuration: Duration.zero,
        averageSpeedMps: 0,
        walkingTime: Duration.zero,
        drivingTime: Duration.zero,
        trainTime: Duration.zero,
        isActive: false,
      );
    }

    var walkingSeconds = 0;
    var drivingSeconds = 0;
    var trainSeconds = 0;
    var totalDistance = 0.0;

    for (var i = 1; i < _currentPoints.length; i++) {
      final previous = _currentPoints[i - 1];
      final current = _currentPoints[i];
      final deltaSeconds =
          current.timestamp.difference(previous.timestamp).inSeconds;
      totalDistance += haversineDistanceMeters(
        previous.latitude,
        previous.longitude,
        current.latitude,
        current.longitude,
      );

      switch (current.mode) {
        case TransportMode.walking:
          walkingSeconds += deltaSeconds;
          break;
        case TransportMode.driving:
          drivingSeconds += deltaSeconds;
          break;
        case TransportMode.train:
          trainSeconds += deltaSeconds;
          break;
        case TransportMode.unknown:
          break;
      }
    }

    final startTime = _sessionStart!;
    final endTime = _currentPoints.last.timestamp;
    final totalDuration = endTime.difference(startTime);
    final averageSpeed = totalDuration.inSeconds > 0
        ? totalDistance / totalDuration.inSeconds
        : 0.0;

    return TripSession(
      startTime: startTime,
      endTime: endTime,
      totalDistanceMeters: totalDistance,
      totalDuration: totalDuration,
      averageSpeedMps: averageSpeed,
      walkingTime: Duration(seconds: walkingSeconds),
      drivingTime: Duration(seconds: drivingSeconds),
      trainTime: Duration(seconds: trainSeconds),
      isActive: false,
    );
  }

  TransportMode _detectMode(double speedMps) {
    if (speedMps < 0) return TransportMode.unknown;
    if (speedMps < 3) return TransportMode.walking;
    if (speedMps < 22) return TransportMode.driving;
    return TransportMode.train;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _locationTracker.stop();
    super.dispose();
  }
}
