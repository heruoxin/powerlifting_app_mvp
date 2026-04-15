import 'package:flutter/material.dart';

import '../../models/plan_models.dart';
import '../../models/training_record.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class PlanDayCard extends StatelessWidget {
  const PlanDayCard({
    super.key,
    required this.day,
    required this.weekLabel,
    required this.records,
    this.filterCategory,
  });

  final PlanDay day;
  final String weekLabel;
  final List<TrainingRecord> records;
  final String? filterCategory;

  String get _dayStatus {
    final record = records.where(
      (r) => r.sourcePlanDayUid == day.uid,
    );
    if (record.any((r) => r.state == 'in_progress')) return 'in_progress';
    if (record.any((r) => r.state == 'completed')) return 'completed';
    return 'planned';
  }

  @override
  Widget build(BuildContext context) {
    final status = _dayStatus;
    final items = _filteredItems();

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(status),
          if (day.dayTitle != null) ...[
            const SizedBox(height: 6),
            Text(
              day.dayTitle!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...items.map((item) => _buildExerciseRow(item, status)),
        ],
      ),
    );
  }

  Widget _buildHeader(String status) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.textPrimary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$weekLabel${day.label}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _statusBadge(status),
        const Spacer(),
        if (day.exerciseItems.isNotEmpty)
          Text(
            '${day.exerciseItems.length} 项',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textTertiary,
            ),
          ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String text;
    IconData? icon;

    switch (status) {
      case 'completed':
        bg = const Color(0xFFF0F0F0);
        fg = AppTheme.textSecondary;
        text = '已完成';
        icon = Icons.check;
      case 'in_progress':
        bg = AppTheme.primaryGold.withValues(alpha: 0.15);
        fg = const Color(0xFFB8860B);
        text = '进行中';
        icon = Icons.play_arrow;
      default:
        bg = AppTheme.secondaryGreen.withValues(alpha: 0.10);
        fg = AppTheme.secondaryGreen;
        text = '计划';
        icon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.chipBorderRadius),
        border: status == 'planned'
            ? Border.all(
                color: AppTheme.secondaryGreen.withValues(alpha: 0.3),
                width: 0.5,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  List<PlanExerciseItem> _filteredItems() {
    if (filterCategory == null) return day.exerciseItems;
    return day.exerciseItems.where((item) {
      final cat = _categoryForKey(item.exerciseTypeKey);
      return cat == filterCategory;
    }).toList();
  }

  String _categoryForKey(String key) {
    const mainLifts = {'squat', 'bench_press', 'deadlift'};
    const variants = {
      'pause_squat', 'close_grip_bench', 'sumo_deadlift', 'front_squat'
    };
    if (mainLifts.contains(key)) return '主项';
    if (variants.contains(key)) return '主项变式';
    return '辅助项';
  }

  Widget _buildExerciseRow(PlanExerciseItem item, String dayStatus) {
    final name = item.displayNameOverride ?? item.exerciseTypeKey;
    final setsSummary = _buildSetsSummary(item);
    final catColor = AppTheme.categoryColor(
      _categoryForKey(item.exerciseTypeKey),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 16,
            margin: const EdgeInsets.only(top: 2, right: 8),
            decoration: BoxDecoration(
              color: catColor,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: dayStatus == 'completed'
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${item.sets.length}组',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                if (setsSummary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      setsSummary,
                      style: TextStyle(
                        fontSize: 11,
                        color: dayStatus == 'completed'
                            ? AppTheme.textTertiary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildSetsSummary(PlanExerciseItem item) {
    if (item.sets.isEmpty) return '';

    final firstSet = item.sets.first.target;
    final parts = <String>[];

    final load = _firstVal(firstSet.load.value);
    if (load != null) {
      final unit = firstSet.load.unit ?? 'kg';
      parts.add('${_formatNum(load)}$unit');
    }

    final rep = _firstVal(firstSet.rep.value);
    if (rep != null) parts.add('×${rep.toInt()}');

    final rpe = _firstVal(firstSet.rpe.value);
    if (rpe != null) parts.add('@RPE${_formatNum(rpe)}');

    final dur = _firstVal(firstSet.duration.value);
    if (dur != null) {
      final unit = firstSet.duration.unit ?? 's';
      parts.add('${dur.toInt()}$unit');
    }

    return parts.join(' ');
  }

  double? _firstVal(List<double?>? values) {
    if (values == null || values.isEmpty) return null;
    return values.first;
  }

  String _formatNum(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }
}
