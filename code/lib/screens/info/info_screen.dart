import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/athlete_profile.dart';
import '../../models/plan_models.dart';
import '../../models/training_record.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_chip.dart';
import '../settings/settings_screen.dart';
import 'training_heatmap_widget.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(child: _GreetingCard(appState: appState)),
        SliverToBoxAdapter(child: _CycleSummaryCard(appState: appState)),
        SliverToBoxAdapter(child: _PrTrendsCard(appState: appState)),
        SliverToBoxAdapter(child: _TrainingHeatmapCard(appState: appState)),
        SliverToBoxAdapter(child: _BodyWeightCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Greeting Card ──

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final name = appState.settings.userName ?? '运动员';
    final now = DateTime.now();
    final dateStr =
        '${now.year}年${now.month}月${now.day}日 ${_weekdayLabel(now.weekday)}';
    final tokenBalance = appState.settings.tokenBalance;

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $name 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 24),
                color: AppTheme.textSecondary,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StatChip(
            icon: Icons.token_outlined,
            label: 'AI 额度',
            value: tokenBalance.toStringAsFixed(1),
            color: AppTheme.accentBlue,
            backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }

  static String _weekdayLabel(int weekday) {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[weekday - 1];
  }
}

// ── Cycle & Coach Summary ──

class _CycleSummaryCard extends StatelessWidget {
  const _CycleSummaryCard({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final activeMeso = _activeMesocycle;
    final completedRecords = appState.trainingRecords
        .where((r) => r.state == 'completed')
        .toList();
    final recentCount = _recentTrainingCount(completedRecords);

    String cycleLabel;
    double progress;

    if (activeMeso != null) {
      final currentWeek = _currentWeekIndex(activeMeso);
      final totalWeeks = activeMeso.microcycles.length;
      cycleLabel = '${activeMeso.name} W$currentWeek/$totalWeeks';
      progress = totalWeeks > 0 ? currentWeek / totalWeeks : 0;
    } else {
      cycleLabel = '暂无活跃周期';
      progress = 0;
    }

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '训练周期',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          Text(
            cycleLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatChip(
                icon: Icons.fitness_center,
                label: '近7天',
                value: '$recentCount 次',
                color: AppTheme.secondaryGreen,
              ),
              StatChip(
                icon: Icons.history,
                label: '总训练',
                value: '${completedRecords.length} 次',
              ),
            ],
          ),
          if (activeMeso?.goal != null) ...[
            const SizedBox(height: 10),
            Text(
              '🎯 ${activeMeso!.goal}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  PlanMesocycle? get _activeMesocycle {
    for (final m in appState.mesocycles) {
      if (m.status == 'active') return m;
    }
    return appState.mesocycles.isNotEmpty ? appState.mesocycles.first : null;
  }

  int _currentWeekIndex(PlanMesocycle meso) {
    for (var i = 0; i < meso.microcycles.length; i++) {
      if (meso.microcycles[i].status != 'completed') return i + 1;
    }
    return meso.microcycles.length;
  }

  int _recentTrainingCount(List<TrainingRecord> records) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return records.where((r) {
      final date = DateTime.tryParse(r.date);
      return date != null && date.isAfter(cutoff);
    }).length;
  }
}

// ── PR & e1RM Trends ──

class _PrTrendsCard extends StatelessWidget {
  const _PrTrendsCard({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final sbdKeys = ['squat', 'bench_press', 'deadlift'];
    final sbdLabels = ['深蹲', '卧推', '硬拉'];
    final sbdColors = [
      AppTheme.primaryGold,
      AppTheme.accentBlue,
      AppTheme.dangerRed,
    ];

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'e1RM 趋势',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < sbdKeys.length; i++)
            _buildLiftRow(sbdKeys[i], sbdLabels[i], sbdColors[i]),
        ],
      ),
    );
  }

  Widget _buildLiftRow(String key, String label, Color color) {
    final profile = _findProfile(key);
    final e1rm = profile?.currentE1rm;
    final unit = profile?.e1rmUnit ?? 'kg';
    final history = profile?.history ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            e1rm != null ? '${e1rm.toStringAsFixed(1)} $unit' : '-- $unit',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          _MiniBarChart(history: history, color: color),
        ],
      ),
    );
  }

  AthleteLiftProfile? _findProfile(String key) {
    for (final p in appState.profiles) {
      if (p.liftKey == key) return p;
    }
    return null;
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.history, required this.color});
  final List<E1rmHistoryEntry> history;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final entries = history.length > 8 ? history.sublist(history.length - 8) : history;
    if (entries.isEmpty) {
      return const SizedBox(width: 64, height: 24);
    }

    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minVal = entries.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;

    return SizedBox(
      width: 64,
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((e) {
          final fraction = range > 0 ? (e.value - minVal) / range : 1.0;
          final height = 6.0 + fraction * 18.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3 + fraction * 0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Training Heatmap Card ──

class _TrainingHeatmapCard extends StatelessWidget {
  const _TrainingHeatmapCard({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '训练热力图',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          TrainingHeatmapWidget(records: appState.trainingRecords),
        ],
      ),
    );
  }
}

// ── Body Weight Trend (placeholder) ──

class _BodyWeightCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '体重趋势',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.monitor_weight_outlined,
                  size: 40,
                  color: AppTheme.textTertiary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  '体重记录功能即将上线',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
