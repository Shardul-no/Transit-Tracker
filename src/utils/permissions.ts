import { Platform, Alert, Linking } from 'react-native';
import {
  check,
  request,
  PERMISSIONS,
  RESULTS,
  Permission,
} from 'react-native-permissions';

export type PermissionStatus = 'granted' | 'denied' | 'blocked' | 'unavailable';

/**
 * Get the appropriate location permission for the platform
 */
const getLocationPermission = (): Permission => {
  if (Platform.OS === 'ios') {
    return PERMISSIONS.IOS.LOCATION_WHEN_IN_USE;
  }
  return PERMISSIONS.ANDROID.ACCESS_FINE_LOCATION;
};

/**
 * Get the background location permission for the platform
 */
const getBackgroundLocationPermission = (): Permission | null => {
  if (Platform.OS === 'ios') {
    return PERMISSIONS.IOS.LOCATION_ALWAYS;
  }
  if (Platform.OS === 'android' && Platform.Version >= 29) {
    return PERMISSIONS.ANDROID.ACCESS_BACKGROUND_LOCATION;
  }
  return null;
};

/**
 * Check if location permission is granted
 */
export const checkLocationPermission = async (): Promise<PermissionStatus> => {
  const permission = getLocationPermission();
  const result = await check(permission);

  switch (result) {
    case RESULTS.GRANTED:
      return 'granted';
    case RESULTS.DENIED:
      return 'denied';
    case RESULTS.BLOCKED:
      return 'blocked';
    default:
      return 'unavailable';
  }
};

/**
 * Request location permission
 */
export const requestLocationPermission = async (): Promise<PermissionStatus> => {
  const permission = getLocationPermission();
  const result = await request(permission);

  switch (result) {
    case RESULTS.GRANTED:
      return 'granted';
    case RESULTS.DENIED:
      return 'denied';
    case RESULTS.BLOCKED:
      return 'blocked';
    default:
      return 'unavailable';
  }
};

/**
 * Request background location permission (if needed)
 */
export const requestBackgroundLocationPermission = async (): Promise<PermissionStatus> => {
  const permission = getBackgroundLocationPermission();

  if (!permission) {
    // Background permission not needed on this platform/version
    return 'granted';
  }

  const result = await request(permission);

  switch (result) {
    case RESULTS.GRANTED:
      return 'granted';
    case RESULTS.DENIED:
      return 'denied';
    case RESULTS.BLOCKED:
      return 'blocked';
    default:
      return 'unavailable';
  }
};

/**
 * Request all necessary location permissions
 */
export const requestAllLocationPermissions = async (): Promise<boolean> => {
  // First request foreground permission
  const foregroundStatus = await requestLocationPermission();

  if (foregroundStatus !== 'granted') {
    Alert.alert(
      'Location Permission Required',
      'Transit Tracker needs location access to track your trips. Please grant location permission.',
      [{ text: 'OK' }],
    );
    return false;
  }

  // Then request background permission
  const backgroundPermission = getBackgroundLocationPermission();
  if (backgroundPermission) {
    const backgroundStatus = await requestBackgroundLocationPermission();

    if (backgroundStatus !== 'granted') {
      Alert.alert(
        'Background Location',
        'For best results, please allow location access "Always" to track trips even when the app is in the background.',
        [
          { text: 'Not Now', style: 'cancel' },
          {
            text: 'Settings',
            onPress: () => Linking.openSettings(),
          },
        ],
      );
      // Still return true as foreground permission is granted
    }
  }

  return true;
};

/**
 * Show alert to open app settings
 */
export const showSettingsAlert = (message: string): void => {
  Alert.alert(
    'Permission Required',
    message,
    [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Open Settings',
        onPress: () => Linking.openSettings(),
      },
    ],
  );
};

/**
 * Check if we have all necessary permissions
 */
export const hasAllPermissions = async (): Promise<boolean> => {
  const foregroundStatus = await checkLocationPermission();
  return foregroundStatus === 'granted';
};
