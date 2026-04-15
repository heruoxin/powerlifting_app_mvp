import 'package:flutter/material.dart';
import '../models/training_record.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'set_row_widget.dart';

/// Exercise block card showing exercise name, category badge, and set rows.
///
/// Adapts display across three modes:
/// - **plan** – read-only plan preview
/// - **training** – live session with state indicators
/// - **review** – post-completion summary
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.block,
    this.mode = SetRowMode.plan,
    this.onSetTap,
    this.onAddSet,
    this.trailing,
  });

  final ExerciseBlock block;
  final SetRowMode mode;
  final void Function(TrainingSet set, int index)? onSetTap;
  final VoidCallback? onAddSet;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Category badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

              // Exercise name
              Expanded(
                child: Text(
                  block.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),

              if (trailing != null) trailing!,
            ],
          ),

          // Column headers
          if (block.sets.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildColumnHeaders(),
            const Divider(height: 1),
          ],

          // Set rows
          ...block.sets.asMap().entries.map((entry) {
            return SetRowWidget(
              set: entry.value,
              setIndex: entry.key,
              mode: mode,
              displayColumns: block.displayColumns,
              onTap: onSetTap != null
                  ? () => onSetTap!(entry.value, entry.key)
                  : null,
            );
          }),

          // Note
          if (block.note != null && block.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      block.note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Add set button (training mode)
          if (mode == SetRowMode.training && onAddSet != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Center(
                child: TextButton.icon(
                  onPressed: onAddSet,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('添加组'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    textStyle: const TextStyle(fontSize: 13),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          if (mode != SetRowMode.plan) const SizedBox(width: 26),
          const SizedBox(
            width: 28,
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textTertiary,
              ),
            ),
          ),
          ...block.displayColumns.map((col) {
            return Expanded(
              child: Text(
                _colHeader(col),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textTertiary,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _categoryLabel(String cat) {
    switch (cat) {
      case 'main':
        return '主项';
      case 'main_variant':
        return '变式';
      case 'accessory':
        return '辅助';
      case 'cardio':
        return '有氧';
      default:
        return cat;
    }
  }

  static String _colHeader(String col) {
    switch (col) {
      case 'load':
        return '负荷';
      case 'rep':
        return '次数';
      case 'rpe':
        return 'RPE';
      case 'duration':
        return '时长';
      case 'distance':
        return '距离';
      default:
        return col;
    }
  }
}
