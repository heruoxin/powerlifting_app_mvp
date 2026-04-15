import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise_type.dart';
import '../../models/plan_models.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/uid_generator.dart';
import '../../widgets/glass_card.dart';

// =============================================================================
// PlanEditorScreen – create or edit a mesocycle (training plan)
// =============================================================================

class PlanEditorScreen extends StatefulWidget {
  const PlanEditorScreen({super.key, this.existingPlan});

  final PlanMesocycle? existingPlan;

  @override
  State<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends State<PlanEditorScreen> {
  // ── Step control ──
  int _currentStep = 0;
  static const _totalSteps = 3;

  // ── Step 1: Basic info ──
  late final TextEditingController _nameCtrl;
  late final TextEditingController _goalCtrl;
  int _weekCount = 4;
  int _daysPerWeek = 4;

  // ── Step 2: Day configuration ──
  // Keyed by "weekIndex-dayIndex" → mutable exercise list for that day.
  final Map<String, _DayConfig> _dayConfigs = {};

  // ── Editing flag ──
  bool get _isEditing => widget.existingPlan != null;
  bool _isSaving = false;

  // ── Mesocycle UID (stable across saves) ──
  late final String _mesocycleUid;

  @override
  void initState() {
    super.initState();
    final plan = widget.existingPlan;
    _mesocycleUid = plan?.uid ?? UidGenerator.generate();
    _nameCtrl = TextEditingController(text: plan?.name ?? '');
    _goalCtrl = TextEditingController(text: plan?.goal ?? '');

    if (plan != null) {
      _weekCount = plan.microcycles.length.clamp(1, 8);
      _daysPerWeek = plan.microcycles.isEmpty
          ? 4
          : plan.microcycles.first.days.length.clamp(1, 7);
      _populateFromExisting(plan);
    } else {
      _rebuildDayConfigs();
    }
  }

  void _populateFromExisting(PlanMesocycle plan) {
    _dayConfigs.clear();
    for (final micro in plan.microcycles) {
      for (final day in micro.days) {
        final key = '${micro.weekIndex}-${day.dayIndex}';
        _dayConfigs[key] = _DayConfig(
          title: day.dayTitle ?? '',
          exercises: day.exerciseItems.map((item) {
            return _ExerciseConfig(
              exerciseTypeKey: item.exerciseTypeKey,
              displayName: item.displayNameOverride ?? item.exerciseTypeKey,
              recordProfileKey: item.recordProfileKey,
              fieldVisibility: Map<String, bool>.from(item.fieldVisibility),
              sets: item.sets
                  .map((s) => _SetConfig(
                        load: _fieldToString(s.target.load),
                        reps: _fieldToString(s.target.rep),
                        rpe: _fieldToString(s.target.rpe),
                      ))
                  .toList(),
            );
          }).toList(),
        );
      }
    }
    // Fill any missing day slots.
    for (int w = 0; w < _weekCount; w++) {
      for (int d = 0; d < _daysPerWeek; d++) {
        _dayConfigs.putIfAbsent('$w-$d', () => _DayConfig());
      }
    }
  }

  void _rebuildDayConfigs() {
    final preserved = Map<String, _DayConfig>.from(_dayConfigs);
    _dayConfigs.clear();
    for (int w = 0; w < _weekCount; w++) {
      for (int d = 0; d < _daysPerWeek; d++) {
        final key = '$w-$d';
        _dayConfigs[key] = preserved[key] ?? _DayConfig();
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──

  static String _fieldToString(PlanFieldValue fv) {
    if (fv.value == null || fv.value!.isEmpty) return '';
    if (fv.value!.length == 1) {
      return fv.value!.first?.toStringAsFixed(0) ?? '';
    }
    return fv.value!.map((v) => v?.toStringAsFixed(0) ?? '').join('-');
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: Text(_isEditing ? '编辑计划' : '创建计划'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _confirmDiscard(context),
        ),
        actions: [
          if (_currentStep == _totalSteps - 1)
            TextButton(
              onPressed: _isSaving ? null : () => _save(context),
              child: const Text('保存'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(child: _buildCurrentStep()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Step Indicator ──

  Widget _buildStepIndicator() {
    const labels = ['基本信息', '配置训练日', '确认保存'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: GestureDetector(
              onTap: i < _currentStep ? () => setState(() => _currentStep = i) : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (i > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isDone || isActive
                                ? AppTheme.primaryGold
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? AppTheme.primaryGold
                              : isActive
                                  ? AppTheme.primaryGold.withValues(alpha: 0.15)
                                  : const Color(0xFFF0F0F0),
                          border: isActive
                              ? Border.all(color: AppTheme.primaryGold, width: 2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: isDone
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? AppTheme.primaryGold
                                      : AppTheme.textTertiary,
                                ),
                              ),
                      ),
                      if (i < _totalSteps - 1)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: isDone
                                ? AppTheme.primaryGold
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive || isDone
                          ? AppTheme.textPrimary
                          : AppTheme.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Current Step ──

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo();
      case 1:
        return _buildStep2ConfigDays();
      case 2:
        return _buildStep3Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Bottom Bar ──

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('上一步'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: _currentStep < _totalSteps - 1
                ? ElevatedButton(
                    onPressed: _canAdvance() ? _advance : null,
                    child: const Text('下一步'),
                  )
                : ElevatedButton(
                    onPressed: _isSaving ? null : () => _save(context),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.textPrimary,
                            ),
                          )
                        : Text(_isEditing ? '保存修改' : '创建计划'),
                  ),
          ),
        ],
      ),
    );
  }

  bool _canAdvance() {
    if (_currentStep == 0) return _nameCtrl.text.trim().isNotEmpty;
    return true;
  }

  void _advance() {
    if (_currentStep == 0) {
      _rebuildDayConfigs();
    }
    setState(() => _currentStep++);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 1 – Basic Info
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStep1BasicInfo() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Name
        GlassCard(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '计划名称',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: '例如：力量周期 #1',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),

        // Goal
        GlassCard(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '训练目标（可选）',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _goalCtrl,
                decoration: const InputDecoration(
                  hintText: '例如：提升深蹲1RM',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),

        // Week count
        GlassCard(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '训练周数',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '一个中周期通常为 4-8 周',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              _buildCounter(
                value: _weekCount,
                min: 1,
                max: 8,
                label: '周',
                onChanged: (v) => setState(() => _weekCount = v),
              ),
            ],
          ),
        ),

        // Days per week
        GlassCard(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '每周训练天数',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '建议 3-5 天以获得最佳恢复',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              _buildCounter(
                value: _daysPerWeek,
                min: 1,
                max: 7,
                label: '天',
                onChanged: (v) => setState(() => _daysPerWeek = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCounter({
    required int value,
    required int min,
    required int max,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _counterButton(
          icon: Icons.remove_rounded,
          enabled: value > min,
          onTap: () => onChanged(value - 1),
        ),
        Container(
          width: 64,
          alignment: Alignment.center,
          child: Text(
            '$value $label',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        _counterButton(
          icon: Icons.add_rounded,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }

  Widget _counterButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? AppTheme.primaryGold.withValues(alpha: 0.12)
              : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppTheme.primaryGold : AppTheme.textTertiary,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 2 – Configure Training Days
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStep2ConfigDays() {
    return DefaultTabController(
      length: _weekCount,
      child: Column(
        children: [
          TabBar(
            isScrollable: _weekCount > 4,
            labelColor: AppTheme.textPrimary,
            unselectedLabelColor: AppTheme.textTertiary,
            indicatorColor: AppTheme.primaryGold,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            tabs: List.generate(
              _weekCount,
              (i) => Tab(text: '第${i + 1}周'),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: List.generate(_weekCount, (weekIdx) {
                return _buildWeekDays(weekIdx);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDays(int weekIdx) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _daysPerWeek,
      itemBuilder: (context, dayIdx) {
        final key = '$weekIdx-$dayIdx';
        final config = _dayConfigs[key]!;
        return _buildDayCard(weekIdx, dayIdx, config);
      },
    );
  }

  Widget _buildDayCard(int weekIdx, int dayIdx, _DayConfig config) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.chipBorderRadius),
                ),
                child: Text(
                  'D${dayIdx + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InlineTextField(
                  initialValue: config.title,
                  hintText: '训练日标题（可选）',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (v) => config.title = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Exercise list
          if (config.exercises.isNotEmpty)
            ...config.exercises.asMap().entries.map((entry) {
              final exIdx = entry.key;
              final ex = entry.value;
              return _buildExerciseTile(weekIdx, dayIdx, exIdx, ex);
            }),

          // Add exercise button
          Center(
            child: TextButton.icon(
              onPressed: () => _showExercisePicker(weekIdx, dayIdx),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('添加动作'),
            ),
          ),

          // Copy from week 1 hint
          if (weekIdx > 0 && config.exercises.isEmpty)
            Center(
              child: TextButton(
                onPressed: () => _copyFromWeek(0, weekIdx),
                child: Text(
                  '从第1周复制',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.accentBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(
    int weekIdx,
    int dayIdx,
    int exIdx,
    _ExerciseConfig ex,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: _exerciseAccentColor(ex.exerciseTypeKey),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ex.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _removeExercise(weekIdx, dayIdx, exIdx),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sets summary
          if (ex.sets.isNotEmpty)
            ...ex.sets.asMap().entries.map((sEntry) {
              final sIdx = sEntry.key;
              final s = sEntry.value;
              return _buildSetRow(weekIdx, dayIdx, exIdx, sIdx, s);
            }),

          // Add set / quick config
          Row(
            children: [
              GestureDetector(
                onTap: () => _addSet(weekIdx, dayIdx, exIdx),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: AppTheme.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        '添加组',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showQuickSetConfig(weekIdx, dayIdx, exIdx),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 14, color: AppTheme.accentBlue),
                      SizedBox(width: 4),
                      Text(
                        '快速配置',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.accentBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(
    int weekIdx,
    int dayIdx,
    int exIdx,
    int sIdx,
    _SetConfig s,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${sIdx + 1}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 4),
          // Load
          _miniField(
            value: s.load,
            hint: '负重',
            suffix: 'kg',
            width: 72,
            onChanged: (v) => setState(() => s.load = v),
          ),
          const SizedBox(width: 6),
          const Text('×',
              style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
          const SizedBox(width: 6),
          // Reps
          _miniField(
            value: s.reps,
            hint: '次数',
            width: 56,
            onChanged: (v) => setState(() => s.reps = v),
          ),
          const SizedBox(width: 6),
          // RPE
          _miniField(
            value: s.rpe,
            hint: 'RPE',
            width: 48,
            onChanged: (v) => setState(() => s.rpe = v),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _removeSet(weekIdx, dayIdx, exIdx, sIdx),
            child: const Icon(Icons.remove_circle_outline,
                size: 16, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _miniField({
    required String value,
    required String hint,
    String? suffix,
    double width = 60,
    required ValueChanged<String> onChanged,
  }) {
    return _InlineMiniField(
      value: value,
      hint: hint,
      suffix: suffix,
      width: width,
      onChanged: onChanged,
    );
  }

  Color _exerciseAccentColor(String key) {
    final appState = context.read<AppState>();
    final type = appState.exerciseTypes.where((t) => t.key == key).firstOrNull;
    if (type == null) return AppTheme.textTertiary;
    return AppTheme.categoryColor(type.category);
  }

  // ── Exercise actions ──

  void _addSet(int weekIdx, int dayIdx, int exIdx) {
    setState(() {
      final key = '$weekIdx-$dayIdx';
      _dayConfigs[key]!.exercises[exIdx].sets.add(_SetConfig());
    });
  }

  void _removeSet(int weekIdx, int dayIdx, int exIdx, int sIdx) {
    setState(() {
      final key = '$weekIdx-$dayIdx';
      _dayConfigs[key]!.exercises[exIdx].sets.removeAt(sIdx);
    });
  }

  void _removeExercise(int weekIdx, int dayIdx, int exIdx) {
    setState(() {
      final key = '$weekIdx-$dayIdx';
      _dayConfigs[key]!.exercises.removeAt(exIdx);
    });
  }

  void _copyFromWeek(int srcWeek, int dstWeek) {
    setState(() {
      for (int d = 0; d < _daysPerWeek; d++) {
        final srcKey = '$srcWeek-$d';
        final dstKey = '$dstWeek-$d';
        final src = _dayConfigs[srcKey];
        if (src != null) {
          _dayConfigs[dstKey] = _DayConfig(
            title: src.title,
            exercises: src.exercises.map((e) => e.clone()).toList(),
          );
        }
      }
    });
  }

  // ── Exercise Picker ──

  void _showExercisePicker(int weekIdx, int dayIdx) {
    final appState = context.read<AppState>();
    final exercises = appState.exerciseTypes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExercisePickerSheet(
        exerciseTypes: exercises,
        onSelect: (type) {
          setState(() {
            final key = '$weekIdx-$dayIdx';
            _dayConfigs[key]!.exercises.add(
              _ExerciseConfig(
                exerciseTypeKey: type.key,
                displayName: type.displayName,
                recordProfileKey: type.recordProfileKey,
                fieldVisibility:
                    Map<String, bool>.from(type.defaultFieldVisibility),
                sets: [_SetConfig()],
              ),
            );
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  // ── Quick Set Config ──

  void _showQuickSetConfig(int weekIdx, int dayIdx, int exIdx) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '快速配置',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '格式示例: 5x5@80kg、3x8-10、4x6@RPE8',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '例如：5x5@80kg',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  _applyQuickConfig(weekIdx, dayIdx, exIdx, ctrl.text);
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 12),
              // Preset chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickChip(ctx, ctrl, '5x5@80kg', weekIdx, dayIdx, exIdx),
                  _quickChip(ctx, ctrl, '3x8-10', weekIdx, dayIdx, exIdx),
                  _quickChip(ctx, ctrl, '4x6@RPE8', weekIdx, dayIdx, exIdx),
                  _quickChip(ctx, ctrl, '3x12', weekIdx, dayIdx, exIdx),
                  _quickChip(ctx, ctrl, '5x3@90%', weekIdx, dayIdx, exIdx),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _applyQuickConfig(weekIdx, dayIdx, exIdx, ctrl.text);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('应用'),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => ctrl.dispose());
  }

  Widget _quickChip(
    BuildContext ctx,
    TextEditingController ctrl,
    String label,
    int weekIdx,
    int dayIdx,
    int exIdx,
  ) {
    return GestureDetector(
      onTap: () {
        _applyQuickConfig(weekIdx, dayIdx, exIdx, label);
        Navigator.of(ctx).pop();
      },
      child: Chip(
        label: Text(label),
        backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.10),
        side: BorderSide.none,
      ),
    );
  }

  /// Parses strings like "5x5@80kg", "3x8-10", "4x6@RPE8"
  void _applyQuickConfig(int weekIdx, int dayIdx, int exIdx, String input) {
    if (input.trim().isEmpty) return;
    final text = input.trim().toLowerCase();

    // Pattern: SETSxREPS(@LOADkg | @RPEn | @n%)
    final match = RegExp(
      r'^(\d+)\s*[x×]\s*(\d+)(?:\s*-\s*(\d+))?'
      r'(?:\s*@\s*(?:rpe\s*(\d+(?:\.\d+)?)|(\d+(?:\.\d+)?)\s*(%|kg|lb)?))?$',
    ).firstMatch(text);

    if (match == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('格式无法识别，请使用如 5x5@80kg 格式')),
        );
      }
      return;
    }

    final numSets = int.parse(match.group(1)!);
    final repsLow = match.group(2)!;
    final repsHigh = match.group(3);
    final rpeVal = match.group(4);
    final loadOrPercent = match.group(5);
    final loadUnit = match.group(6);

    String repsStr = repsHigh != null ? '$repsLow-$repsHigh' : repsLow;
    String loadStr = '';
    String rpeStr = '';

    if (rpeVal != null) {
      rpeStr = rpeVal;
    } else if (loadOrPercent != null) {
      if (loadUnit == '%') {
        loadStr = '$loadOrPercent%';
      } else {
        loadStr = loadOrPercent;
      }
    }

    setState(() {
      final key = '$weekIdx-$dayIdx';
      final ex = _dayConfigs[key]!.exercises[exIdx];
      ex.sets.clear();
      for (int i = 0; i < numSets; i++) {
        ex.sets.add(_SetConfig(load: loadStr, reps: repsStr, rpe: rpeStr));
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Step 3 – Review & Save
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStep3Review() {
    final totalExercises = _dayConfigs.values
        .fold<int>(0, (sum, d) => sum + d.exercises.length);
    final totalSets = _dayConfigs.values.fold<int>(
      0,
      (sum, d) =>
          sum + d.exercises.fold<int>(0, (s, e) => s + e.sets.length),
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Summary card
        GlassCard(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nameCtrl.text.trim().isEmpty ? '未命名计划' : _nameCtrl.text.trim(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_goalCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _goalCtrl.text.trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _summaryChip(Icons.calendar_today_rounded,
                      '$_weekCount 周'),
                  const SizedBox(width: 12),
                  _summaryChip(Icons.fitness_center_rounded,
                      '$_daysPerWeek 天/周'),
                  const SizedBox(width: 12),
                  _summaryChip(Icons.list_alt_rounded,
                      '$totalExercises 个动作'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _summaryChip(Icons.repeat_rounded,
                      '$totalSets 组'),
                ],
              ),
            ],
          ),
        ),

        // Per-week breakdown
        ...List.generate(_weekCount, (w) => _buildWeekReview(w)),

        // Warning if empty
        if (totalExercises == 0)
          GlassCard(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 12),
            color: AppTheme.dangerRed.withValues(alpha: 0.05),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 20, color: AppTheme.dangerRed),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '您还没有添加任何动作，创建后可以随时编辑。',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _summaryChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.chipBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryGold),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekReview(int weekIdx) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '第${weekIdx + 1}周',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_daysPerWeek, (d) {
            final key = '$weekIdx-$d';
            final config = _dayConfigs[key]!;
            final title = config.title.isNotEmpty
                ? config.title
                : 'D${d + 1}';
            final exCount = config.exercises.length;
            final sCount = config.exercises
                .fold<int>(0, (sum, e) => sum + e.sets.length);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: exCount > 0
                          ? AppTheme.secondaryGreen
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    exCount > 0 ? '$exCount 动作 · $sCount 组' : '无动作',
                    style: TextStyle(
                      fontSize: 12,
                      color: exCount > 0
                          ? AppTheme.textSecondary
                          : AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Save
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _save(BuildContext context) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入计划名称')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final meso = _buildMesocycle();
      final appState = context.read<AppState>();
      await appState.saveMesocycle(meso);
      if (mounted) navigator.pop();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  PlanMesocycle _buildMesocycle() {
    final microcycles = <PlanMicrocycle>[];
    for (int w = 0; w < _weekCount; w++) {
      final microUid = UidGenerator.generate();
      final days = <PlanDay>[];

      for (int d = 0; d < _daysPerWeek; d++) {
        final key = '$w-$d';
        final config = _dayConfigs[key]!;
        final dayUid = UidGenerator.generate();

        final exerciseItems = <PlanExerciseItem>[];
        for (int e = 0; e < config.exercises.length; e++) {
          final exConfig = config.exercises[e];
          final itemUid = UidGenerator.generate();

          final sets = <PlanSet>[];
          for (int s = 0; s < exConfig.sets.length; s++) {
            final sc = exConfig.sets[s];
            sets.add(PlanSet(
              exerciseItemUid: itemUid,
              setOrderInItem: s,
              target: PlanSetTarget(
                load: _parseFieldValue(sc.load, 'kg'),
                rep: _parseFieldValue(sc.reps, null),
                rpe: _parseFieldValue(sc.rpe, null),
              ),
            ));
          }

          exerciseItems.add(PlanExerciseItem(
            uid: itemUid,
            planDayUid: dayUid,
            orderInDay: e,
            exerciseTypeKey: exConfig.exerciseTypeKey,
            displayNameOverride: exConfig.displayName,
            recordProfileKey: exConfig.recordProfileKey,
            fieldVisibility: exConfig.fieldVisibility,
            sets: sets,
          ));
        }

        days.add(PlanDay(
          uid: dayUid,
          microcycleUid: microUid,
          dayIndex: d,
          label: 'D${d + 1}',
          dayTitle: config.title.isNotEmpty ? config.title : null,
          exerciseItems: exerciseItems,
        ));
      }

      microcycles.add(PlanMicrocycle(
        uid: microUid,
        mesocycleUid: _mesocycleUid,
        weekIndex: w,
        label: 'W${w + 1}',
        days: days,
      ));
    }

    return PlanMesocycle(
      uid: _mesocycleUid,
      name: _nameCtrl.text.trim(),
      status: 'active',
      goal: _goalCtrl.text.trim().isNotEmpty ? _goalCtrl.text.trim() : null,
      startDate: widget.existingPlan?.startDate ??
          DateTime.now().toIso8601String().split('T').first,
      microcycles: microcycles,
      createdAt: widget.existingPlan?.createdAt,
    );
  }

  PlanFieldValue _parseFieldValue(String raw, String? defaultUnit) {
    final text = raw.trim();
    if (text.isEmpty) return PlanFieldValue.empty;

    // Handle range: "8-10"
    final rangeMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)(.*)$')
        .firstMatch(text);
    if (rangeMatch != null) {
      final low = double.tryParse(rangeMatch.group(1)!);
      final high = double.tryParse(rangeMatch.group(2)!);
      final unitSuffix = rangeMatch.group(3)?.trim();
      return PlanFieldValue(
        value: [low, high],
        unit: unitSuffix != null && unitSuffix.isNotEmpty
            ? unitSuffix
            : defaultUnit,
        origin: 'user',
      );
    }

    // Handle percentage: "80%"
    final percentMatch =
        RegExp(r'^(\d+(?:\.\d+)?)\s*%$').firstMatch(text);
    if (percentMatch != null) {
      final v = double.tryParse(percentMatch.group(1)!);
      return PlanFieldValue(
        value: v != null ? [v] : null,
        unit: '%',
        origin: 'user',
      );
    }

    // Handle value with optional unit: "80kg", "135lb", or bare "5"
    final numMatch =
        RegExp(r'^(\d+(?:\.\d+)?)\s*(kg|lb)?$').firstMatch(text);
    if (numMatch != null) {
      final v = double.tryParse(numMatch.group(1)!);
      final unit = numMatch.group(2) ?? defaultUnit;
      return PlanFieldValue(
        value: v != null ? [v] : null,
        unit: unit,
        origin: 'user',
      );
    }

    // Fallback: store as text
    return PlanFieldValue(text: text, origin: 'user');
  }

  // ── Discard confirmation ──

  void _confirmDiscard(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('放弃编辑？'),
        content: const Text('未保存的修改将会丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              '放弃',
              style: TextStyle(color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Mutable config models (local editor state, not persisted directly)
// =============================================================================

class _DayConfig {
  String title;
  List<_ExerciseConfig> exercises;

  _DayConfig({this.title = '', List<_ExerciseConfig>? exercises})
      : exercises = exercises ?? [];
}

class _ExerciseConfig {
  final String exerciseTypeKey;
  final String displayName;
  final String recordProfileKey;
  final Map<String, bool> fieldVisibility;
  final List<_SetConfig> sets;

  _ExerciseConfig({
    required this.exerciseTypeKey,
    required this.displayName,
    this.recordProfileKey = 'load_reps_profile',
    Map<String, bool>? fieldVisibility,
    List<_SetConfig>? sets,
  })  : fieldVisibility =
            fieldVisibility ?? PlanExerciseItem.defaultFieldVisibility,
        sets = sets ?? [];

  _ExerciseConfig clone() => _ExerciseConfig(
        exerciseTypeKey: exerciseTypeKey,
        displayName: displayName,
        recordProfileKey: recordProfileKey,
        fieldVisibility: Map<String, bool>.from(fieldVisibility),
        sets: sets.map((s) => _SetConfig(
              load: s.load,
              reps: s.reps,
              rpe: s.rpe,
            )).toList(),
      );
}

class _SetConfig {
  String load;
  String reps;
  String rpe;

  _SetConfig({this.load = '', this.reps = '', this.rpe = ''});
}

// =============================================================================
// Exercise Picker Bottom Sheet
// =============================================================================

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet({
    required this.exerciseTypes,
    required this.onSelect,
  });

  final List<ExerciseType> exerciseTypes;
  final ValueChanged<ExerciseType> onSelect;

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _search = '';
  String _selectedCategory = '全部';

  static const _categories = ['全部', '主项', '主项变式', '辅助项', '有氧运动'];
  static const _categoryKeys = {
    '全部': null,
    '主项': 'main',
    '主项变式': 'main_variant',
    '辅助项': 'accessory',
    '有氧运动': 'cardio',
  };

  List<ExerciseType> get _filtered {
    var list = widget.exerciseTypes;
    final catKey = _categoryKeys[_selectedCategory];
    if (catKey != null) {
      list = list.where((e) => e.category == catKey).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((e) =>
              e.displayName.toLowerCase().contains(q) ||
              e.key.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  '选择动作',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              autofocus: false,
              decoration: const InputDecoration(
                hintText: '搜索动作…',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 8),
          // Category chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryGold
                          : const Color(0xFFF0F0F0),
                      borderRadius:
                          BorderRadius.circular(AppTheme.chipBorderRadius),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          // List
          Flexible(
            child: _filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        '未找到匹配的动作',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 4, 12, 12 + bottomPad),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final type = _filtered[i];
                      return ListTile(
                        dense: true,
                        leading: Container(
                          width: 4,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.categoryColor(type.category),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        title: Text(
                          type.displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _categoryLabel(type.category),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.add_circle_outline,
                            size: 20, color: AppTheme.primaryGold),
                        onTap: () => widget.onSelect(type),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static String _categoryLabel(String cat) {
    switch (cat) {
      case 'main':
        return '主项';
      case 'main_variant':
        return '主项变式';
      case 'accessory':
        return '辅助项';
      case 'cardio':
        return '有氧运动';
      default:
        return cat;
    }
  }
}

// =============================================================================
// _InlineTextField – manages its own TextEditingController lifecycle
// =============================================================================

class _InlineTextField extends StatefulWidget {
  const _InlineTextField({
    required this.initialValue,
    required this.onChanged,
    this.hintText,
    this.isDense = false,
    this.contentPadding,
    this.style,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final bool isDense;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? style;

  @override
  State<_InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<_InlineTextField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_InlineTextField old) {
    super.didUpdateWidget(old);
    if (old.initialValue != widget.initialValue &&
        _ctrl.text != widget.initialValue) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      decoration: InputDecoration(
        hintText: widget.hintText,
        isDense: widget.isDense,
        contentPadding: widget.contentPadding,
      ),
      style: widget.style,
      onChanged: widget.onChanged,
    );
  }
}

// =============================================================================
// _InlineMiniField – small input field with managed controller
// =============================================================================

class _InlineMiniField extends StatefulWidget {
  const _InlineMiniField({
    required this.value,
    required this.hint,
    this.suffix,
    this.width = 60,
    required this.onChanged,
  });

  final String value;
  final String hint;
  final String? suffix;
  final double width;
  final ValueChanged<String> onChanged;

  @override
  State<_InlineMiniField> createState() => _InlineMiniFieldState();
}

class _InlineMiniFieldState extends State<_InlineMiniField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_InlineMiniField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: 32,
      child: TextField(
        controller: _ctrl,
        decoration: InputDecoration(
          hintText: widget.hint,
          suffixText: widget.suffix,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: AppTheme.primaryGold, width: 1.5),
          ),
          hintStyle:
              const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
          suffixStyle:
              const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
        ),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        keyboardType: TextInputType.text,
        onChanged: widget.onChanged,
      ),
    );
  }
}
