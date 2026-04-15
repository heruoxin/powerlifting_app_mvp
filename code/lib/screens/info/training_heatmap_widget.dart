import 'package:flutter/material.dart';

import '../../models/training_record.dart';
import '../../theme/app_theme.dart';

/// GitHub-style training heatmap showing daily volume for the last 12 weeks.
class TrainingHeatmapWidget extends StatelessWidget {
  const TrainingHeatmapWidget({super.key, required this.records});

  final List<TrainingRecord> records;

  static const int _weeks = 12;
  static const double _cellSize = 14;
  static const double _cellGap = 3;

  @override
  Widget build(BuildContext context) {
    final volumeMap = _buildVolumeMap();
    final today = DateTime.now();
    // Start from Sunday of (today - 11 weeks)
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    final gridStart = startOfWeek.subtract(Duration(days: (_weeks - 1) * 7));

    final maxVolume = volumeMap.values.fold<double>(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month labels
        _buildMonthLabels(gridStart),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekday labels
            _buildWeekdayLabels(),
            const SizedBox(width: 4),
            // Grid
            Expanded(child: _buildGrid(gridStart, volumeMap, maxVolume, today)),
          ],
        ),
        const SizedBox(height: 8),
        _buildLegend(),
      ],
    );
  }

  Widget _buildMonthLabels(DateTime gridStart) {
    final months = <_MonthLabel>[];
    DateTime cursor = gridStart;
    int? lastMonth;

    for (var w = 0; w < _weeks; w++) {
      final weekStart = cursor.add(Duration(days: w * 7));
      if (weekStart.month != lastMonth) {
        lastMonth = weekStart.month;
        months.add(_MonthLabel(week: w, month: lastMonth));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: SizedBox(
        height: 16,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: months.map((m) {
                final left =
                    m.week * (_cellSize + _cellGap);
                return Positioned(
                  left: left,
                  child: Text(
                    _monthName(m.month),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    const labels = ['', '一', '', '三', '', '五', ''];
    return Column(
      children: labels.map((l) {
        return SizedBox(
          height: _cellSize + _cellGap,
          width: 18,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              l,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.textTertiary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrid(
    DateTime gridStart,
    Map<String, double> volumeMap,
    double maxVolume,
    DateTime today,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_weeks, (w) {
          return Column(
            children: List.generate(7, (d) {
              final date = gridStart.add(Duration(days: w * 7 + d));
              if (date.isAfter(today)) {
                return SizedBox(
                  width: _cellSize + _cellGap,
                  height: _cellSize + _cellGap,
                );
              }
              final key = _dateKey(date);
              final volume = volumeMap[key] ?? 0;
              final color = _volumeColor(volume, maxVolume);

              return Padding(
                padding: const EdgeInsets.all(_cellGap / 2),
                child: Tooltip(
                  message: '$key: ${volume.toStringAsFixed(0)} kg',
                  child: Container(
                    width: _cellSize,
                    height: _cellSize,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          '少',
          style: TextStyle(fontSize: 10, color: AppTheme.textTertiary),
        ),
        const SizedBox(width: 4),
        for (final alpha in [0.0, 0.25, 0.5, 0.75, 1.0])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: alpha == 0.0
                    ? const Color(0xFFEBEDF0)
                    : AppTheme.secondaryGreen.withValues(alpha: 0.25 + alpha * 0.75),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        const SizedBox(width: 4),
        const Text(
          '多',
          style: TextStyle(fontSize: 10, color: AppTheme.textTertiary),
        ),
      ],
    );
  }

  Map<String, double> _buildVolumeMap() {
    final map = <String, double>{};
    for (final record in records) {
      if (record.state != 'completed') continue;
      final key = record.date.length >= 10
          ? record.date.substring(0, 10)
          : record.date;
      double vol = 0;
      for (final block in record.exerciseBlocks) {
        for (final set in block.sets) {
          if (set.state != 'completed' || set.actual == null) continue;
          final load = set.actual!.loadValue?.firstOrNull ?? 0;
          final reps = set.actual!.rep?.firstOrNull ?? 0;
          vol += load * reps;
        }
      }
      map[key] = (map[key] ?? 0) + vol;
    }
    return map;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Color _volumeColor(double volume, double maxVolume) {
    if (volume <= 0) return const Color(0xFFEBEDF0);
    if (maxVolume <= 0) return const Color(0xFFEBEDF0);
    final fraction = (volume / maxVolume).clamp(0.0, 1.0);
    return AppTheme.secondaryGreen.withValues(alpha: 0.25 + fraction * 0.75);
  }

  static String _monthName(int month) {
    const names = [
      '', '1月', '2月', '3月', '4月', '5月', '6月',
      '7月', '8月', '9月', '10月', '11月', '12月',
    ];
    return names[month];
  }
}

class _MonthLabel {
  final int week;
  final int month;
  const _MonthLabel({required this.week, required this.month});
}
