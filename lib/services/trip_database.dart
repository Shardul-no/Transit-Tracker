import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/trip_models.dart';

class TripDatabase {
  TripDatabase._();

  static final TripDatabase instance = TripDatabase._();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'transit_pulse.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            startTime INTEGER NOT NULL,
            endTime INTEGER,
            totalDistance REAL DEFAULT 0,
            totalDuration INTEGER DEFAULT 0,
            averageSpeed REAL DEFAULT 0,
            walkingTime INTEGER DEFAULT 0,
            drivingTime INTEGER DEFAULT 0,
            trainTime INTEGER DEFAULT 0,
            isActive INTEGER DEFAULT 1
          );
        ''');

        await db.execute('''
          CREATE TABLE points (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sessionId INTEGER NOT NULL,
            timestamp INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            speed REAL DEFAULT 0,
            mode TEXT NOT NULL,
            FOREIGN KEY (sessionId) REFERENCES sessions(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE INDEX idx_points_sessionId ON points(sessionId);
        ''');
      },
    );
  }

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('Database has not been initialized.');
    }
    return db;
  }

  Future<int> createSession() async {
    final session = TripSession(
      startTime: DateTime.now(),
      endTime: null,
      totalDistanceMeters: 0,
      totalDuration: Duration.zero,
      averageSpeedMps: 0,
      walkingTime: Duration.zero,
      drivingTime: Duration.zero,
      trainTime: Duration.zero,
      isActive: true,
    );

    return _database.insert('sessions', session.toMap());
  }

  Future<void> addPoint(TripPoint point) async {
    await _database.insert('points', point.toMap());
  }

  Future<void> completeSession({
    required int sessionId,
    required DateTime endTime,
    required double totalDistanceMeters,
    required Duration totalDuration,
    required double averageSpeedMps,
    required Duration walkingTime,
    required Duration drivingTime,
    required Duration trainTime,
  }) async {
    await _database.update(
      'sessions',
      {
        'endTime': endTime.millisecondsSinceEpoch,
        'totalDistance': totalDistanceMeters,
        'totalDuration': totalDuration.inSeconds,
        'averageSpeed': averageSpeedMps,
        'walkingTime': walkingTime.inSeconds,
        'drivingTime': drivingTime.inSeconds,
        'trainTime': trainTime.inSeconds,
        'isActive': 0,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<List<TripSession>> getHistory() async {
    final rows = await _database.query(
      'sessions',
      where: 'isActive = 0',
      orderBy: 'startTime DESC',
    );
    return rows.map(TripSession.fromMap).toList();
  }

  Future<TripSession?> getSession(int sessionId) async {
    final rows = await _database.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TripSession.fromMap(rows.first);
  }

  Future<TripSession?> getActiveSession() async {
    final rows = await _database.query(
      'sessions',
      where: 'isActive = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TripSession.fromMap(rows.first);
  }

  Future<TripSessionDetails?> getSessionDetails(int sessionId) async {
    final session = await getSession(sessionId);
    if (session == null) return null;

    final pointRows = await _database.query(
      'points',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    final points = pointRows.map(TripPoint.fromMap).toList();
    return TripSessionDetails(session: session, points: points);
  }

  Future<void> deleteSession(int sessionId) async {
    await _database.delete('points', where: 'sessionId = ?', whereArgs: [sessionId]);
    await _database.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  Future<void> clearHistory() async {
    final completedSessions = await _database.query(
      'sessions',
      columns: ['id'],
      where: 'isActive = 0',
    );

    final sessionIds = completedSessions
        .map((row) => row['id'] as int)
        .toList(growable: false);

    if (sessionIds.isEmpty) {
      return;
    }

    final placeholders = List.filled(sessionIds.length, '?').join(', ');
    await _database.delete(
      'points',
      where: 'sessionId IN ($placeholders)',
      whereArgs: sessionIds,
    );
    await _database.delete(
      'sessions',
      where: 'id IN ($placeholders)',
      whereArgs: sessionIds,
    );
  }

  Future<String> exportSessionAsJson(int sessionId) async {
    final details = await getSessionDetails(sessionId);
    if (details == null) {
      throw StateError('Session not found.');
    }

    final payload = {
      'session': details.session.toMap(),
      'points': details.points.map((point) => point.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<String> exportSessionAsGpx(int sessionId) async {
    final details = await getSessionDetails(sessionId);
    if (details == null) {
      throw StateError('Session not found.');
    }

    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<gpx version="1.1" creator="Transit Pulse">')
      ..writeln('  <metadata>')
      ..writeln('    <name>Transit Pulse Session $sessionId</name>')
      ..writeln(
        '    <time>${details.session.startTime.toUtc().toIso8601String()}</time>',
      )
      ..writeln('  </metadata>')
      ..writeln('  <trk>')
      ..writeln('    <name>Session $sessionId</name>')
      ..writeln('    <trkseg>');

    for (final point in details.points) {
      buffer
        ..writeln(
          '      <trkpt lat="${point.latitude}" lon="${point.longitude}">',
        )
        ..writeln('        <ele>0</ele>')
        ..writeln(
          '        <time>${point.timestamp.toUtc().toIso8601String()}</time>',
        )
        ..writeln('        <extensions>')
        ..writeln('          <speed>${point.speedMps}</speed>')
        ..writeln('          <mode>${point.mode.name}</mode>')
        ..writeln('        </extensions>')
        ..writeln('      </trkpt>');
    }

    buffer
      ..writeln('    </trkseg>')
      ..writeln('  </trk>')
      ..writeln('</gpx>');

    return buffer.toString();
  }
}
