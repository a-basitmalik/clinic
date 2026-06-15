import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum ButtonVariant { primary, secondary, outlined, danger }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool loading;
  final IconData? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.loading = false,
    this.icon,
    this.width,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || loading;

    final content = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          );

    switch (variant) {
      case ButtonVariant.primary:
        return SizedBox(
          width: width,
          height: height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: isDisabled
                      ? LinearGradient(colors: [
                          AppColors.primary.withValues(alpha: .45),
                          AppColors.primaryDark.withValues(alpha: .45),
                        ])
                      : const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDisabled
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .38),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Center(
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white),
                    child: IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

      case ButtonVariant.secondary:
        return SizedBox(
          width: width,
          height: height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.accentLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: .35),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Center(
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white),
                    child: IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

      case ButtonVariant.outlined:
        return SizedBox(
          width: width,
          height: height,
          child: OutlinedButton(
            onPressed: isDisabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.glass,
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: .4), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: content,
          ),
        );

      case ButtonVariant.danger:
        return SizedBox(
          width: width,
          height: height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.danger, Color(0xFFBD3228)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: .35),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Center(
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white),
                    child: IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}
