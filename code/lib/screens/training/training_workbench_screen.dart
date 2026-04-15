import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/training_record.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/set_edit_dialog.dart';
import '../../widgets/add_exercise_dialog.dart';
import 'training_completion_screen.dart';

/// Full-screen training workbench for active session execution.
class TrainingWorkbenchScreen extends StatefulWidget {
  const TrainingWorkbenchScreen({super.key});

  @override
  State<TrainingWorkbenchScreen> createState() =>
      _TrainingWorkbenchScreenState();
}

class _TrainingWorkbenchScreenState extends State<TrainingWorkbenchScreen> {
  Timer? _timer;
  Duration _totalElapsed = Duration.zero;
  Duration _segmentElapsed = Duration.zero;
  String? _currentSegmentLabel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final appState = context.read<AppState>();
      final training = appState.activeTraining;
      if (training == null) return;

      final start = DateTime.tryParse(training.startedAt ?? '');
      if (start != null) {
        setState(() {
          _totalElapsed = DateTime.now().difference(start);
        });
      }

      _updateSegmentInfo(training);
    });
  }

  void _updateSegmentInfo(TrainingRecord training) {
    String? latestFinish;
    String? currentLabel;

    for (final block in training.exerciseBlocks) {
      for (final s in block.sets) {
        if (s.state == 'completed' && s.finishedAt != null) {
          if (latestFinish == null ||
              s.finishedAt!.compareTo(latestFinish) > 0) {
            latestFinish = s.finishedAt;
          }
        }
        if (s.state == 'pending' && currentLabel == null) {
          currentLabel = block.name;
        }
      }
    }

    if (latestFinish != null) {
      final lastFinish = DateTime.tryParse(latestFinish);
      if (lastFinish != null) {
        _segmentElapsed = DateTime.now().difference(lastFinish);
      }
    } else {
      _segmentElapsed = _totalElapsed;
    }
    _currentSegmentLabel = currentLabel ?? '准备中';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _onSetTap(
    BuildContext context,
    ExerciseBlock block,
    TrainingSet set,
    int setIndex,
  ) async {
    final appState = context.read<AppState>();
    final displayCols = [...block.displayColumns];
    if (!displayCols.contains('rpe')) displayCols.add('rpe');

    final result = await SetEditDialog.show(
      context,
      trainingSet: set,
      setIndex: setIndex,
      displayColumns: displayCols,
      weightUnit: appState.settings.defaultWeightUnit,
    );

    if (result != null && result.actual != null) {
      await appState.completeSet(
        block.uid,
        set.uid,
        result.actual!,
        result.effortMetrics,
      );
    }
  }

  Future<void> _onSkipSet(
    BuildContext context,
    String blockUid,
    String setUid,
  ) async {
    final appState = context.read<AppState>();
    await appState.skipSet(blockUid, setUid);
  }

  Future<void> _onAddExercise(BuildContext context) async {
    final appState = context.read<AppState>();
    final type = await showDialog(
      context: context,
      builder: (_) => AddExerciseDialog(exerciseTypes: appState.exerciseTypes),
    );
    if (type != null) {
      await appState.addExerciseToActiveTraining(type);
    }
  }

  Future<void> _onFinishTraining(BuildContext context) async {
    final appState = context.read<AppState>();
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('结束训练'),
        content: const Text('确定要结束本次训练吗？未完成的组将保留当前状态。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('继续训练'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('结束'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Capture the record before finishing (to show in completion screen)
      final finishedRecord = appState.activeTraining;
      await appState.finishTraining();
      if (mounted && finishedRecord != null) {
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => TrainingCompletionScreen(
              record: finishedRecord.copyWith(
                state: 'completed',
                finishedAt: DateTime.now().toIso8601String(),
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final training = appState.activeTraining;

    if (training == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('训练')),
        body: const Center(
          child: Text('没有活跃的训练', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    final planLabel = training.dayLabel ?? training.daySlotLabel;
    final completedSets = _countCompletedSets(training);
    final totalSets = _countTotalSets(training);

    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: Column(
        children: [
          _buildHeaderBar(planLabel, completedSets, totalSets),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 140),
              itemCount: training.exerciseBlocks.length,
              itemBuilder: (context, index) {
                final block = training.exerciseBlocks[index];
                return _buildExerciseBlock(context, block, appState);
              },
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomActions(context, training),
    );
  }

  Widget _buildHeaderBar(String planLabel, int completed, int total) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: AppTheme.trainingBarDark),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      planLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completed/$total 组',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentSegmentLabel ?? '准备中',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDuration(_segmentElapsed),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '总计',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _formatDuration(_totalElapsed),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseBlock(
      BuildContext context, ExerciseBlock block, AppState appState) {
    final currentSetIndex = block.sets.indexWhere((s) => s.state == 'pending');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.categoryColor(block.exerciseCategory)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _categoryLabel(block.exerciseCategory),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.categoryColor(block.exerciseCategory),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  block.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                _blockProgress(block),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textTertiary),
              ),
            ],
          ),
        ),
        if (block.note != null && block.note!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              block.note!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ...block.sets.asMap().entries.map((entry) {
          final idx = entry.key;
          final s = entry.value;
          final isCurrent = idx == currentSetIndex;
          return _buildSetRow(context, block, s, idx, isCurrent);
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton.icon(
            onPressed: () => appState.addSetToBlock(block.uid),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('添加组'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textTertiary,
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const Divider(indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildSetRow(
    BuildContext context,
    ExerciseBlock block,
    TrainingSet set,
    int setIndex,
    bool isCurrent,
  ) {
    final planValues = set.workingPlan ?? set.baselinePlan;
    final actualValues = set.actual;
    final isCompleted = set.state == 'completed';
    final isSkipped = set.state == 'skipped';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primaryGold.withValues(alpha: 0.08)
            : isCompleted
                ? AppTheme.secondaryGreen.withValues(alpha: 0.04)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isCurrent
            ? Border.all(
                color: AppTheme.primaryGold.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: InkWell(
        onTap: isCompleted || isSkipped
            ? null
            : () => _onSetTap(context, block, set, setIndex),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _buildStateIcon(set.state, isCurrent),
              const SizedBox(width: 10),
              SizedBox(
                width: 32,
                child: Text(
                  'S${setIndex + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSkipped
                        ? AppTheme.textTertiary
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: _buildSetContent(
                  block, set, planValues, actualValues, isCompleted, isSkipped,
                ),
              ),
              if (!isCompleted && !isSkipped)
                GestureDetector(
                  onTap: () => _onSkipSet(context, block.uid, set.uid),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.skip_next_rounded,
                        size: 20,
                        color: AppTheme.textTertiary.withValues(alpha: 0.6)),
                  ),
                ),
              if (isCompleted &&
                  set.effortMetrics?.rpe != null &&
                  set.effortMetrics!.rpe!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _rpeColor(set.effortMetrics!.rpe!.first)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'RPE ${_formatRpe(set.effortMetrics!.rpe!.first)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _rpeColor(set.effortMetrics!.rpe!.first),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateIcon(String state, bool isCurrent) {
    switch (state) {
      case 'completed':
        return const Icon(Icons.check_circle,
            size: 20, color: AppTheme.secondaryGreen);
      case 'skipped':
        return Icon(Icons.remove_circle_outline,
            size: 20, color: AppTheme.textTertiary.withValues(alpha: 0.5));
      default:
        if (isCurrent) {
          return Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryGold, width: 2.5),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGold,
                ),
              ),
            ),
          );
        }
        return Icon(Icons.radio_button_unchecked,
            size: 20, color: AppTheme.textTertiary.withValues(alpha: 0.4));
    }
  }

  Widget _buildSetContent(
    ExerciseBlock block,
    TrainingSet set,
    SetValues? planValues,
    SetValues? actualValues,
    bool isCompleted,
    bool isSkipped,
  ) {
    final cols = block.displayColumns;

    if (isCompleted && actualValues != null) {
      return Row(
        children: cols.map((col) {
          return Expanded(
            child: Text(
              _fieldText(actualValues, col),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          );
        }).toList(),
      );
    }

    if (isSkipped) {
      return const Text('已跳过',
          style: TextStyle(
              fontSize: 13,
              color: AppTheme.textTertiary,
              fontStyle: FontStyle.italic));
    }

    if (planValues != null) {
      return Row(
        children: cols.map((col) {
          return Expanded(
            child: Text(
              _fieldText(planValues, col),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          );
        }).toList(),
      );
    }

    return const Text('点击录入',
        style: TextStyle(fontSize: 13, color: AppTheme.textTertiary));
  }

  Widget _buildBottomActions(BuildContext context, TrainingRecord training) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(
          top: BorderSide(
              color: Colors.black.withValues(alpha: 0.06), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _onAddExercise(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加动作'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _onFinishTraining(context),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('结束训练'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _countCompletedSets(TrainingRecord training) {
    int count = 0;
    for (final block in training.exerciseBlocks) {
      count += block.sets.where((s) => s.state == 'completed').length;
    }
    return count;
  }

  int _countTotalSets(TrainingRecord training) {
    int count = 0;
    for (final block in training.exerciseBlocks) {
      count += block.sets.length;
    }
    return count;
  }

  String _blockProgress(ExerciseBlock block) {
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
      return '${_numStr(filtered.first)} $unit';
    }
    return '${_numStr(filtered.first)}-${_numStr(filtered.last)} $unit';
  }

  String _numStr(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _formatRpe(double? v) {
    if (v == null) return '-';
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);
  }

  Color _rpeColor(double? rpe) {
    if (rpe == null) return AppTheme.textTertiary;
    if (rpe >= 9.5) return AppTheme.dangerRed;
    if (rpe >= 8.5) return const Color(0xFFFF9800);
    if (rpe >= 7) return AppTheme.primaryGold;
    return AppTheme.secondaryGreen;
  }

  static String _categoryLabel(String cat) {
    switch (cat) {
      case 'main' || '主项':
        return '主项';
      case 'main_variant' || '主项变式':
        return '变式';
      case 'accessory' || '辅助项':
        return '辅助';
      case 'cardio' || '有氧运动':
        return '有氧';
      default:
        return cat;
    }
  }
}
