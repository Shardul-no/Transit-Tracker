import SQLite from 'react-native-sqlite-storage';
import { Session, GPSPoint, SessionSummary, TransportMode } from '../types';

SQLite.enablePromise(true);

class StorageService {
  private db: SQLite.SQLiteDatabase | null = null;

  async init(): Promise<void> {
    try {
      this.db = await SQLite.openDatabase({
        name: 'TransitTracker.db',
        location: 'default',
      });

      await this.createTables();
      console.log('Database initialized successfully');
    } catch (error) {
      console.error('Error initializing database:', error);
      throw error;
    }
  }

  private async createTables(): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    // Create sessions table
    await this.db.executeSql(`
      CREATE TABLE IF NOT EXISTS sessions (
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
    `);

    // Create GPS points table
    await this.db.executeSql(`
      CREATE TABLE IF NOT EXISTS gps_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        speed REAL DEFAULT 0,
        mode TEXT NOT NULL,
        FOREIGN KEY (sessionId) REFERENCES sessions(id)
      );
    `);

    // Create index for faster queries
    await this.db.executeSql(`
      CREATE INDEX IF NOT EXISTS idx_session_points 
      ON gps_points(sessionId);
    `);
  }

  async createSession(): Promise<number> {
    if (!this.db) throw new Error('Database not initialized');

    const startTime = Date.now();
    const result = await this.db.executeSql(
      'INSERT INTO sessions (startTime, isActive) VALUES (?, 1)',
      [startTime],
    );

    return result[0].insertId;
  }

  async endSession(sessionId: number, summary: Partial<Session>): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    await this.db.executeSql(
      `UPDATE sessions 
       SET endTime = ?, 
           totalDistance = ?, 
           totalDuration = ?, 
           averageSpeed = ?,
           walkingTime = ?,
           drivingTime = ?,
           trainTime = ?,
           isActive = 0
       WHERE id = ?`,
      [
        summary.endTime || Date.now(),
        summary.totalDistance || 0,
        summary.totalDuration || 0,
        summary.averageSpeed || 0,
        summary.walkingTime || 0,
        summary.drivingTime || 0,
        summary.trainTime || 0,
        sessionId,
      ],
    );
  }

  async addGPSPoint(point: Omit<GPSPoint, 'id'>): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    await this.db.executeSql(
      `INSERT INTO gps_points 
       (sessionId, timestamp, latitude, longitude, speed, mode) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        point.sessionId,
        point.timestamp,
        point.latitude,
        point.longitude,
        point.speed,
        point.mode,
      ],
    );
  }

  async getSession(sessionId: number): Promise<Session | null> {
    if (!this.db) throw new Error('Database not initialized');

    const result = await this.db.executeSql(
      'SELECT * FROM sessions WHERE id = ?',
      [sessionId],
    );

    if (result[0].rows.length === 0) return null;

    const row = result[0].rows.item(0);
    return this.mapRowToSession(row);
  }

  async getSessionWithPoints(sessionId: number): Promise<SessionSummary | null> {
    if (!this.db) throw new Error('Database not initialized');

    const session = await this.getSession(sessionId);
    if (!session) return null;

    const pointsResult = await this.db.executeSql(
      'SELECT * FROM gps_points WHERE sessionId = ? ORDER BY timestamp ASC',
      [sessionId],
    );

    const points: GPSPoint[] = [];
    for (let i = 0; i < pointsResult[0].rows.length; i++) {
      points.push(this.mapRowToGPSPoint(pointsResult[0].rows.item(i)));
    }

    return { ...session, points };
  }

  async getAllSessions(): Promise<Session[]> {
    if (!this.db) throw new Error('Database not initialized');

    const result = await this.db.executeSql(
      'SELECT * FROM sessions WHERE isActive = 0 ORDER BY startTime DESC',
    );

    const sessions: Session[] = [];
    for (let i = 0; i < result[0].rows.length; i++) {
      sessions.push(this.mapRowToSession(result[0].rows.item(i)));
    }

    return sessions;
  }

  async getActiveSession(): Promise<Session | null> {
    if (!this.db) throw new Error('Database not initialized');

    const result = await this.db.executeSql(
      'SELECT * FROM sessions WHERE isActive = 1 LIMIT 1',
    );

    if (result[0].rows.length === 0) return null;

    return this.mapRowToSession(result[0].rows.item(0));
  }

  async deleteSession(sessionId: number): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');

    await this.db.executeSql('DELETE FROM gps_points WHERE sessionId = ?', [
      sessionId,
    ]);
    await this.db.executeSql('DELETE FROM sessions WHERE id = ?', [sessionId]);
  }

  async exportSessionAsJSON(sessionId: number): Promise<string> {
    const sessionData = await this.getSessionWithPoints(sessionId);
    if (!sessionData) throw new Error('Session not found');

    return JSON.stringify(sessionData, null, 2);
  }

  async exportSessionAsGPX(sessionId: number): Promise<string> {
    const sessionData = await this.getSessionWithPoints(sessionId);
    if (!sessionData) throw new Error('Session not found');

    const gpx = `<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="Transit Tracker">
  <metadata>
    <name>Transit Tracker Session ${sessionId}</name>
    <time>${new Date(sessionData.startTime).toISOString()}</time>
  </metadata>
  <trk>
    <name>Session ${sessionId}</name>
    <trkseg>
${sessionData.points
  .map(
    point => `      <trkpt lat="${point.latitude}" lon="${point.longitude}">
        <ele>0</ele>
        <time>${new Date(point.timestamp).toISOString()}</time>
        <extensions>
          <speed>${point.speed}</speed>
          <mode>${point.mode}</mode>
        </extensions>
      </trkpt>`,
  )
  .join('\n')}
    </trkseg>
  </trk>
</gpx>`;

    return gpx;
  }

  private mapRowToSession(row: any): Session {
    return {
      id: row.id,
      startTime: row.startTime,
      endTime: row.endTime,
      totalDistance: row.totalDistance,
      totalDuration: row.totalDuration,
      averageSpeed: row.averageSpeed,
      walkingTime: row.walkingTime,
      drivingTime: row.drivingTime,
      trainTime: row.trainTime,
      isActive: row.isActive === 1,
    };
  }

  private mapRowToGPSPoint(row: any): GPSPoint {
    return {
      id: row.id,
      sessionId: row.sessionId,
      timestamp: row.timestamp,
      latitude: row.latitude,
      longitude: row.longitude,
      speed: row.speed,
      mode: row.mode as TransportMode,
    };
  }
}

export default new StorageService();
