import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/trip_models.dart';
import '../state/tracker_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'history_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
  });

  final TrackerController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  TrackerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_handleControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.refreshCurrentLocation();
    });
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerUpdate);
    super.dispose();
  }

  void _handleControllerUpdate() {
    _centerMapOnCurrentLocation();
  }

  void _handleMapReady() {
    if (!mounted) return;
    setState(() => _mapReady = true);
    _centerMapOnCurrentLocation();
  }

  void _centerMapOnCurrentLocation() {
    final snapshot = controller.snapshot;
    if (!_mapReady || snapshot.latitude == null || snapshot.longitude == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      _mapController.move(
        LatLng(snapshot.latitude!, snapshot.longitude!),
        math.max(15.0, snapshot.route.length > 8 ? 16.0 : 15.0),
      );
    });
  }

  Future<void> _startOrStop() async {
    final snapshot = controller.snapshot;
    if (snapshot.isTracking) {
      final sessionId = await controller.stopTracking();
      if (!mounted || sessionId == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SummaryScreen(
            controller: controller,
            sessionId: sessionId,
          ),
        ),
      );
      setState(() {});
      return;
    }

    try {
      await controller.startTracking();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final snapshot = controller.snapshot;
        final routePoints = snapshot.route;
        final currentMode = snapshot.currentMode;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF08111F),
                  Color(0xFF0C1C2C),
                  Color(0xFF112843),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: -60,
                    right: -40,
                    child: _GlowBlob(
                      color: AppTheme.accent.withValues(alpha: 0.22),
                      size: 180,
                    ),
                  ),
                  Positioned(
                    top: 90,
                    left: -70,
                    child: _GlowBlob(
                      color: AppTheme.accentBlue.withValues(alpha: 0.16),
                      size: 160,
                    ),
                  ),
                  Positioned.fill(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(
                            isTracking: snapshot.isTracking,
                            currentMode: currentMode,
                            statusMessage: snapshot.statusMessage,
                          ),
                          const SizedBox(height: 18),
                          _HeroPanel(
                            snapshot: snapshot,
                            routePoints: routePoints,
                            mapController: _mapController,
                            mapReady: _mapReady,
                            onMapReady: _handleMapReady,
                            onTapHistory: _openHistory,
                          ),
                          const SizedBox(height: 18),
                          _StatsRow(snapshot: snapshot),
                          const SizedBox(height: 18),
                          _CalloutCard(
                            title: snapshot.isTracking
                                ? 'Trip in motion'
                                : 'Ready to record',
                            description: snapshot.isTracking
                                ? 'Keep the app alive and the foreground service will keep your GPS trace going on Android.'
                                : 'Tap Start when you leave and the app will begin logging speed, route, and mode automatically.',
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  label: snapshot.isTracking
                                      ? 'Stop trip'
                                      : 'Start trip',
                                  icon: snapshot.isTracking
                                      ? Icons.stop_circle_outlined
                                      : Icons.play_circle_fill,
                                  accent: snapshot.isTracking
                                      ? AppTheme.accentGold
                                      : AppTheme.accent,
                                  onTap: _startOrStop,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _MiniActionButton(
                                label: 'History',
                                icon: Icons.history,
                                onTap: _openHistory,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (snapshot.statusMessage != null)
                            _StatusBanner(message: snapshot.statusMessage!),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isTracking,
    required this.currentMode,
    required this.statusMessage,
  });

  final bool isTracking;
  final TransportMode currentMode;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transit Pulse',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'A bold, offline-first trip logger for Android.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        _Pill(
          icon: isTracking ? Icons.fiber_manual_record : Icons.bolt,
          label: isTracking ? currentMode.label : 'Idle',
          color: isTracking ? currentMode.color : AppTheme.accentBlue,
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.snapshot,
    required this.routePoints,
    required this.mapController,
    required this.mapReady,
    required this.onMapReady,
    required this.onTapHistory,
  });

  final TripSnapshot snapshot;
  final List<LatLng> routePoints;
  final MapController mapController;
  final bool mapReady;
  final VoidCallback onMapReady;
  final VoidCallback onTapHistory;

  @override
  Widget build(BuildContext context) {
    final center = snapshot.latitude != null && snapshot.longitude != null
        ? LatLng(snapshot.latitude!, snapshot.longitude!)
        : _defaultMapCenter;
    final route = routePoints;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 320,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: route.isNotEmpty ? 16 : 13,
                      onMapReady: onMapReady,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.transittracker.transit_tracker',
                      ),
                      if (route.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: route,
                              strokeWidth: 6,
                              color: AppTheme.accent,
                              borderColor: const Color(0xFF0A0F18),
                              borderStrokeWidth: 4,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (snapshot.latitude != null && snapshot.longitude != null)
                            Marker(
                              width: 48,
                              height: 48,
                              point: center,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.accent.withValues(alpha: 0.18),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.accent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.accent.withValues(alpha: 0.7),
                                          blurRadius: 18,
                                          spreadRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _GlassChip(
                          icon: Icons.map_outlined,
                          text: mapReady ? 'Live map' : 'Preparing map',
                        ),
                        const Spacer(),
                        _GlassChip(
                          icon: Icons.auto_graph,
                          text: route.length > 1
                              ? '${route.length} fixes'
                              : 'No route yet',
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Expanded(
                          child: _MetricGlass(
                            label: 'Distance',
                            value: formatDistanceMeters(snapshot.totalDistanceMeters),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricGlass(
                            label: 'Elapsed',
                            value: formatDuration(snapshot.elapsed),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _StateTile(
                      label: 'Mode',
                      value: snapshot.currentMode.label,
                      accent: snapshot.currentMode.color,
                      icon: snapshot.currentMode.icon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StateTile(
                      label: 'Speed',
                      value: formatSpeedMps(snapshot.currentSpeedMps),
                      accent: AppTheme.accentBlue,
                      icon: Icons.speed,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: _LocationFooter(
                latitude: snapshot.latitude,
                longitude: snapshot.longitude,
                currentFixTime: snapshot.currentFixTime,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const LatLng _defaultMapCenter = LatLng(12.9716, 77.5946);

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.snapshot});

  final TripSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompactStatCard(
            label: 'Distance',
            value: formatDistanceMeters(snapshot.totalDistanceMeters),
            icon: Icons.route,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CompactStatCard(
            label: 'Elapsed',
            value: formatDuration(snapshot.elapsed),
            icon: Icons.timer_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CompactStatCard(
            label: 'Speed',
            value: formatSpeedMps(snapshot.currentSpeedMps),
            icon: Icons.speed,
          ),
        ),
      ],
    );
  }
}

class _CalloutCard extends StatelessWidget {
  const _CalloutCard({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.95),
              accent.withValues(alpha: 0.70),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 28),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 72,
        width: 96,
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.textPrimary),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _MetricGlass extends StatelessWidget {
  const _MetricGlass({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _StateTile extends StatelessWidget {
  const _StateTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationFooter extends StatelessWidget {
  const _LocationFooter({
    required this.latitude,
    required this.longitude,
    required this.currentFixTime,
  });

  final double? latitude;
  final double? longitude;
  final DateTime? currentFixTime;

  @override
  Widget build(BuildContext context) {
    final lat = latitude?.toStringAsFixed(5) ?? '--';
    final lon = longitude?.toStringAsFixed(5) ?? '--';
    final fixTime = currentFixTime == null
        ? 'Waiting for GPS'
        : formatLongDateTime(currentFixTime!);

    return Text(
      'Fix: $lat, $lon  |  $fixTime',
      style: Theme.of(context).textTheme.bodySmall,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  const _CompactStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(height: 14),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 70,
            spreadRadius: 18,
          ),
        ],
      ),
    );
  }
}

