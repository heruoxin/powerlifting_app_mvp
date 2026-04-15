import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A semi-transparent glass-morphism card with backdrop blur,
/// subtle border, and soft shadow – the core visual building block.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius = AppTheme.cardBorderRadius,
    this.onTap,
    this.enableBlur = false,
    this.blurSigma = 10.0,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool enableBlur;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        (color ?? AppTheme.cardWhite).withValues(alpha: AppTheme.glassOpacity);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: enableBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurSigma,
                sigmaY: blurSigma,
              ),
              child: _buildContainer(effectiveColor),
            )
          : _buildContainer(effectiveColor),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }

  Widget _buildContainer(Color bg) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 0.5,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}
