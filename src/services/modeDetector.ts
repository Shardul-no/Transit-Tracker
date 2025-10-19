import { TransportMode } from '../types';

/**
 * Speed thresholds for mode detection (in m/s)
 */
const SPEED_THRESHOLDS = {
  WALKING_MAX: 3, // ~10.8 km/h
  DRIVING_MAX: 22, // ~79.2 km/h
};

/**
 * Detect transportation mode based on speed
 * @param speed Speed in meters per second
 * @returns Detected transportation mode
 */
export const detectMode = (speed: number): TransportMode => {
  if (speed < 0) {
    return TransportMode.UNKNOWN;
  }

  if (speed < SPEED_THRESHOLDS.WALKING_MAX) {
    return TransportMode.WALKING;
  }

  if (speed < SPEED_THRESHOLDS.DRIVING_MAX) {
    return TransportMode.DRIVING;
  }

  return TransportMode.TRAIN;
};

/**
 * Get display name for transport mode
 */
export const getModeDisplayName = (mode: TransportMode): string => {
  switch (mode) {
    case TransportMode.WALKING:
      return 'Walking';
    case TransportMode.DRIVING:
      return 'Driving';
    case TransportMode.TRAIN:
      return 'Train';
    default:
      return 'Unknown';
  }
};

/**
 * Get color for transport mode (for UI display)
 */
export const getModeColor = (mode: TransportMode): string => {
  switch (mode) {
    case TransportMode.WALKING:
      return '#10b981'; // green
    case TransportMode.DRIVING:
      return '#3b82f6'; // blue
    case TransportMode.TRAIN:
      return '#8b5cf6'; // purple
    default:
      return '#6b7280'; // gray
  }
};

/**
 * Get emoji icon for transport mode
 */
export const getModeIcon = (mode: TransportMode): string => {
  switch (mode) {
    case TransportMode.WALKING:
      return '🚶';
    case TransportMode.DRIVING:
      return '🚗';
    case TransportMode.TRAIN:
      return '🚆';
    default:
      return '❓';
  }
};
