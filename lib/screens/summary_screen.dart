import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/trip_models.dart';
import '../state/tracker_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({
    super.key,
    required this.controller,
    required this.sessionId,
  });

  final TrackerController controller;
  final int sessionId;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late Future<TripSessionDetails?> _future;

  TrackerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _future = controller.loadSessionDetails(widget.sessionId);
  }

  Future<void> _shareJson() async {
    final json = await controller.exportSessionAsJson(widget.sessionId);
    await SharePlus.instance.share(
      ShareParams(
        text: json,
        subject: 'Transit Pulse session ${widget.sessionId}',
      ),
    );
  }

  Future<void> _shareGpx() async {
    final gpx = await controller.exportSessionAsGpx(widget.sessionId);
    await SharePlus.instance.share(
      ShareParams(
        text: gpx,
        subject: 'Transit Pulse GPX ${widget.sessionId}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: FutureBuilder<TripSessionDetails?>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final details = snapshot.data;
              if (details == null) {
                return _FailureState(
                  onBack: () => Navigator.of(context).pop(),
                );
              }

              final session = details.session;
              final points = details.points;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Trip Summary',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          const _SoftBadge(label: 'Saved locally'),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _SummaryHero(session: session),
                          const SizedBox(height: 16),
                          _SectionTitle(label: 'Overview'),
                          const SizedBox(height: 12),
                          _OverviewGrid(session: session),
                          const SizedBox(height: 18),
                          _SectionTitle(label: 'Mode split'),
                          const SizedBox(height: 12),
                          _ModeBreakdown(session: session),
                          const SizedBox(height: 18),
                          _SectionTitle(label: 'Route'),
                          const SizedBox(height: 12),
                          _RouteCard(points: points),
                          const SizedBox(height: 18),
                          _SectionTitle(label: 'Export'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ExportButton(
                                  label: 'Share JSON',
                                  icon: Icons.data_object,
                                  onTap: _shareJson,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ExportButton(
                                  label: 'Share GPX',
                                  icon: Icons.route,
                                  onTap: _shareGpx,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonalIcon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Back to map'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.session});

  final TripSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.18),
            AppTheme.accentBlue.withValues(alpha: 0.16),
            AppTheme.surface.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.analytics_outlined, color: AppTheme.accent, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDistanceMeters(session.totalDistanceMeters),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatDuration(session.totalDuration)} tracked  |  ${formatSpeedMps(session.averageSpeedMps)} average',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.session});

  final TripSession session;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DetailCard(
            label: 'Started',
            value: formatLongDateTime(session.startTime),
            icon: Icons.play_arrow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DetailCard(
            label: 'Ended',
            value: session.endTime == null
                ? 'In progress'
                : formatLongDateTime(session.endTime!),
            icon: Icons.stop,
          ),
        ),
      ],
    );
  }
}

class _ModeBreakdown extends StatelessWidget {
  const _ModeBreakdown({required this.session});

  final TripSession session;

  @override
  Widget build(BuildContext context) {
    final modes = <({TransportMode mode, Duration duration})>[
      (mode: TransportMode.walking, duration: session.walkingTime),
      (mode: TransportMode.driving, duration: session.drivingTime),
      (mode: TransportMode.train, duration: session.trainTime),
    ].where((item) => item.duration.inSeconds > 0).toList();

    if (modes.isEmpty) {
      return _DetailCard(
        label: 'Mode split',
        value: 'No mode segments recorded',
        icon: Icons.help_outline,
      );
    }

    return Column(
      children: [
        for (final item in modes) ...[
          _ModeRow(
            mode: item.mode,
            duration: item.duration,
            total: session.totalDuration,
          ),
          if (item != modes.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.mode,
    required this.duration,
    required this.total,
  });

  final TransportMode mode;
  final Duration duration;
  final Duration total;

  @override
  Widget build(BuildContext context) {
    final share = total.inSeconds > 0 ? duration.inSeconds / total.inSeconds : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mode.color.withValues(alpha: 0.16),
                ),
                child: Icon(mode.icon, color: mode.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mode.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                formatDuration(duration),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: share.clamp(0, 1),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(mode.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.points});

  final List<TripPoint> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, color: AppTheme.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${points.length} GPS fixes captured along the route.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accentBlue, size: 20),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.accentGold),
            const SizedBox(height: 16),
            Text(
              'Summary not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The trip may have been deleted or never finished properly.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onBack,
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

