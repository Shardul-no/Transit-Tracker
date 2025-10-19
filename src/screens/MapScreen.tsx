import React, { useEffect, useRef, useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Alert,
  Platform,
} from 'react-native';
import MapView, { Polyline, PROVIDER_DEFAULT } from 'react-native-maps';
import { check, request, PERMISSIONS, RESULTS } from 'react-native-permissions';
import { useTrackingStore } from '../store/trackingStore';
import { getModeDisplayName, getModeIcon } from '../services/modeDetector';
import { formatDuration, formatDistance, formatSpeed } from '../utils/calculations';
import trackingService from '../services/trackingService';

interface MapScreenProps {
  navigation: any;
}

const MapScreen: React.FC<MapScreenProps> = ({ navigation }) => {
  const mapRef = useRef<MapView>(null);
  const [hasLocationPermission, setHasLocationPermission] = useState(false);

  const {
    isTracking,
    currentMode,
    currentSpeed,
    currentLocation,
    elapsedTime,
    totalDistance,
    routeCoordinates,
    startTracking,
    stopTracking,
    incrementElapsedTime,
  } = useTrackingStore();

  // Timer for elapsed time
  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isTracking) {
      interval = setInterval(() => {
        incrementElapsedTime();
      }, 1000);
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isTracking, incrementElapsedTime]);

  // Check and request location permissions
  useEffect(() => {
    checkLocationPermission();
  }, []);

  // Center map on current location
  useEffect(() => {
    if (currentLocation && mapRef.current) {
      mapRef.current.animateToRegion({
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
        latitudeDelta: 0.01,
        longitudeDelta: 0.01,
      });
    }
  }, [currentLocation]);

  const checkLocationPermission = async () => {
    const permission =
      Platform.OS === 'ios'
        ? PERMISSIONS.IOS.LOCATION_WHEN_IN_USE
        : PERMISSIONS.ANDROID.ACCESS_FINE_LOCATION;

    const result = await check(permission);

    if (result === RESULTS.GRANTED) {
      setHasLocationPermission(true);
      // Get initial location
      try {
        const location = await trackingService.getCurrentLocation();
        if (location && mapRef.current) {
          mapRef.current.animateToRegion({
            latitude: location.latitude,
            longitude: location.longitude,
            latitudeDelta: 0.01,
            longitudeDelta: 0.01,
          });
        }
      } catch (error) {
        console.error('Error getting initial location:', error);
      }
    } else {
      requestLocationPermission();
    }
  };

  const requestLocationPermission = async () => {
    const permission =
      Platform.OS === 'ios'
        ? PERMISSIONS.IOS.LOCATION_WHEN_IN_USE
        : PERMISSIONS.ANDROID.ACCESS_FINE_LOCATION;

    const result = await request(permission);

    if (result === RESULTS.GRANTED) {
      setHasLocationPermission(true);
    } else {
      Alert.alert(
        'Location Permission Required',
        'This app needs location access to track your movement. Please enable location permissions in settings.',
        [{ text: 'OK' }],
      );
    }
  };

  const handleStartStop = async () => {
    if (!hasLocationPermission) {
      Alert.alert(
        'Permission Required',
        'Please grant location permission to start tracking.',
      );
      return;
    }

    try {
      if (isTracking) {
        // Stop tracking
        const sessionId = await stopTracking();
        if (sessionId) {
          // Navigate to summary screen
          navigation.navigate('Summary', { sessionId });
        }
      } else {
        // Start tracking
        await startTracking();
      }
    } catch (error) {
      console.error('Error toggling tracking:', error);
      Alert.alert('Error', 'Failed to toggle tracking. Please try again.');
    }
  };

  const handleHistoryPress = () => {
    navigation.navigate('History');
  };

  return (
    <View style={styles.container}>
      <MapView
        ref={mapRef}
        provider={PROVIDER_DEFAULT}
        style={styles.map}
        showsUserLocation
        showsMyLocationButton
        followsUserLocation={isTracking}
        customMapStyle={[]}
        // OpenStreetMap tiles configuration
        // Note: For production, consider using a tile server with proper attribution
      >
        {routeCoordinates.length > 1 && (
          <Polyline
            coordinates={routeCoordinates}
            strokeColor="#3b82f6"
            strokeWidth={4}
          />
        )}
      </MapView>

      {/* Top info bar */}
      {isTracking && (
        <View style={styles.topBar}>
          <View style={styles.infoContainer}>
            <Text style={styles.modeText}>
              {getModeIcon(currentMode)} {getModeDisplayName(currentMode)}
            </Text>
            <Text style={styles.statsText}>
              {formatDuration(elapsedTime)} • {formatDistance(totalDistance)}
            </Text>
            <Text style={styles.speedText}>{formatSpeed(currentSpeed)}</Text>
          </View>
        </View>
      )}

      {/* History button */}
      <TouchableOpacity
        style={styles.historyButton}
        onPress={handleHistoryPress}
      >
        <Text style={styles.historyButtonText}>📋 History</Text>
      </TouchableOpacity>

      {/* Start/Stop button */}
      <TouchableOpacity
        style={[
          styles.trackingButton,
          isTracking ? styles.stopButton : styles.startButton,
        ]}
        onPress={handleStartStop}
      >
        <Text style={styles.buttonText}>
          {isTracking ? '⏹ Stop' : '▶ Start'}
        </Text>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  map: {
    flex: 1,
  },
  topBar: {
    position: 'absolute',
    top: 50,
    left: 20,
    right: 20,
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  infoContainer: {
    gap: 8,
  },
  modeText: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1f2937',
  },
  statsText: {
    fontSize: 16,
    color: '#4b5563',
  },
  speedText: {
    fontSize: 14,
    color: '#6b7280',
  },
  historyButton: {
    position: 'absolute',
    top: 50,
    right: 20,
    backgroundColor: 'white',
    borderRadius: 12,
    paddingVertical: 12,
    paddingHorizontal: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
  },
  historyButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1f2937',
  },
  trackingButton: {
    position: 'absolute',
    bottom: 40,
    left: '50%',
    marginLeft: -80,
    width: 160,
    height: 160,
    borderRadius: 80,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 4.65,
    elevation: 8,
  },
  startButton: {
    backgroundColor: '#10b981',
  },
  stopButton: {
    backgroundColor: '#ef4444',
  },
  buttonText: {
    fontSize: 24,
    fontWeight: 'bold',
    color: 'white',
  },
});

export default MapScreen;
