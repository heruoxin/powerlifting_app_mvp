import 'dart:math' as math;

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
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(child: _GreetingCard(appState: appState)),
        SliverToBoxAdapter(child: _CycleSummaryCard(appState: appState)),
        SliverToBoxAdapter(child: _BigThreeCard(appState: appState)),
        SliverToBoxAdapter(child: _TrainingHeatmapCard(appState: appState)),
        const SliverToBoxAdapter(child: _BodyWeightCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Greeting Card ────────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final name = appState.settings.userName ?? '运动员';
    final now = DateTime.now();
    final greeting = now.hour < 12 ? '早上好' : (now.hour < 18 ? '下午好' : '晚上好');
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateStr =
        '${now.year}年${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}';

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting，$name',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.3,
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
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            color: AppTheme.textSecondary,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }
}

// ── Training Cycle Summary ───────────────────────────────────────────────────

class _CycleSummaryCard extends StatelessWidget {
  const _CycleSummaryCard({required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final meso = _activeMeso;
    final completed = appState.trainingRecords
        .where((r) => r.state == 'completed')
        .toList();
    final recent = _recentCount(completed);

    final String cycleName;
    final String phase;
    final int doneDays, allDays;
    final double progress;

    if (meso != null) {
      cycleName = meso.name;
      phase = _phaseLabel(meso);
      doneDays = _completedDayCount(meso);
      allDays = _totalDayCount(meso);
      progress = allDays > 0 ? doneDays / allDays : 0;
    } else {
      cycleName = '暂无活跃周期';
      phase = '';
      doneDays = 0;
      allDays = 0;
      progress = 0;
    }

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '训练周期', padding: EdgeInsets.zero),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  cycleName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (phase.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      AppTheme.chipBorderRadius,
                    ),
                  ),
                  child: Text(
                    phase,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF0F0F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$doneDays / $allDays 天',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatChip(
                icon: Icons.local_fire_department_outlined,
                label: '近7天',
                value: '$recent 次',
                color: AppTheme.secondaryGreen,
              ),
              StatChip(
                icon: Icons.emoji_events_outlined,
                label: '累计训练',
                value: '${completed.length} 次',
              ),
              if (meso != null)
                StatChip(
                  icon: Icons.calendar_today_outlined,
                  label: '周进度',
                  value: _weekLabel(meso),
                  color: AppTheme.accentBlue,
                ),
            ],
          ),
          if (meso?.goal != null && meso!.goal!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.track_changes_rounded,
                  size: 14,
                  color: AppTheme.primaryGold.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    meso.goal!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  PlanMesocycle? get _activeMeso {
    for (final m in appState.mesocycles) {
      if (m.status == 'active') return m;
    }
    return appState.mesocycles.isNotEmpty ? appState.mesocycles.first : null;
  }

  static int _weekIdx(PlanMesocycle m) {
    for (var i = 0; i < m.microcycles.length; i++) {
      if (m.microcycles[i].status != 'completed') return i;
    }
    return math.max(0, m.microcycles.length - 1);
  }

  static String _phaseLabel(PlanMesocycle m) {
    final i = _weekIdx(m);
    if (i < m.microcycles.length) {
      final l = m.microcycles[i].label;
      if (l.isNotEmpty) return l;
    }
    return '';
  }

  String _weekLabel(PlanMesocycle m) =>
      'W${_weekIdx(m) + 1}/${m.microcycles.length}';

  int _completedDayCount(PlanMesocycle m) {
    var c = 0;
    for (final mc in m.microcycles) {
      if (mc.status == 'completed') {
        c += mc.days.length;
      } else {
        for (final d in mc.days) {
          if (appState.trainingRecords.any(
            (r) => r.sourcePlanDayUid == d.uid && r.state == 'completed',
          )) {
            c++;
          }
        }
      }
    }
    return c;
  }

  static int _totalDayCount(PlanMesocycle m) =>
      m.microcycles.fold(0, (s, mc) => s + mc.days.length);

  int _recentCount(List<TrainingRecord> recs) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return recs.where((r) {
      final d = DateTime.tryParse(r.date);
      return d != null && d.isAfter(cutoff);
    }).length;
  }
}

