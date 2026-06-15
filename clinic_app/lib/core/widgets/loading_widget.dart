import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingWidget({super.key, this.message, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size + 24,
            height: size + 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySurface,
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: .15), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: .15),
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 18),
            Text(
              message!,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}
