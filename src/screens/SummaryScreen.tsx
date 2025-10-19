import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  Share,
} from 'react-native';
import { SessionSummary, TransportMode } from '../types';
import storageService from '../services/storage';
import {
  formatDistance,
  formatDuration,
  formatSpeed,
  formatTimestamp,
} from '../utils/calculations';
import { getModeDisplayName, getModeIcon, getModeColor } from '../services/modeDetector';

interface SummaryScreenProps {
  route: any;
  navigation: any;
}

const SummaryScreen: React.FC<SummaryScreenProps> = ({ route, navigation }) => {
  const { sessionId } = route.params;
  const [session, setSession] = useState<SessionSummary | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadSession();
  }, [sessionId]);

  const loadSession = async () => {
    try {
      const data = await storageService.getSessionWithPoints(sessionId);
      setSession(data);
    } catch (error) {
      console.error('Error loading session:', error);
      Alert.alert('Error', 'Failed to load session data');
    } finally {
      setLoading(false);
    }
  };

  const handleExportJSON = async () => {
    try {
      const json = await storageService.exportSessionAsJSON(sessionId);
      await Share.share({
        message: json,
        title: `Transit Tracker Session ${sessionId}`,
      });
    } catch (error) {
      console.error('Error exporting JSON:', error);
      Alert.alert('Error', 'Failed to export session as JSON');
    }
  };

  const handleExportGPX = async () => {
    try {
      const gpx = await storageService.exportSessionAsGPX(sessionId);
      await Share.share({
        message: gpx,
        title: `Transit Tracker Session ${sessionId}`,
      });
    } catch (error) {
      console.error('Error exporting GPX:', error);
      Alert.alert('Error', 'Failed to export session as GPX');
    }
  };

  const handleClose = () => {
    navigation.navigate('Map');
  };

  if (loading) {
    return (
      <View style={styles.container}>
        <Text style={styles.loadingText}>Loading session...</Text>
      </View>
    );
  }

  if (!session) {
    return (
      <View style={styles.container}>
        <Text style={styles.errorText}>Session not found</Text>
        <TouchableOpacity style={styles.button} onPress={handleClose}>
          <Text style={styles.buttonText}>Back to Map</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const getModeTime = (mode: TransportMode): number => {
    switch (mode) {
      case TransportMode.WALKING:
        return session.walkingTime;
      case TransportMode.DRIVING:
        return session.drivingTime;
      case TransportMode.TRAIN:
        return session.trainTime;
      default:
        return 0;
    }
  };

  const modes = [
    TransportMode.WALKING,
    TransportMode.DRIVING,
    TransportMode.TRAIN,
  ].filter(mode => getModeTime(mode) > 0);

  return (
    <ScrollView style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.title}>Trip Summary</Text>

        {/* Main stats */}
        <View style={styles.statsCard}>
          <View style={styles.statRow}>
            <Text style={styles.statLabel}>Total Distance</Text>
            <Text style={styles.statValue}>
              {formatDistance(session.totalDistance)}
            </Text>
          </View>

          <View style={styles.statRow}>
            <Text style={styles.statLabel}>Total Duration</Text>
            <Text style={styles.statValue}>
              {formatDuration(session.totalDuration)}
            </Text>
          </View>

          <View style={styles.statRow}>
            <Text style={styles.statLabel}>Average Speed</Text>
            <Text style={styles.statValue}>
              {formatSpeed(session.averageSpeed)}
            </Text>
          </View>

          <View style={styles.statRow}>
            <Text style={styles.statLabel}>Started</Text>
            <Text style={styles.statValue}>
              {formatTimestamp(session.startTime)}
            </Text>
          </View>

          {session.endTime && (
            <View style={styles.statRow}>
              <Text style={styles.statLabel}>Ended</Text>
              <Text style={styles.statValue}>
                {formatTimestamp(session.endTime)}
              </Text>
            </View>
          )}
        </View>

        {/* Mode breakdown */}
        <Text style={styles.sectionTitle}>Transportation Modes</Text>
        <View style={styles.modesCard}>
          {modes.map(mode => (
            <View
              key={mode}
              style={[
                styles.modeRow,
                { borderLeftColor: getModeColor(mode) },
              ]}
            >
              <Text style={styles.modeIcon}>{getModeIcon(mode)}</Text>
              <View style={styles.modeInfo}>
                <Text style={styles.modeName}>{getModeDisplayName(mode)}</Text>
                <Text style={styles.modeTime}>
                  {formatDuration(getModeTime(mode))}
                </Text>
              </View>
            </View>
          ))}

          {modes.length === 0 && (
            <Text style={styles.noDataText}>No mode data available</Text>
          )}
        </View>

        {/* GPS points info */}
        <Text style={styles.sectionTitle}>Route Details</Text>
        <View style={styles.infoCard}>
          <Text style={styles.infoText}>
            📍 {session.points.length} GPS points recorded
          </Text>
        </View>

        {/* Export buttons */}
        <Text style={styles.sectionTitle}>Export</Text>
        <View style={styles.exportButtons}>
          <TouchableOpacity
            style={styles.exportButton}
            onPress={handleExportJSON}
          >
            <Text style={styles.exportButtonText}>Export as JSON</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.exportButton}
            onPress={handleExportGPX}
          >
            <Text style={styles.exportButtonText}>Export as GPX</Text>
          </TouchableOpacity>
        </View>

        {/* Close button */}
        <TouchableOpacity style={styles.closeButton} onPress={handleClose}>
          <Text style={styles.closeButtonText}>Back to Map</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f3f4f6',
  },
  content: {
    padding: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1f2937',
    marginBottom: 20,
  },
  statsCard: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 3,
  },
  statRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
  },
  statLabel: {
    fontSize: 16,
    color: '#6b7280',
  },
  statValue: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1f2937',
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1f2937',
    marginTop: 10,
    marginBottom: 12,
  },
  modesCard: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 3,
  },
  modeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingLeft: 12,
    borderLeftWidth: 4,
    marginBottom: 8,
  },
  modeIcon: {
    fontSize: 32,
    marginRight: 12,
  },
  modeInfo: {
    flex: 1,
  },
  modeName: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1f2937',
  },
  modeTime: {
    fontSize: 14,
    color: '#6b7280',
    marginTop: 2,
  },
  infoCard: {
    backgroundColor: 'white',
    borderRadius: 12,
    padding: 16,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 3,
  },
  infoText: {
    fontSize: 16,
    color: '#4b5563',
  },
  exportButtons: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 20,
  },
  exportButton: {
    flex: 1,
    backgroundColor: '#3b82f6',
    borderRadius: 8,
    paddingVertical: 12,
    alignItems: 'center',
  },
  exportButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
  },
  closeButton: {
    backgroundColor: '#10b981',
    borderRadius: 8,
    paddingVertical: 16,
    alignItems: 'center',
    marginBottom: 40,
  },
  closeButtonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
  },
  loadingText: {
    fontSize: 18,
    color: '#6b7280',
    textAlign: 'center',
    marginTop: 40,
  },
  errorText: {
    fontSize: 18,
    color: '#ef4444',
    textAlign: 'center',
    marginTop: 40,
  },
  noDataText: {
    fontSize: 16,
    color: '#9ca3af',
    textAlign: 'center',
    paddingVertical: 20,
  },
  button: {
    backgroundColor: '#3b82f6',
    borderRadius: 8,
    paddingVertical: 12,
    paddingHorizontal: 24,
    alignSelf: 'center',
    marginTop: 20,
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },
});

export default SummaryScreen;
