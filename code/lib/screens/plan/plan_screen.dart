import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../training/training_workbench_screen.dart';
import 'timeline_view.dart';
import 'calendar_view.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _isCalendarView = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildViewToggle(),
            Expanded(
              child: _isCalendarView
                  ? CalendarView(appState: appState)
                  : TimelineView(appState: appState),
            ),
          ],
        ),
      ),
      floatingActionButton: _isCalendarView
          ? null
          : _buildFab(context, appState),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(AppTheme.smallBorderRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _toggleButton('时间轴', !_isCalendarView, () {
                  setState(() => _isCalendarView = false);
                }),
                _toggleButton('日历视图', _isCalendarView, () {
                  setState(() => _isCalendarView = true);
                }),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '计划',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.cardWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.smallBorderRadius),
          boxShadow: selected ? AppTheme.subtleShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppTheme.textPrimary : AppTheme.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, AppState appState) {
    return FloatingActionButton.extended(
      onPressed: () {
        final nextDay = appState.getNextPlanDay();
        if (nextDay != null) {
          appState.startTraining(planDay: nextDay);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TrainingWorkbenchScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('没有可用的训练计划')),
          );
        }
      },
      icon: const Icon(Icons.play_arrow_rounded, size: 22),
      label: const Text('开始训练'),
      backgroundColor: AppTheme.primaryGold,
      foregroundColor: AppTheme.textPrimary,
    );
  }
}
