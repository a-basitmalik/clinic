import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class DataCardList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T item) builder;
  final String? emptyMessage;

  const DataCardList({
    super.key,
    required this.items,
    required this.builder,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_rounded,
                  size: 48, color: AppColors.border),
              const SizedBox(height: 12),
              Text(
                emptyMessage ?? 'No records found.',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: items.map(builder).toList());
  }
}

/// Reusable mobile card shell with consistent styling.
class InfoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const InfoCard({super.key, required this.child, this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: padding ?? const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
          ],
        ),
        child: child,
      ),
    );
  }
}
