import 'package:flutter/material.dart';
import '../models/ai_topic.dart';
import '../theme/app_theme.dart';

/// A chip that shows an AI context reference (plan, record, note, etc.)
/// with a type-appropriate icon and display label.
class AiContextChip extends StatelessWidget {
  const AiContextChip({
    super.key,
    required this.reference,
    this.onTap,
    this.onRemove,
  });

  final ContextReference reference;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  IconData get _icon {
    switch (reference.type) {
      case 'plan':
        return Icons.calendar_today;
      case 'record' || 'training_record':
        return Icons.fitness_center;
      case 'note':
        return Icons.sticky_note_2_outlined;
      case 'profile':
        return Icons.person_outline;
      case 'memory':
        return Icons.psychology_outlined;
      case 'exercise_type':
        return Icons.sports_gymnastics;
      default:
        return Icons.link;
    }
  }

  Color get _color {
    switch (reference.type) {
      case 'plan':
        return AppTheme.accentBlue;
      case 'record' || 'training_record':
        return AppTheme.primaryGold;
      case 'note':
        return AppTheme.secondaryGreen;
      case 'profile':
        return const Color(0xFFAB47BC);
      case 'memory':
        return const Color(0xFFFF7043);
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label =
        reference.displayLabel ?? reference.type;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.chipBorderRadius),
          border: Border.all(
            color: _color.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 14, color: _color),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: _color.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
