import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/plan_models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../training/training_completion_screen.dart';
import 'plan_day_card.dart';

class TimelineView extends StatefulWidget {
  const TimelineView({super.key, required this.appState});

  final AppState appState;

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  int _selectedCycleIndex = 0;
  int _selectedWeekIndex = 0;
  String _filterCategory = '全部';

  AppState get _appState => widget.appState;

  PlanMesocycle? get _selectedMeso {
    if (_appState.mesocycles.isEmpty) return null;
    return _appState.mesocycles[_selectedCycleIndex.clamp(
      0,
      _appState.mesocycles.length - 1,
    )];
  }

  PlanMicrocycle? get _selectedMicro {
    final meso = _selectedMeso;
    if (meso == null || meso.microcycles.isEmpty) return null;
    return meso.microcycles[_selectedWeekIndex.clamp(
      0,
      meso.microcycles.length - 1,
    )];
  }

  @override
  void initState() {
    super.initState();
    _initSelections();
  }

  @override
  void didUpdateWidget(TimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState != widget.appState) {
      _initSelections();
    }
  }

  void _initSelections() {
    final mesos = _appState.mesocycles;
    if (mesos.isEmpty) return;

    // Find active mesocycle
    final activeIdx = mesos.indexWhere((m) => m.status == 'active');
    _selectedCycleIndex = activeIdx >= 0 ? activeIdx : 0;

    final meso = mesos[_selectedCycleIndex];
    if (meso.microcycles.isEmpty) return;

    // Find first non-completed week
    final weekIdx =
        meso.microcycles.indexWhere((w) => w.status != 'completed');
    _selectedWeekIndex = weekIdx >= 0 ? weekIdx : meso.microcycles.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_appState.mesocycles.isEmpty) {
      return _buildEmptyState();
    }

    final meso = _selectedMeso;
    final micro = _selectedMicro;
    if (meso == null || micro == null) return _buildEmptyState();

    final days = _filteredDays(micro);

    return Column(
      children: [
        _buildSelectors(meso),
        _buildDateRange(meso),
        _buildFilterRow(),
        const SizedBox(height: 4),
        Expanded(
          child: days.isEmpty
              ? _buildNoDaysState()
              : _buildDaysList(days, micro),
        ),
      ],
    );
  }

  Widget _buildSelectors(PlanMesocycle meso) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Cycle dropdown
          _buildDropdownChip(
            label: 'C${_selectedCycleIndex + 1}',
            items: List.generate(
              _appState.mesocycles.length,
              (i) => 'C${i + 1}',
            ),
            onSelected: (idx) => setState(() {
              _selectedCycleIndex = idx;
              _selectedWeekIndex = 0;
            }),
          ),
          const SizedBox(width: 8),
          // Week dropdown
          _buildDropdownChip(
            label: 'W${_selectedWeekIndex + 1}',
            items: List.generate(
              meso.microcycles.length,
              (i) => 'W${i + 1}',
            ),
            onSelected: (idx) => setState(() => _selectedWeekIndex = idx),
          ),
          const Spacer(),
          // Week status badge
          if (_selectedMicro != null)
            _buildStatusChip(_selectedMicro!.status),
        ],
      ),
    );
  }

  Widget _buildDropdownChip({
    required String label,
    required List<String> items,
    required ValueChanged<int> onSelected,
  }) {
    return PopupMenuButton<int>(
      onSelected: onSelected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: const Offset(0, 36),
      itemBuilder: (_) => items.asMap().entries.map((e) {
        return PopupMenuItem<int>(
          value: e.key,
          child: Text(e.value, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.smallBorderRadius),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16,
                color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String text;
    switch (status) {
      case 'completed':
        bg = AppTheme.secondaryGreen.withValues(alpha: 0.12);
        fg = AppTheme.secondaryGreen;
        text = '已完成';
      case 'in_progress':
        bg = AppTheme.primaryGold.withValues(alpha: 0.15);
        fg = AppTheme.primaryGold;
        text = '进行中';
      default:
        bg = AppTheme.accentBlue.withValues(alpha: 0.10);
        fg = AppTheme.accentBlue;
        text = '计划';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.chipBorderRadius),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildDateRange(PlanMesocycle meso) {
    String dateStr = '';
    if (meso.startDate != null) {
      try {
        final start = DateTime.parse(meso.startDate!);
        final weekStart = start.add(Duration(days: _selectedWeekIndex * 7));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final fmt = DateFormat('yyyy年 M月');
        dateStr = fmt.format(weekStart);
        final dayFmt = DateFormat('M/d');
        dateStr += '  ${dayFmt.format(weekStart)} - ${dayFmt.format(weekEnd)}';
      } catch (_) {
        dateStr = '';
      }
    }

    if (dateStr.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          dateStr,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final categories = ['全部', '主项', '主项变式', '辅助项'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _filterCategory = v),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 36),
            itemBuilder: (_) => categories.map((c) {
              return PopupMenuItem<String>(
                value: c,
                child: Text(c, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius:
                    BorderRadius.circular(AppTheme.chipBorderRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_list, size: 14,
                      color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _filterCategory,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down, size: 14,
                      color: AppTheme.textTertiary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PlanDay> _filteredDays(PlanMicrocycle micro) {
    if (_filterCategory == '全部') return micro.days;
    return micro.days.where((day) {
      return day.exerciseItems.any((item) {
        final cat = _categoryForKey(item.exerciseTypeKey);
        return cat == _filterCategory;
      });
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

  Widget _buildDaysList(List<PlanDay> days, PlanMicrocycle micro) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: days.length * 2 + 1, // days + rest markers + end marker
      itemBuilder: (context, index) {
        if (index == days.length * 2) {
          return _buildEndMarker();
        }
        if (index.isOdd) {
          return _buildRestDayMarker(days, index ~/ 2);
        }
        final dayIndex = index ~/ 2;
        final day = days[dayIndex];
        final weekLabel = micro.label;
        return PlanDayCard(
          day: day,
          weekLabel: weekLabel,
          records: _appState.trainingRecords,
          filterCategory: _filterCategory == '全部' ? null : _filterCategory,
          onTapCompleted: (record) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TrainingCompletionScreen(record: record),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRestDayMarker(List<PlanDay> days, int afterIndex) {
    if (afterIndex >= days.length - 1) {
      return const SizedBox(height: 8);
    }
    final currentDay = days[afterIndex];
    final nextDay = days[afterIndex + 1];
    final restDays = nextDay.dayIndex - currentDay.dayIndex - 1;
    if (restDays <= 0) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Container(
            width: 2,
            height: 24,
            color: const Color(0xFFE0E0E0),
          ),
          const SizedBox(width: 12),
          Icon(Icons.nights_stay_outlined, size: 14,
              color: AppTheme.textTertiary.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text(
            '休息 $restDays 天',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textTertiary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndMarker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 28,
                color: AppTheme.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 6),
            Text(
              '没有更多计划安排',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textTertiary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined, size: 48,
              color: AppTheme.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text(
            '暂无训练计划',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '通过 AI 教练创建你的第一个训练周期',
            style: TextStyle(fontSize: 13, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDaysState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt_outlined, size: 36,
              color: AppTheme.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          const Text(
            '当前筛选条件下没有训练日',
            style: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}
