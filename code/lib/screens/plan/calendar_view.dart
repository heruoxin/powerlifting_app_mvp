import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/plan_models.dart';
import '../../models/training_record.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key, required this.appState});

  final AppState appState;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  AppState get _appState => widget.appState;

  // Build a map of DateTime to List of TrainingRecord for calendar markers
  Map<DateTime, List<TrainingRecord>> get _eventMap {
    final map = <DateTime, List<TrainingRecord>>{};
    for (final record in _appState.trainingRecords) {
      try {
        final date = DateTime.parse(record.date);
        final key = DateTime(date.year, date.month, date.day);
        map.putIfAbsent(key, () => []).add(record);
      } catch (_) {}
    }
    return map;
  }

  /// Build a map of DateTime → PlanDay for planned days
  Map<DateTime, _PlanDayInfo> get _planDayMap {
    final map = <DateTime, _PlanDayInfo>{};
    for (final meso in _appState.mesocycles) {
      if (meso.startDate == null) continue;
      try {
        final start = DateTime.parse(meso.startDate!);
        for (final micro in meso.microcycles) {
          for (final day in micro.days) {
            // Training days are spaced every 2 days (matching demo data pattern)
            final date = start.add(
              Duration(days: micro.weekIndex * 7 + day.dayIndex * 2),
            );
            final key = DateTime(date.year, date.month, date.day);
            map[key] = _PlanDayInfo(
              day: day,
              weekLabel: micro.label,
              mesoName: meso.name,
              mesoGoal: meso.goal,
            );
          }
        }
      } catch (_) {}
    }
    return map;
  }

  List<TrainingRecord> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _eventMap[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _buildCalendarHeader(),
        _buildCalendar(),
        const SizedBox(height: 16),
        _buildMonthlySummary(),
        const SizedBox(height: 16),
        _buildSbdMaxes(),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    final meso = _appState.mesocycles.isNotEmpty
        ? _appState.mesocycles.first
        : null;
    final phaseName = meso?.goal ?? meso?.name ?? '';

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'STRENGTH LOG',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textTertiary,
                ),
              ),
              const Spacer(),
              if (phaseName.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryGreen.withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(AppTheme.chipBorderRadius),
                  ),
                  child: Text(
                    phaseName,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('yyyy/MM').format(_focusedDay),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final planDays = _planDayMap;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: TableCalendar<TrainingRecord>(
        firstDay: DateTime(2023, 1, 1),
        lastDay: DateTime(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) =>
            _selectedDay != null && isSameDay(day, _selectedDay),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onPageChanged: (focused) {
          setState(() => _focusedDay = focused);
        },
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerVisible: false,
        daysOfWeekHeight: 28,
        rowHeight: 56,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryGold.withValues(alpha: 0.20),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          selectedDecoration: BoxDecoration(
            color: AppTheme.primaryGold.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          defaultTextStyle: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
          weekendTextStyle: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
          markerDecoration: const BoxDecoration(
            color: AppTheme.secondaryGreen,
            shape: BoxShape.circle,
          ),
          markerSize: 5,
          markersMaxCount: 1,
          markerMargin: const EdgeInsets.only(top: 1),
          cellMargin: const EdgeInsets.all(2),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textTertiary,
            letterSpacing: 0.5,
          ),
          weekendStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        calendarBuilders: CalendarBuilders<TrainingRecord>(
          markerBuilder: (context, day, events) {
            final dayKey = DateTime(day.year, day.month, day.day);
            final planInfo = planDays[dayKey];
            final hasRecord = events.isNotEmpty;
            final isToday = dayKey == todayKey;

            if (!hasRecord && planInfo == null) return null;

            return Positioned(
              bottom: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasRecord)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: events.first.state == 'completed'
                            ? AppTheme.secondaryGreen
                            : AppTheme.primaryGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (hasRecord && planInfo != null) const SizedBox(width: 2),
                  if (planInfo != null && !hasRecord)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isToday
                              ? AppTheme.primaryGold
                              : AppTheme.accentBlue,
                          width: 1,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthlySummary() {
    final monthStart =
        DateTime(_focusedDay.year, _focusedDay.month, 1);
    final monthEnd =
        DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    final monthRecords = _appState.trainingRecords.where((r) {
      try {
        final date = DateTime.parse(r.date);
        return !date.isBefore(monthStart) && !date.isAfter(monthEnd);
      } catch (_) {
        return false;
      }
    }).toList();

    final completedCount =
        monthRecords.where((r) => r.state == 'completed').length;

    // Count PRs from profiles
    final prCount = _countMonthlyPrs(monthStart, monthEnd);

    // Count failed sets
    int failedSets = 0;
    for (final record in monthRecords) {
      for (final block in record.exerciseBlocks) {
        failedSets += block.sets.where((s) => s.state == 'skipped').length;
      }
    }

    // Get current phase
    String phase = '—';
    for (final meso in _appState.mesocycles) {
      if (meso.status == 'active') {
        phase = meso.goal ?? meso.name;
        break;
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '本月总结',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryItem(
                icon: Icons.fitness_center,
                label: '训练次数',
                value: '$completedCount',
                color: AppTheme.secondaryGreen,
              ),
              _summaryItem(
                icon: Icons.emoji_events,
                label: 'PR 突破',
                value: '$prCount',
                color: AppTheme.primaryGold,
              ),
              _summaryItem(
                icon: Icons.cancel_outlined,
                label: '未完成组',
                value: '$failedSets',
                color: failedSets > 0
                    ? AppTheme.dangerRed
                    : AppTheme.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timeline, size: 14,
                  color: AppTheme.textTertiary),
              const SizedBox(width: 6),
              const Text(
                '当前阶段',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  phase,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  int _countMonthlyPrs(DateTime monthStart, DateTime monthEnd) {
    int count = 0;
    for (final profile in _appState.profiles) {
      for (final pr in profile.prSnapshots) {
        try {
          final date = DateTime.parse(pr.date);
          if (!date.isBefore(monthStart) && !date.isAfter(monthEnd)) {
            count++;
          }
        } catch (_) {}
      }
    }
    return count;
  }

  Widget _buildSbdMaxes() {
    final profiles = _appState.profiles;
    final squat =
        profiles.where((p) => p.liftKey == 'squat').firstOrNull;
    final bench =
        profiles.where((p) => p.liftKey == 'bench_press').firstOrNull;
    final deadlift =
        profiles.where((p) => p.liftKey == 'deadlift').firstOrNull;

    if (squat == null && bench == null && deadlift == null) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: AppTheme.textPrimary,
      child: Row(
        children: [
          _sbdItem('S', '深蹲', squat?.currentE1rm, squat?.e1rmUnit ?? 'kg'),
          _sbdDivider(),
          _sbdItem('B', '卧推', bench?.currentE1rm, bench?.e1rmUnit ?? 'kg'),
          _sbdDivider(),
          _sbdItem(
              'D', '硬拉', deadlift?.currentE1rm, deadlift?.e1rmUnit ?? 'kg'),
        ],
      ),
    );
  }

  Widget _sbdItem(String letter, String name, double? e1rm, String unit) {
    return Expanded(
      child: Column(
        children: [
          Text(
            letter,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryGold.withValues(alpha: 0.8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            e1rm != null ? '${e1rm.toStringAsFixed(0)}$unit' : '—',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sbdDivider() {
    return Container(
      width: 0.5,
      height: 36,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

class _PlanDayInfo {
  final PlanDay day;
  final String weekLabel;
  final String mesoName;
  final String? mesoGoal;

  const _PlanDayInfo({
    required this.day,
    required this.weekLabel,
    required this.mesoName,
    this.mesoGoal,
  });
}
