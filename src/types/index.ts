export enum TransportMode {
  WALKING = 'walking',
  DRIVING = 'driving',
  TRAIN = 'train',
  UNKNOWN = 'unknown',
}

export interface GPSPoint {
  id?: number;
  sessionId: number;
  timestamp: number;
  latitude: number;
  longitude: number;
  speed: number;
  mode: TransportMode;
}

export interface Session {
  id?: number;
  startTime: number;
  endTime?: number;
  totalDistance: number;
  totalDuration: number;
  averageSpeed: number;
  walkingTime: number;
  drivingTime: number;
  trainTime: number;
  isActive: boolean;
}

export interface SessionSummary extends Session {
  points: GPSPoint[];
}

export interface TrackingState {
  isTracking: boolean;
  currentSession: Session | null;
  currentMode: TransportMode;
  elapsedTime: number;
  currentSpeed: number;
  totalDistance: number;
}
