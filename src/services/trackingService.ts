import Geolocation from 'react-native-geolocation-service';
import { TransportMode, GPSPoint } from '../types';
import { detectMode } from './modeDetector';
import storageService from './storage';
import { calculateDistance } from '../utils/calculations';

export interface LocationUpdate {
  latitude: number;
  longitude: number;
  speed: number;
  timestamp: number;
  mode: TransportMode;
}

class TrackingService {
  private watchId: number | null = null;
  private currentSessionId: number | null = null;
  private lastLocation: LocationUpdate | null = null;
  private isTracking = false;
  private updateInterval = 5000; // Start with 5 seconds
  private stationaryThreshold = 0.5; // m/s - consider stationary below this
  private listeners: ((update: LocationUpdate) => void)[] = [];

  /**
   * Start tracking GPS location
   */
  async startTracking(): Promise<number> {
    if (this.isTracking) {
      throw new Error('Tracking already in progress');
    }

    // Create new session in database
    this.currentSessionId = await storageService.createSession();
    this.isTracking = true;
    this.lastLocation = null;

    // Start watching location
    this.watchId = Geolocation.watchPosition(
      position => {
        this.handleLocationUpdate(position);
      },
      error => {
        console.error('Location error:', error);
      },
      {
        enableHighAccuracy: true,
        distanceFilter: 5, // Update every 5 meters
        interval: this.updateInterval,
        fastestInterval: 3000,
        showsBackgroundLocationIndicator: true,
        forceRequestLocation: true,
      },
    );

    return this.currentSessionId;
  }

  /**
   * Stop tracking and finalize session
   */
  async stopTracking(): Promise<number | null> {
    if (!this.isTracking || this.currentSessionId === null) {
      return null;
    }

    // Stop watching location
    if (this.watchId !== null) {
      Geolocation.clearWatch(this.watchId);
      this.watchId = null;
    }

    const sessionId = this.currentSessionId;

    // Calculate session summary
    const sessionData = await storageService.getSessionWithPoints(sessionId);
    if (sessionData) {
      const summary = this.calculateSessionSummary(sessionData.points);
      await storageService.endSession(sessionId, summary);
    }

    this.isTracking = false;
    this.currentSessionId = null;
    this.lastLocation = null;

    return sessionId;
  }

  /**
   * Handle incoming location update
   */
  private async handleLocationUpdate(
    position: Geolocation.GeoPosition,
  ): Promise<void> {
    if (!this.currentSessionId) return;

    const { latitude, longitude, speed, timestamp } = position.coords;
    const actualSpeed = speed !== null && speed >= 0 ? speed : 0;
    const mode = detectMode(actualSpeed);

    const update: LocationUpdate = {
      latitude,
      longitude,
      speed: actualSpeed,
      timestamp,
      mode,
    };

    // Save to database
    const point: Omit<GPSPoint, 'id'> = {
      sessionId: this.currentSessionId,
      timestamp,
      latitude,
      longitude,
      speed: actualSpeed,
      mode,
    };

    await storageService.addGPSPoint(point);

    // Adjust update interval based on movement
    this.adjustUpdateInterval(actualSpeed);

    // Notify listeners
    this.notifyListeners(update);

    this.lastLocation = update;
  }

  /**
   * Adjust GPS update interval based on speed (battery optimization)
   */
  private adjustUpdateInterval(speed: number): void {
    if (speed < this.stationaryThreshold) {
      // Stationary - update less frequently
      this.updateInterval = 30000; // 30 seconds
    } else if (speed < 3) {
      // Walking - moderate updates
      this.updateInterval = 10000; // 10 seconds
    } else {
      // Moving fast - frequent updates
      this.updateInterval = 5000; // 5 seconds
    }
  }

  /**
   * Calculate session summary from GPS points
   */
  private calculateSessionSummary(points: GPSPoint[]) {
    if (points.length === 0) {
      return {
        endTime: Date.now(),
        totalDistance: 0,
        totalDuration: 0,
        averageSpeed: 0,
        walkingTime: 0,
        drivingTime: 0,
        trainTime: 0,
      };
    }

    let totalDistance = 0;
    let walkingTime = 0;
    let drivingTime = 0;
    let trainTime = 0;

    // Calculate distance and time per mode
    for (let i = 1; i < points.length; i++) {
      const prev = points[i - 1];
      const curr = points[i];

      const distance = calculateDistance(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );
      totalDistance += distance;

      const timeDiff = (curr.timestamp - prev.timestamp) / 1000; // seconds

      switch (curr.mode) {
        case TransportMode.WALKING:
          walkingTime += timeDiff;
          break;
        case TransportMode.DRIVING:
          drivingTime += timeDiff;
          break;
        case TransportMode.TRAIN:
          trainTime += timeDiff;
          break;
      }
    }

    const startTime = points[0].timestamp;
    const endTime = points[points.length - 1].timestamp;
    const totalDuration = (endTime - startTime) / 1000; // seconds

    const averageSpeed =
      totalDuration > 0 ? totalDistance / totalDuration : 0;

    return {
      endTime,
      totalDistance,
      totalDuration,
      averageSpeed,
      walkingTime,
      drivingTime,
      trainTime,
    };
  }

  /**
   * Get current location once
   */
  async getCurrentLocation(): Promise<LocationUpdate | null> {
    return new Promise((resolve, reject) => {
      Geolocation.getCurrentPosition(
        position => {
          const { latitude, longitude, speed, timestamp } = position.coords;
          const actualSpeed = speed !== null && speed >= 0 ? speed : 0;
          const mode = detectMode(actualSpeed);

          resolve({
            latitude,
            longitude,
            speed: actualSpeed,
            timestamp,
            mode,
          });
        },
        error => {
          console.error('Error getting current location:', error);
          reject(error);
        },
        {
          enableHighAccuracy: true,
          timeout: 15000,
          maximumAge: 10000,
        },
      );
    });
  }

  /**
   * Subscribe to location updates
   */
  addListener(callback: (update: LocationUpdate) => void): () => void {
    this.listeners.push(callback);

    // Return unsubscribe function
    return () => {
      this.listeners = this.listeners.filter(cb => cb !== callback);
    };
  }

  /**
   * Notify all listeners of location update
   */
  private notifyListeners(update: LocationUpdate): void {
    this.listeners.forEach(callback => callback(update));
  }

  /**
   * Check if currently tracking
   */
  getIsTracking(): boolean {
    return this.isTracking;
  }

  /**
   * Get current session ID
   */
  getCurrentSessionId(): number | null {
    return this.currentSessionId;
  }

  /**
   * Get last known location
   */
  getLastLocation(): LocationUpdate | null {
    return this.lastLocation;
  }
}

export default new TrackingService();
