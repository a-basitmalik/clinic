import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'premium_surface.dart';

class DataCardList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T item) builder;
  final String? emptyMessage;
  final IconData? emptyIcon;

  const DataCardList({
    super.key,
    required this.items,
    required this.builder,
    this.emptyMessage,
    this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  emptyIcon ?? Icons.inbox_rounded,
                  size: 30,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage ?? 'No records found.',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: items.map(builder).toList());
  }
}

/// Reusable glass card shell with consistent premium styling.
class InfoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? accentColor;

  const InfoCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (accentColor != null) {
      return ColoredGlassCard(
        color: accentColor!,
        radius: 20,
        margin: const EdgeInsets.only(bottom: 10),
        padding: padding ?? const EdgeInsets.all(14),
        onTap: onTap,
        child: child,
      );
    }
    return GlassPanel(
      radius: 20,
      margin: const EdgeInsets.only(bottom: 10),
      padding: padding ?? const EdgeInsets.all(14),
      onTap: onTap,
      child: child,
    );
  }
}
