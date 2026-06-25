import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum TransportMode { walking, driving, train, unknown }

extension TransportModeX on TransportMode {
  String get label {
    switch (this) {
      case TransportMode.walking:
        return 'Walking';
      case TransportMode.driving:
        return 'Driving';
      case TransportMode.train:
        return 'Train';
      case TransportMode.unknown:
        return 'Unknown';
    }
  }

  IconData get icon {
    switch (this) {
      case TransportMode.walking:
        return Icons.directions_walk;
      case TransportMode.driving:
        return Icons.directions_car;
      case TransportMode.train:
        return Icons.train;
      case TransportMode.unknown:
        return Icons.help_outline;
    }
  }

  Color get color {
    switch (this) {
      case TransportMode.walking:
        return const Color(0xFF21C58E);
      case TransportMode.driving:
        return const Color(0xFF5DA9FF);
      case TransportMode.train:
        return const Color(0xFFF1B24A);
      case TransportMode.unknown:
        return const Color(0xFF8E98B7);
    }
  }
}

class TripPoint {
  final int? id;
  final int sessionId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double speedMps;
  final TransportMode mode;

  const TripPoint({
    this.id,
    required this.sessionId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.speedMps,
    required this.mode,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speedMps,
      'mode': mode.name,
    };
  }

  factory TripPoint.fromMap(Map<String, Object?> map) {
    return TripPoint(
      id: map['id'] as int?,
      sessionId: map['sessionId'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      speedMps: (map['speed'] as num).toDouble(),
      mode: TransportMode.values.firstWhere(
        (value) => value.name == map['mode'],
        orElse: () => TransportMode.unknown,
      ),
    );
  }
}

class TripSession {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalDistanceMeters;
  final Duration totalDuration;
  final double averageSpeedMps;
  final Duration walkingTime;
  final Duration drivingTime;
  final Duration trainTime;
  final bool isActive;

  const TripSession({
    this.id,
    required this.startTime,
    this.endTime,
    required this.totalDistanceMeters,
    required this.totalDuration,
    required this.averageSpeedMps,
    required this.walkingTime,
    required this.drivingTime,
    required this.trainTime,
    required this.isActive,
  });

  TripSession copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    double? totalDistanceMeters,
    Duration? totalDuration,
    double? averageSpeedMps,
    Duration? walkingTime,
    Duration? drivingTime,
    Duration? trainTime,
    bool? isActive,
  }) {
    return TripSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      totalDuration: totalDuration ?? this.totalDuration,
      averageSpeedMps: averageSpeedMps ?? this.averageSpeedMps,
      walkingTime: walkingTime ?? this.walkingTime,
      drivingTime: drivingTime ?? this.drivingTime,
      trainTime: trainTime ?? this.trainTime,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'totalDistance': totalDistanceMeters,
      'totalDuration': totalDuration.inSeconds,
      'averageSpeed': averageSpeedMps,
      'walkingTime': walkingTime.inSeconds,
      'drivingTime': drivingTime.inSeconds,
      'trainTime': trainTime.inSeconds,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory TripSession.fromMap(Map<String, Object?> map) {
    return TripSession(
      id: map['id'] as int?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int),
      endTime: map['endTime'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int),
      totalDistanceMeters: (map['totalDistance'] as num).toDouble(),
      totalDuration: Duration(seconds: (map['totalDuration'] as num).toInt()),
      averageSpeedMps: (map['averageSpeed'] as num).toDouble(),
      walkingTime: Duration(seconds: (map['walkingTime'] as num).toInt()),
      drivingTime: Duration(seconds: (map['drivingTime'] as num).toInt()),
      trainTime: Duration(seconds: (map['trainTime'] as num).toInt()),
      isActive: (map['isActive'] as num).toInt() == 1,
    );
  }
}

class TripSessionDetails {
  final TripSession session;
  final List<TripPoint> points;

  const TripSessionDetails({
    required this.session,
    required this.points,
  });
}

class TripSnapshot {
  final bool isTracking;
  final bool isBusy;
  final int? activeSessionId;
  final TransportMode currentMode;
  final double currentSpeedMps;
  final double totalDistanceMeters;
  final Duration elapsed;
  final DateTime? currentFixTime;
  final double? latitude;
  final double? longitude;
  final List<LatLng> route;
  final String? statusMessage;

  const TripSnapshot({
    required this.isTracking,
    required this.isBusy,
    required this.activeSessionId,
    required this.currentMode,
    required this.currentSpeedMps,
    required this.totalDistanceMeters,
    required this.elapsed,
    required this.currentFixTime,
    required this.latitude,
    required this.longitude,
    required this.route,
    required this.statusMessage,
  });

  factory TripSnapshot.idle() {
    return const TripSnapshot(
      isTracking: false,
      isBusy: false,
      activeSessionId: null,
      currentMode: TransportMode.unknown,
      currentSpeedMps: 0,
      totalDistanceMeters: 0,
      elapsed: Duration.zero,
      currentFixTime: null,
      latitude: null,
      longitude: null,
      route: <LatLng>[],
      statusMessage: null,
    );
  }

  TripSnapshot copyWith({
    bool? isTracking,
    bool? isBusy,
    int? activeSessionId,
    TransportMode? currentMode,
    double? currentSpeedMps,
    double? totalDistanceMeters,
    Duration? elapsed,
    DateTime? currentFixTime,
    double? latitude,
    double? longitude,
    List<LatLng>? route,
    String? statusMessage,
  }) {
    return TripSnapshot(
      isTracking: isTracking ?? this.isTracking,
      isBusy: isBusy ?? this.isBusy,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      currentMode: currentMode ?? this.currentMode,
      currentSpeedMps: currentSpeedMps ?? this.currentSpeedMps,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      elapsed: elapsed ?? this.elapsed,
      currentFixTime: currentFixTime ?? this.currentFixTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      route: route ?? this.route,
      statusMessage: statusMessage,
    );
  }
}
