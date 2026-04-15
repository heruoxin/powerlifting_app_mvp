import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

/// A persistent dark bar shown at the top of the app when a training
/// session is in progress. Displays current exercise + elapsed time
/// and navigates back to the training workbench on tap.
class TrainingStatusBar extends StatefulWidget {
  const TrainingStatusBar({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<TrainingStatusBar> createState() => _TrainingStatusBarState();
}

class _TrainingStatusBarState extends State<TrainingStatusBar> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final appState = context.read<AppState>();
      final startedAt = appState.activeTraining?.startedAt;
      if (startedAt != null) {
        final start = DateTime.tryParse(startedAt);
        if (start != null) {
          setState(() => _elapsed = DateTime.now().difference(start));
        }
      }
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final training = appState.activeTraining;
    if (training == null) return const SizedBox.shrink();

    // Find current exercise label
    final currentExercise = training.exerciseBlocks.isNotEmpty
        ? training.exerciseBlocks.last.name
        : '训练中';

    final planLabel = training.dayLabel ?? training.daySlotLabel;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: AppTheme.trainingBarDark,
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              // Pulsing dot
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.dangerRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),

              // Exercise name + plan label
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentExercise,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (planLabel.isNotEmpty)
                      Text(
                        planLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Elapsed time
              Text(
                _formatDuration(_elapsed),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
