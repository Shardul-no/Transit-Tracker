import { create } from 'zustand';
import { TransportMode, Session } from '../types';
import trackingService, { LocationUpdate } from '../services/trackingService';
import storageService from '../services/storage';

interface TrackingStore {
  // State
  isTracking: boolean;
  currentSession: Session | null;
  currentMode: TransportMode;
  currentSpeed: number;
  currentLocation: { latitude: number; longitude: number } | null;
  elapsedTime: number;
  totalDistance: number;
  routeCoordinates: { latitude: number; longitude: number }[];

  // Actions
  startTracking: () => Promise<void>;
  stopTracking: () => Promise<number | null>;
  updateLocation: (update: LocationUpdate) => void;
  incrementElapsedTime: () => void;
  resetTracking: () => void;
  loadActiveSession: () => Promise<void>;
}

export const useTrackingStore = create<TrackingStore>((set, get) => ({
  // Initial state
  isTracking: false,
  currentSession: null,
  currentMode: TransportMode.UNKNOWN,
  currentSpeed: 0,
  currentLocation: null,
  elapsedTime: 0,
  totalDistance: 0,
  routeCoordinates: [],

  // Start tracking
  startTracking: async () => {
    try {
      const sessionId = await trackingService.startTracking();
      const session = await storageService.getSession(sessionId);

      set({
        isTracking: true,
        currentSession: session,
        elapsedTime: 0,
        totalDistance: 0,
        routeCoordinates: [],
      });

      // Subscribe to location updates
      trackingService.addListener(update => {
        get().updateLocation(update);
      });
    } catch (error) {
      console.error('Error starting tracking:', error);
      throw error;
    }
  },

  // Stop tracking
  stopTracking: async () => {
    try {
      const sessionId = await trackingService.stopTracking();

      set({
        isTracking: false,
        currentSession: null,
        currentMode: TransportMode.UNKNOWN,
        currentSpeed: 0,
        elapsedTime: 0,
      });

      return sessionId;
    } catch (error) {
      console.error('Error stopping tracking:', error);
      throw error;
    }
  },

  // Update location from GPS
  updateLocation: (update: LocationUpdate) => {
    const { routeCoordinates } = get();

    const newCoordinate = {
      latitude: update.latitude,
      longitude: update.longitude,
    };

    // Calculate distance from last point
    let additionalDistance = 0;
    if (routeCoordinates.length > 0) {
      const lastCoord = routeCoordinates[routeCoordinates.length - 1];
      const R = 6371e3; // Earth's radius in meters
      const φ1 = (lastCoord.latitude * Math.PI) / 180;
      const φ2 = (newCoordinate.latitude * Math.PI) / 180;
      const Δφ = ((newCoordinate.latitude - lastCoord.latitude) * Math.PI) / 180;
      const Δλ = ((newCoordinate.longitude - lastCoord.longitude) * Math.PI) / 180;

      const a =
        Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
        Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

      additionalDistance = R * c;
    }

    set(state => ({
      currentMode: update.mode,
      currentSpeed: update.speed,
      currentLocation: newCoordinate,
      totalDistance: state.totalDistance + additionalDistance,
      routeCoordinates: [...routeCoordinates, newCoordinate],
    }));
  },

  // Increment elapsed time (called every second)
  incrementElapsedTime: () => {
    set(state => ({
      elapsedTime: state.elapsedTime + 1,
    }));
  },

  // Reset tracking state
  resetTracking: () => {
    set({
      isTracking: false,
      currentSession: null,
      currentMode: TransportMode.UNKNOWN,
      currentSpeed: 0,
      currentLocation: null,
      elapsedTime: 0,
      totalDistance: 0,
      routeCoordinates: [],
    });
  },

  // Load active session on app start
  loadActiveSession: async () => {
    try {
      const activeSession = await storageService.getActiveSession();
      if (activeSession) {
        // Resume tracking if there's an active session
        console.log('Found active session:', activeSession.id);
        // Note: In production, you might want to ask user if they want to resume
      }
    } catch (error) {
      console.error('Error loading active session:', error);
    }
  },
}));
