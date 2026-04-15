import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_record.dart';
import '../providers/app_state.dart';

/// A persistent high-contrast status bar shown at the top of the app when a
/// training session is in progress.
///
/// Two-line layout:
///   Line 1 (16 px, bold): current segment name  ·  segment timer
///   Line 2 (12 px, muted): plan context          ·  总计 HH:MM:SS
class TrainingStatusBar extends StatefulWidget {
  const TrainingStatusBar({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<TrainingStatusBar> createState() => _TrainingStatusBarState();
}

class _TrainingStatusBarState extends State<TrainingStatusBar>
    with SingleTickerProviderStateMixin {
  static const _barColor = Color(0xFF1B3A2D);
  static const _accentGreen = Color(0xFF4CAF50);

  Timer? _timer;
  Duration _totalElapsed = Duration.zero;
  Duration _segmentElapsed = Duration.zero;
  String _segmentLabel = '准备开始';

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final training = context.read<AppState>().activeTraining;
      if (training == null) return;

      final now = DateTime.now();

      // Total elapsed
      final start = DateTime.tryParse(training.startedAt ?? '');
      if (start != null) {
        _totalElapsed = now.difference(start);
      }

      // Segment detection
      _updateSegment(training, now);

      setState(() {});
    });
  }

  void _updateSegment(TrainingRecord training, DateTime now) {
    String? inProgressExercise;
    DateTime? inProgressStart;
    String? latestFinishedAt;

    for (final block in training.exerciseBlocks) {
      for (final s in block.sets) {
        // A set that has been started but not yet finished
        if (s.startedAt != null &&
            s.finishedAt == null &&
            s.state != 'completed' &&
            s.state != 'skipped') {
          final setStart = DateTime.tryParse(s.startedAt!);
          if (setStart != null) {
            inProgressExercise = block.name;
            inProgressStart = setStart;
          }
        }

        // Track the latest finishedAt across all completed sets
        if (s.state == 'completed' && s.finishedAt != null) {
          if (latestFinishedAt == null ||
              s.finishedAt!.compareTo(latestFinishedAt) > 0) {
            latestFinishedAt = s.finishedAt;
          }
        }
      }
    }

    if (inProgressExercise != null && inProgressStart != null) {
      // Currently performing a set
      _segmentLabel = inProgressExercise;
      _segmentElapsed = now.difference(inProgressStart);
    } else if (latestFinishedAt != null) {
      // Resting between sets
      final lastFinish = DateTime.tryParse(latestFinishedAt);
      if (lastFinish != null) {
        _segmentLabel = '组间休息';
        _segmentElapsed = now.difference(lastFinish);
      }
    } else {
      // No sets started or completed yet
      _segmentLabel = '准备开始';
      _segmentElapsed = Duration.zero;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatHMS(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Build a plan context string like "W3 D2 Hypertrophy".
  String _buildPlanContext(TrainingRecord t) {
    final parts = <String>[];
    parts.add('W${t.weekIndex + 1}');
    parts.add(t.daySlotLabel);
    if (t.dayLabel != null && t.dayLabel!.isNotEmpty) {
      parts.add(t.dayLabel!);
    }
    return parts.join(' ');
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final training = appState.activeTraining;
    if (training == null) return const SizedBox.shrink();

    final planContext = _buildPlanContext(training);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: _barColor),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Pulsing green accent dot
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _accentGreen
                          .withValues(alpha: _pulseAnimation.value),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _accentGreen
                              .withValues(alpha: _pulseAnimation.value * 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Two-line info
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Line 1: segment label + segment timer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _segmentLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatHMS(_segmentElapsed),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Line 2: plan context + total timer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              planContext,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '总计 ${_formatHMS(_totalElapsed)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
