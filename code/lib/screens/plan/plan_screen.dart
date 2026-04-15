import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../training/training_workbench_screen.dart';
import 'plan_editor_screen.dart';
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
            _buildHeader(context),
            _buildViewToggle(),
            Expanded(
              child: _isCalendarView
                  ? CalendarView(appState: appState)
                  : TimelineView(appState: appState),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(context, appState),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
      child: Row(
        children: [
          Text(
            '计划',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlanEditorScreen()),
            ),
            icon: const Icon(Icons.add_rounded, size: 26),
            tooltip: '新建计划',
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
    // If there's already an active training, don't show FAB
    if (appState.activeTraining != null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Free training button
        FloatingActionButton.small(
          heroTag: 'free_train',
          onPressed: () => _startFreeTraining(context, appState),
          backgroundColor: AppTheme.cardWhite,
          foregroundColor: AppTheme.textSecondary,
          elevation: 2,
          child: const Icon(Icons.flash_on_rounded, size: 20),
        ),
        const SizedBox(height: 10),
        // Start planned training button
        FloatingActionButton.extended(
          heroTag: 'start_train',
          onPressed: () => _startPlannedTraining(context, appState),
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          label: const Text('开始训练'),
          backgroundColor: AppTheme.primaryGold,
          foregroundColor: AppTheme.textPrimary,
        ),
      ],
    );
  }

  void _startPlannedTraining(BuildContext context, AppState appState) {
    final nextDay = appState.getNextPlanDay();
    if (nextDay != null) {
      appState.startTraining(planDay: nextDay);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TrainingWorkbenchScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的训练计划')),
      );
    }
  }

  void _startFreeTraining(BuildContext context, AppState appState) {
    appState.startTraining(); // No planDay → free/open session
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TrainingWorkbenchScreen()),
    );
  }
}
