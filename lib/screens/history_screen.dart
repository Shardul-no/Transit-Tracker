import 'package:flutter/material.dart';

import '../models/trip_models.dart';
import '../state/tracker_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'summary_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.controller,
  });

  final TrackerController controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<TripSession>> _historyFuture;

  TrackerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _historyFuture = controller.loadHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = controller.loadHistory();
    });
  }

  Future<void> _openSummary(TripSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SummaryScreen(
          controller: controller,
          sessionId: session.id!,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _deleteSession(TripSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete trip?'),
        content: const Text(
          'This removes the session and all of its GPS points from the device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || session.id == null) return;
    await controller.deleteSession(session.id!);
    await _refresh();
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'This removes every completed trip and all of their GPS points from the device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await controller.clearHistory();
    await _refresh();
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Trip History',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Clear history',
                      onPressed: _clearHistory,
                      icon: const Icon(Icons.delete_sweep_outlined),
                    ),
                    const _SoftBadge(label: 'Local only'),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<TripSession>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final sessions = snapshot.data ?? <TripSession>[];
                    if (sessions.isEmpty) {
                      return _EmptyHistory(
                        onStartNew: () => Navigator.of(context).pop(),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                        itemCount: sessions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return _HistoryCard(
                            session: session,
                            onTap: () => _openSummary(session),
                            onDelete: () => _deleteSession(session),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  final TripSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final modeRows = <Widget>[
      if (session.walkingTime.inSeconds > 0)
        _MiniChip(
          label: 'Walk ${formatDuration(session.walkingTime)}',
          accent: TransportMode.walking.color,
        ),
      if (session.drivingTime.inSeconds > 0)
        _MiniChip(
          label: 'Drive ${formatDuration(session.drivingTime)}',
          accent: TransportMode.driving.color,
        ),
      if (session.trainTime.inSeconds > 0)
        _MiniChip(
          label: 'Train ${formatDuration(session.trainTime)}',
          accent: TransportMode.train.color,
        ),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accent.withValues(alpha: 0.14),
                  ),
                  child: const Icon(Icons.route, color: AppTheme.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatShortDate(session.startTime),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatLongDateTime(session.startTime),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  formatDistanceMeters(session.totalDistanceMeters),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Delete trip',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InfoBlock(
                    label: 'Duration',
                    value: formatDuration(session.totalDuration),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoBlock(
                    label: 'Average speed',
                    value: formatSpeedMps(session.averageSpeedMps),
                  ),
                ),
              ],
            ),
            if (modeRows.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: modeRows,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
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

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent,
            ),
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onStartNew});

  final VoidCallback onStartNew;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.route_outlined,
                size: 42,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No trips yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a session and the history will fill in here automatically.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onStartNew,
              child: const Text('Back to map'),
            ),
          ],
        ),
      ),
    );
  }
}

