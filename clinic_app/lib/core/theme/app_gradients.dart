import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient hero = LinearGradient(
    colors: [
      Color(0xFF0D2137),
      Color(0xFF093D38),
      Color(0xFF2EC4B6),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0, .52, 1],
  );

  static const LinearGradient background = LinearGradient(
    colors: [
      Color(0xFFF5FAFB),
      Color(0xFFECF7F8),
      Color(0xFFF4FAFA),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient teal = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gold = LinearGradient(
    colors: [Color(0xFFE67E22), Color(0xFFFFB347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emerald = LinearGradient(
    colors: [Color(0xFF27AE60), Color(0xFF2FCCA1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient rose = LinearGradient(
    colors: [Color(0xFFE74C3C), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blue = LinearGradient(
    colors: [Color(0xFF2980B9), Color(0xFF3D9CF0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purple = LinearGradient(
    colors: [Color(0xFF9B7EDE), Color(0xFF6B4FB0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient forColor(Color color) => LinearGradient(
        colors: [color, color.withValues(alpha: .65)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient glowCard(Color color) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: .72),
          color.withValues(alpha: .08),
          color.withValues(alpha: .04),
        ],
      );
}
