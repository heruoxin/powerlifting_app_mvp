import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/training_record.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

/// Training completion summary screen shown after finishing a training session.
/// Displays actual results, plan diffs, and session stats.
class TrainingCompletionScreen extends StatefulWidget {
  const TrainingCompletionScreen({super.key, required this.record});

  final TrainingRecord record;

  @override
  State<TrainingCompletionScreen> createState() =>
      _TrainingCompletionScreenState();
}

class _TrainingCompletionScreenState extends State<TrainingCompletionScreen> {
  bool _showDiff = false;

  TrainingRecord get record => widget.record;

  @override
  Widget build(BuildContext context) {
    final duration = _computeDuration();
    final stats = _computeStats();

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text('训练总结'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showDiff = !_showDiff),
            icon: Icon(
              _showDiff ? Icons.compare_arrows : Icons.difference_outlined,
              size: 18,
            ),
            label: Text(_showDiff ? '实际' : '对比'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Header card
          _buildHeaderCard(duration, stats),
          const SizedBox(height: 16),

          // Exercise blocks
          ...record.exerciseBlocks.map((block) => _buildBlockCard(block)),

          // Session tag
          const SizedBox(height: 16),
          _buildStatusBanner(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Duration duration, _SessionStats stats) {
    final dateStr = _formatDate(record.startedAt ?? '');
    final isTerminated = record.endedReason == 'terminated';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.dayLabel ?? record.daySlotLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isTerminated
                      ? AppTheme.dangerRed.withValues(alpha: 0.1)
                      : AppTheme.secondaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isTerminated ? '已终止' : '已完成',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isTerminated
                        ? AppTheme.dangerRed
                        : AppTheme.secondaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _StatChip(
                label: '时长',
                value: _formatDuration(duration),
                icon: Icons.timer_outlined,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: '完成组',
                value: '${stats.completed}/${stats.total}',
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: '跳过',
                value: '${stats.skipped}',
                icon: Icons.skip_next_outlined,
              ),
            ],
          ),

          if (stats.avgRpe != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                  label: '平均RPE',
                  value: stats.avgRpe!.toStringAsFixed(1),
                  icon: Icons.speed,
                  color: _rpeColor(stats.avgRpe!),
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: '总负荷',
                  value: _formatVolume(stats.totalVolume),
                  icon: Icons.fitness_center,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlockCard(ExerciseBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.categoryColor(block.exerciseCategory),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    block.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Text(
                  _blockSummary(block),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Sets
            ...block.sets.asMap().entries.map((entry) {
              final idx = entry.key;
              final set = entry.value;
              return _buildSetSummary(block, set, idx);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSetSummary(ExerciseBlock block, TrainingSet set, int idx) {
    final isCompleted = set.state == 'completed';
    final isSkipped = set.state == 'skipped';

    final statusTag = _getStatusTag(set);
    final cols = block.displayColumns;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.04),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 28,
            child: Text(
              'S${idx + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSkipped
                    ? AppTheme.textTertiary.withValues(alpha: 0.5)
                    : AppTheme.textSecondary,
              ),
            ),
          ),

          // Values
          if (isCompleted && set.actual != null) ...[
            Expanded(
              child: _showDiff
                  ? _buildDiffRow(block, set)
                  : _buildActualRow(set.actual!, cols),
            ),
          ] else if (isSkipped) ...[
            const Expanded(
              child: Text(
                '已跳过',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Text(
                '未执行',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textTertiary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],

          // Status tag
          if (statusTag != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusTag.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusTag.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusTag.color,
                ),
              ),
            ),

          // RPE
          if (isCompleted &&
              set.effortMetrics?.rpe != null &&
              set.effortMetrics!.rpe!.isNotEmpty &&
              set.effortMetrics!.rpe!.first != null) ...[
            const SizedBox(width: 6),
            Text(
              '@${_formatNum(set.effortMetrics!.rpe!.first)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _rpeColor(set.effortMetrics!.rpe!.first!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActualRow(SetValues actual, List<String> cols) {
    return Row(
      children: cols.map((col) {
        return Expanded(
          child: Text(
            _fieldText(actual, col),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDiffRow(ExerciseBlock block, TrainingSet set) {
    final plan = set.workingPlan ?? set.baselinePlan;
    final actual = set.actual;
    final cols = block.displayColumns;

    if (plan == null || actual == null) {
      return _buildActualRow(actual ?? const SetValues(), cols);
    }

    return Row(
      children: cols.map((col) {
        final planText = _fieldText(plan, col);
        final actualText = _fieldText(actual, col);
        final isDifferent = planText != actualText;

        return Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                if (isDifferent) ...[
                  TextSpan(
                    text: planText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const TextSpan(text: ' '),
                ],
                TextSpan(
                  text: actualText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDifferent
                        ? AppTheme.primaryGold
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusBanner() {
    final isTerminated = record.endedReason == 'terminated';

    if (!isTerminated) return const SizedBox.shrink();

    return GlassCard(
      color: AppTheme.dangerRed.withValues(alpha: 0.05),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 20,
              color: AppTheme.dangerRed.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '此训练因超时被自动终止，部分组可能未完成。',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──

  Duration _computeDuration() {
    final start = DateTime.tryParse(record.startedAt ?? '');
    final end = DateTime.tryParse(record.finishedAt ?? '');
    if (start != null && end != null) {
      return end.difference(start);
    }
    return Duration.zero;
  }

  _SessionStats _computeStats() {
    int completed = 0;
    int skipped = 0;
    int total = 0;
    double totalRpe = 0;
    int rpeCount = 0;
    double totalVolume = 0;

    for (final block in record.exerciseBlocks) {
      for (final set in block.sets) {
        total++;
        if (set.state == 'completed') {
          completed++;
          if (set.effortMetrics?.rpe != null &&
              set.effortMetrics!.rpe!.isNotEmpty) {
            final rpe = set.effortMetrics!.rpe!.first;
            if (rpe != null) {
              totalRpe += rpe;
              rpeCount++;
            }
          }
          // Calculate volume (load × reps)
          if (set.actual != null) {
            final load = set.actual!.loadValue?.firstOrNull;
            final reps = set.actual!.rep?.firstOrNull;
            if (load != null && reps != null) {
              totalVolume += load * reps;
            }
          }
        } else if (set.state == 'skipped') {
          skipped++;
        }
      }
    }

    return _SessionStats(
      completed: completed,
      skipped: skipped,
      total: total,
      avgRpe: rpeCount > 0 ? totalRpe / rpeCount : null,
      totalVolume: totalVolume,
    );
  }

  _StatusTag? _getStatusTag(TrainingSet set) {
    if (set.state == 'skipped') {
      return _StatusTag('跳过', AppTheme.textTertiary);
    }
    if (set.state != 'completed') {
      return _StatusTag('未执行', AppTheme.textTertiary);
    }

    final plan = set.workingPlan ?? set.baselinePlan;
    final actual = set.actual;
    if (plan == null || actual == null) return null;

    // Compare load
    final planLoad = plan.loadValue?.firstOrNull;
    final actualLoad = actual.loadValue?.firstOrNull;
    if (planLoad != null && actualLoad != null) {
      if (actualLoad > planLoad) {
        return _StatusTag('上调', AppTheme.secondaryGreen);
      }
      if (actualLoad < planLoad) {
        return _StatusTag('下调', const Color(0xFFFF9800));
      }
    }

    // Compare reps
    final planRep = plan.rep?.firstOrNull;
    final actualRep = actual.rep?.firstOrNull;
    if (planRep != null && actualRep != null) {
      if (actualRep > planRep) {
        return _StatusTag('上调', AppTheme.secondaryGreen);
      }
      if (actualRep < planRep) {
        return _StatusTag('下调', const Color(0xFFFF9800));
      }
    }

    return _StatusTag('按计划', AppTheme.accentBlue);
  }

  String _blockSummary(ExerciseBlock block) {
    final completed = block.sets.where((s) => s.state == 'completed').length;
    return '$completed/${block.sets.length}';
  }

  String _fieldText(SetValues sv, String field) {
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

  String _rangeText(List<double?>? vals, String unit) {
    if (vals == null || vals.isEmpty) return '-';
    final filtered = vals.whereType<double>().toList();
    if (filtered.isEmpty) return '-';
    if (filtered.length == 1) {
      return '${_formatNum(filtered.first)} $unit';
    }
    return '${_formatNum(filtered.first)}-${_formatNum(filtered.last)} $unit';
  }

  String _formatNum(double? v) {
    if (v == null) return '-';
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('yyyy/MM/dd HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _formatVolume(double v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}t';
    }
    return '${v.toInt()}kg';
  }

  Color _rpeColor(double rpe) {
    if (rpe >= 9.5) return AppTheme.dangerRed;
    if (rpe >= 8.5) return const Color(0xFFFF9800);
    if (rpe >= 7) return AppTheme.primaryGold;
    return AppTheme.secondaryGreen;
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color ?? AppTheme.textTertiary),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color ?? AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTag {
  const _StatusTag(this.label, this.color);

  final String label;
  final Color color;
}

class _SessionStats {
  const _SessionStats({
    required this.completed,
    required this.skipped,
    required this.total,
    this.avgRpe,
    this.totalVolume = 0,
  });

  final int completed;
  final int skipped;
  final int total;
  final double? avgRpe;
  final double totalVolume;
}
