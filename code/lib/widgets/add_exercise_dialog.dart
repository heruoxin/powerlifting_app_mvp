import 'package:flutter/material.dart';
import '../models/exercise_type.dart';
import '../theme/app_theme.dart';

/// Dialog for selecting an exercise type to add to a training session.
///
/// Shows a searchable list of exercise types grouped by category.
/// Returns the selected [ExerciseType] via [Navigator.pop].
class AddExerciseDialog extends StatefulWidget {
  const AddExerciseDialog({
    super.key,
    required this.exerciseTypes,
  });

  final List<ExerciseType> exerciseTypes;

  /// Convenience method to show the dialog and return the selected type.
  static Future<ExerciseType?> show(
    BuildContext context, {
    required List<ExerciseType> exerciseTypes,
  }) {
    return showDialog<ExerciseType>(
      context: context,
      builder: (_) => AddExerciseDialog(exerciseTypes: exerciseTypes),
    );
  }

  @override
  State<AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<AddExerciseDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExerciseType> get _filtered {
    if (_query.isEmpty) return widget.exerciseTypes;
    final q = _query.toLowerCase();
    return widget.exerciseTypes
        .where((e) =>
            e.displayName.toLowerCase().contains(q) ||
            e.key.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q))
        .toList();
  }

  Map<String, List<ExerciseType>> get _grouped {
    final map = <String, List<ExerciseType>>{};
    for (final ex in _filtered) {
      map.putIfAbsent(ex.category, () => []).add(ex);
    }
    return map;
  }

  static const _categoryOrder = ['main', 'main_variant', 'accessory', 'cardio'];

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final ai = _categoryOrder.indexOf(a);
        final bi = _categoryOrder.indexOf(b);
        return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
      });

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '添加动作',
                      style: TextStyle(
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
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '搜索动作名称...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            const SizedBox(height: 8),

            // Grouped list
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        '没有匹配的动作',
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        for (final cat in sortedKeys) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                            child: Text(
                              _categoryDisplayName(cat),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.categoryColor(cat),
                              ),
                            ),
                          ),
                          ...grouped[cat]!.map((ex) => _ExerciseTile(
                                exercise: ex,
                                onTap: () => Navigator.pop(context, ex),
                              )),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _categoryDisplayName(String cat) {
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

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise, required this.onTap});

  final ExerciseType exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        exercise.displayName,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.add_circle_outline,
        size: 20,
        color: AppTheme.textTertiary,
      ),
      onTap: onTap,
    );
  }
}
