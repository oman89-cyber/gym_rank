import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? borderRadius;
  final bool showBorder;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.showBorder = true,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? 14),
        border: showBorder 
            ? Border.all(color: AppColors.border, width: 0.5) 
            : null,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}