// ── Three Big Lifts e1RM ─────────────────────────────────────────────────────

class _BigThreeCard extends StatelessWidget {
  const _BigThreeCard({required this.appState});
  final AppState appState;

  static const _lifts = [
    ('squat', '深蹲', 'S'),
    ('bench_press', '卧推', 'B'),
    ('deadlift', '硬拉', 'D'),
  ];
  static const _colors = [
    AppTheme.primaryGold,
    AppTheme.accentBlue,
    AppTheme.dangerRed,
  ];

  @override
  Widget build(BuildContext context) {
    double maxE1rm = 0;
    for (final (k, _, _) in _lifts) {
      final v = _profileFor(k)?.currentE1rm ?? 0;
      if (v > maxE1rm) maxE1rm = v;
    }
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '三大项 e1RM', padding: EdgeInsets.zero),
          const SizedBox(height: 14),
          for (var i = 0; i < _lifts.length; i++) ...[
            _liftRow(
              _lifts[i].$1,
              _lifts[i].$2,
              _lifts[i].$3,
              _colors[i],
              maxE1rm,
            ),
            if (i < _lifts.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _liftRow(
    String key,
    String label,
    String badge,
    Color color,
    double maxE1rm,
  ) {
    final p = _profileFor(key);
    final e1rm = p?.currentE1rm;
    final unit = p?.e1rmUnit ?? 'kg';
    final bar = (e1rm != null && maxE1rm > 0) ? (e1rm / maxE1rm) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              e1rm != null ? '${e1rm.toStringAsFixed(1)} $unit' : '— $unit',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            _MiniSparkline(history: p?.history ?? [], color: color),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: bar.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: const Color(0xFFF0F0F0),
            valueColor: AlwaysStoppedAnimation<Color>(
              color.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  AthleteLiftProfile? _profileFor(String key) {
    for (final p in appState.profiles) {
      if (p.liftKey == key) return p;
    }
    return null;
  }
}

class _MiniSparkline extends StatelessWidget {
  const _MiniSparkline({required this.history, required this.color});
  final List<E1rmHistoryEntry> history;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final e = history.length > 8
        ? history.sublist(history.length - 8)
        : history;
    if (e.isEmpty) return const SizedBox(width: 56, height: 24);
    final vals = e.map((v) => v.value).toList();
    final hi = vals.reduce(math.max), lo = vals.reduce(math.min);
    return SizedBox(
      width: 56,
      height: 24,
      child: CustomPaint(
        painter: _SparkPainter(
          vals: vals,
          lo: lo,
          range: hi - lo,
          color: color,
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.vals,
    required this.lo,
    required this.range,
    required this.color,
  });
  final List<double> vals;
  final double lo, range;
  final Color color;

  double _y(double v, double h) {
    final f = range > 0 ? (v - lo) / range : 0.5;
    return h - f * h * 0.85 - h * 0.075;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (vals.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < vals.length; i++) {
      final x = i / (vals.length - 1) * size.width;
      final y = _y(vals[i], size.height);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width, _y(vals.last, size.height)),
      2.5,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.vals != vals || old.color != color;
}

// ── Training Heatmap ─────────────────────────────────────────────────────────

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
          const SectionHeader(title: '训练热力图', padding: EdgeInsets.zero),
          const SizedBox(height: 12),
          TrainingHeatmapWidget(records: appState.trainingRecords),
        ],
      ),
    );
  }
}

// ── Body Weight (placeholder) ────────────────────────────────────────────────

class _BodyWeightCard extends StatelessWidget {
  const _BodyWeightCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '体重记录', padding: EdgeInsets.zero),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.monitor_weight_outlined,
                    size: 24,
                    color: AppTheme.primaryGold.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '即将上线',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
