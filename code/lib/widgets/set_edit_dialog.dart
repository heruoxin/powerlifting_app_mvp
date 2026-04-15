import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/training_record.dart';
import '../theme/app_theme.dart';

/// Result returned when the user confirms an edit.
class SetEditResult {
  const SetEditResult({
    this.actual,
    this.effortMetrics,
  });

  final SetValues? actual;
  final EffortMetrics? effortMetrics;
}

/// Dialog for editing set values (load, reps, RPE) during a training session.
///
/// Presents fields based on [displayColumns] and pre-fills from plan values.
class SetEditDialog extends StatefulWidget {
  const SetEditDialog({
    super.key,
    required this.trainingSet,
    required this.setIndex,
    this.displayColumns = const ['load', 'rep', 'rpe'],
    this.weightUnit = 'kg',
  });

  final TrainingSet trainingSet;
  final int setIndex;
  final List<String> displayColumns;
  final String weightUnit;

  /// Convenience method to show the dialog and return the result.
  static Future<SetEditResult?> show(
    BuildContext context, {
    required TrainingSet trainingSet,
    required int setIndex,
    List<String> displayColumns = const ['load', 'rep', 'rpe'],
    String weightUnit = 'kg',
  }) {
    return showDialog<SetEditResult>(
      context: context,
      builder: (_) => SetEditDialog(
        trainingSet: trainingSet,
        setIndex: setIndex,
        displayColumns: displayColumns,
        weightUnit: weightUnit,
      ),
    );
  }

  @override
  State<SetEditDialog> createState() => _SetEditDialogState();
}

class _SetEditDialogState extends State<SetEditDialog> {
  late final TextEditingController _loadCtrl;
  late final TextEditingController _repCtrl;
  late final TextEditingController _rpeCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _distanceCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    // Pre-fill from actual → workingPlan → baselinePlan
    final actual = widget.trainingSet.actual;
    final plan =
        widget.trainingSet.workingPlan ?? widget.trainingSet.baselinePlan;

    _loadCtrl = TextEditingController(
        text: _firstVal(actual?.loadValue) ?? _firstVal(plan?.loadValue) ?? '');
    _repCtrl = TextEditingController(
        text: _firstVal(actual?.rep) ?? _firstVal(plan?.rep) ?? '');
    _rpeCtrl = TextEditingController(
        text: _firstRpe(widget.trainingSet.effortMetrics) ?? '');
    _durationCtrl = TextEditingController(
        text: _firstVal(actual?.duration) ??
            _firstVal(plan?.duration) ??
            '');
    _distanceCtrl = TextEditingController(
        text: _firstVal(actual?.distance) ??
            _firstVal(plan?.distance) ??
            '');
    _noteCtrl =
        TextEditingController(text: actual?.note ?? plan?.note ?? '');
  }

  @override
  void dispose() {
    _loadCtrl.dispose();
    _repCtrl.dispose();
    _rpeCtrl.dispose();
    _durationCtrl.dispose();
    _distanceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String? _firstVal(List<double?>? vals) {
    if (vals == null || vals.isEmpty) return null;
    final v = vals.first;
    if (v == null) return null;
    return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
  }

  String? _firstRpe(EffortMetrics? e) {
    if (e == null || e.rpe == null || e.rpe!.isEmpty) return null;
    final v = e.rpe!.first;
    if (v == null) return null;
    return v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
  }

  void _submit() {
    final loadVal = double.tryParse(_loadCtrl.text);
    final repVal = double.tryParse(_repCtrl.text);
    final rpeVal = double.tryParse(_rpeCtrl.text);
    final durVal = double.tryParse(_durationCtrl.text);
    final distVal = double.tryParse(_distanceCtrl.text);
    final noteVal = _noteCtrl.text.trim();

    final actual = SetValues(
      loadValue: loadVal != null ? [loadVal] : null,
      loadUnit: widget.weightUnit,
      rep: repVal != null ? [repVal] : null,
      duration: durVal != null ? [durVal] : null,
      distance: distVal != null ? [distVal] : null,
      note: noteVal.isNotEmpty ? noteVal : null,
    );

    final effort = rpeVal != null
        ? EffortMetrics(rpe: [rpeVal])
        : null;

    Navigator.pop(
      context,
      SetEditResult(actual: actual, effortMetrics: effort),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planSource =
        widget.trainingSet.workingPlan ?? widget.trainingSet.baselinePlan;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
              children: [
                Expanded(
                  child: Text(
                    '第 ${widget.setIndex + 1} 组',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            // Plan hint
            if (planSource != null) ...[
              const SizedBox(height: 4),
              Text(
                '计划: ${_planSummary(planSource)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Dynamic fields
            if (widget.displayColumns.contains('load'))
              _buildField(
                controller: _loadCtrl,
                label: '负荷 (${widget.weightUnit})',
                icon: Icons.fitness_center,
              ),
            if (widget.displayColumns.contains('rep'))
              _buildField(
                controller: _repCtrl,
                label: '次数',
                icon: Icons.repeat,
              ),
            if (widget.displayColumns.contains('rpe'))
              _buildField(
                controller: _rpeCtrl,
                label: 'RPE (1-10)',
                icon: Icons.speed,
              ),
            if (widget.displayColumns.contains('duration'))
              _buildField(
                controller: _durationCtrl,
                label: '时长 (s)',
                icon: Icons.timer,
              ),
            if (widget.displayColumns.contains('distance'))
              _buildField(
                controller: _distanceCtrl,
                label: '距离 (m)',
                icon: Icons.straighten,
              ),

            // Note
            const SizedBox(height: 4),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: '备注',
                prefixIcon: Icon(Icons.note_outlined, size: 20),
              ),
              textInputAction: TextInputAction.done,
              maxLines: 1,
            ),

            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('完成'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        ],
        textInputAction: TextInputAction.next,
      ),
    );
  }

  String _planSummary(SetValues sv) {
    final parts = <String>[];
    if (sv.loadValue != null && sv.loadValue!.isNotEmpty) {
      final v = sv.loadValue!.first;
      if (v != null) parts.add('${_numStr(v)} ${sv.loadUnit ?? "kg"}');
    }
    if (sv.rep != null && sv.rep!.isNotEmpty) {
      final v = sv.rep!.first;
      if (v != null) parts.add('${_numStr(v)} 次');
    }
    return parts.isEmpty ? '-' : parts.join(' × ');
  }

  String _numStr(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}
