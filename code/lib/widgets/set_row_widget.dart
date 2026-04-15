import 'package:flutter/material.dart';
import '../models/training_record.dart';
import '../theme/app_theme.dart';

/// Display mode for a set row.
enum SetRowMode { plan, training, review }

/// Individual set row inside an [ExerciseCard].
///
/// Shows set number, load, reps, RPE/effort, and optional note.
/// In training mode, plan values appear faded behind editable actuals.
class SetRowWidget extends StatelessWidget {
  const SetRowWidget({
    super.key,
    required this.set,
    required this.setIndex,
    this.mode = SetRowMode.plan,
    this.displayColumns = const ['load', 'rep', 'rpe'],
    this.onTap,
  });

  final TrainingSet set;
  final int setIndex;
  final SetRowMode mode;
  final List<String> displayColumns;
  final VoidCallback? onTap;

  // ── helpers ──

  Color get _stateColor => AppTheme.stateColor(set.state);

  IconData get _stateIcon {
    switch (set.state) {
      case 'completed':
        return Icons.check_circle;
      case 'skipped':
        return Icons.remove_circle_outline;
      case 'pending':
        return Icons.radio_button_unchecked;
      default:
        return Icons.circle_outlined;
    }
  }

  String _fieldText(SetValues? sv, String field) {
    if (sv == null) return '-';
    switch (field) {
      case 'load':
        return _rangeText(sv.loadValue, sv.loadUnit ?? 'kg');
      case 'rep':
        return _rangeText(sv.rep, '次');
      case 'duration':
        return _rangeText(sv.duration, sv.durationUnit ?? 's');
      case 'distance':
        return _rangeText(sv.distance, sv.distanceUnit ?? 'm');
      default:
        return '-';
    }
  }

  String _rpeText(EffortMetrics? e) {
    if (e == null || e.rpe == null || e.rpe!.isEmpty) return '-';
    final v = e.rpe!.first;
    return v != null ? v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1) : '-';
  }

  String _rangeText(List<double?>? vals, String unit) {
    if (vals == null || vals.isEmpty) return '-';
    final filtered = vals.whereType<double>().toList();
    if (filtered.isEmpty) return '-';
    if (filtered.length == 1) {
      return '${_numStr(filtered.first)} $unit';
    }
    return '${_numStr(filtered.first)}-${_numStr(filtered.last)} $unit';
  }

  String _numStr(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final isTraining = mode == SetRowMode.training;
    final isReview = mode == SetRowMode.review;

    // Pick source values based on mode
    final SetValues? planValues = set.workingPlan ?? set.baselinePlan;
    final SetValues? actualValues = set.actual;
    final SetValues? display =
        (isReview || isTraining) && actualValues != null
            ? actualValues
            : planValues;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            // State indicator
            if (isTraining || isReview) ...[
              Icon(_stateIcon, size: 18, color: _stateColor),
              const SizedBox(width: 8),
            ],

            // Set number
            SizedBox(
              width: 28,
              child: Text(
                'S${setIndex + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),

            // Dynamic columns
            ...displayColumns.map((col) {
              if (col == 'rpe') {
                return _buildCell(
                  context,
                  label: 'RPE',
                  value: _rpeText(
                    (isReview || isTraining) && set.effortMetrics != null
                        ? set.effortMetrics
                        : null,
                  ),
                  planValue: isTraining && planValues != null ? '-' : null,
                );
              }
              return _buildCell(
                context,
                label: _colLabel(col),
                value: _fieldText(display, col),
                planValue:
                    isTraining && actualValues != null && planValues != null
                        ? _fieldText(planValues, col)
                        : null,
              );
            }),

            // Note indicator
            if (set.actual?.note != null && set.actual!.note!.isNotEmpty ||
                planValues?.note != null && planValues!.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.sticky_note_2_outlined,
                  size: 14,
                  color: AppTheme.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(
    BuildContext context, {
    required String label,
    required String value,
    String? planValue,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (planValue != null)
            Text(
              planValue,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textTertiary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  value == '-' ? AppTheme.textTertiary : AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _colLabel(String col) {
    switch (col) {
      case 'load':
        return '负荷';
      case 'rep':
        return '次数';
      case 'rpe':
        return 'RPE';
      case 'duration':
        return '时长';
      case 'distance':
        return '距离';
      default:
        return col;
    }
  }
}
