import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary teal
  static const Color primary = Color(0xFF13B9B4);
  static const Color primaryLight = Color(0xFFA8E8E5);
  static const Color primaryDark = Color(0xFF087E7B);
  static const Color primarySurface = Color(0xFFE8F8F8);
  static const Color primaryDeep = Color(0xFF073E45);

  // Accent
  static const Color accent = Color(0xFF72D9D3);
  static const Color accentLight = Color(0xFFC6F0EE);
  static const Color accentSurface = Color(0xFFF1FAFA);

  // Backgrounds
  static const Color background = Color(0xFFF2F8F9);
  static const Color surface = Color(0xFFFAFDFD);
  static const Color cardBg = Color(0xEEFFFFFF);
  static const Color surfaceMuted = Color(0xFFEDF6F7);
  static const Color glass = Color(0xAFFFFFFF);

  // Deep hero bg
  static const Color heroStart = Color(0xFF0D2137);
  static const Color heroMid = Color(0xFF093D38);
  static const Color heroEnd = Color(0xFF2EC4B6);

  // Status
  static const Color success = Color(0xFF27AE60);
  static const Color successSurface = Color(0xFFE9F7EF);
  static const Color warning = Color(0xFFE67E22);
  static const Color warningSurface = Color(0xFFFEF5E7);
  static const Color danger = Color(0xFFE74C3C);
  static const Color dangerSurface = Color(0xFFFEECEB);
  static const Color info = Color(0xFF2980B9);
  static const Color infoSurface = Color(0xFFE9F3FA);

  // Text
  static const Color textPrimary = Color(0xFF123E45);
  static const Color textSecondary = Color(0xFF416870);
  static const Color textMuted = Color(0xFF86A8AE);
  static const Color textHint = Color(0xFFB2C9CD);
  static const Color textOnPrimary = Colors.white;

  // Borders
  static const Color border = Color(0xFFCBE9EA);
  static const Color divider = Color(0xFFE2F2F2);

  // Sidebar (dark)
  static const Color sidebarBg = Color(0xFF0D2137);
  static const Color sidebarHeader = Color(0xFF091A2B);
  static const Color sidebarActive = Color(0xFF2EC4B6);
  static const Color sidebarHover = Color(0x1A2EC4B6);
  static const Color sidebarText = Color(0xFF7DB8C2);
  static const Color sidebarTextActive = Colors.white;
  static const Color sidebarIcon = Color(0xFF5A9DAA);
  static const Color sidebarIconActive = Colors.white;

  // Glow accent colors
  static const Color glowTeal = Color(0xFF2EC4B6);
  static const Color glowBlue = Color(0xFF3D9CF0);
  static const Color glowPurple = Color(0xFF9B7EDE);
  static const Color glowGold = Color(0xFFFFB347);
  static const Color glowEmerald = Color(0xFF27AE60);
  static const Color glowRose = Color(0xFFFF6B6B);

  static Color roleColor(String role) {
    switch (role) {
      case 'super_admin':
        return const Color(0xFF9B7EDE);
      case 'clinic_admin':
        return const Color(0xFF3D9CF0);
      case 'doctor':
        return const Color(0xFF2EC4B6);
      case 'assistant':
        return const Color(0xFF2980B9);
      case 'receptionist':
        return const Color(0xFF27AE60);
      case 'pharmacy':
        return const Color(0xFFE67E22);
      case 'patient':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF7A9FA8);
    }
  }

  static List<Color> roleGradient(String role) {
    switch (role) {
      case 'super_admin':
        return [const Color(0xFF9B7EDE), const Color(0xFF6B4FB0)];
      case 'clinic_admin':
        return [const Color(0xFF3D9CF0), const Color(0xFF2176D9)];
      case 'doctor':
        return [const Color(0xFF2EC4B6), const Color(0xFF0A8A7E)];
      case 'assistant':
        return [const Color(0xFF2980B9), const Color(0xFF1A5E88)];
      case 'receptionist':
        return [const Color(0xFF27AE60), const Color(0xFF1A7A43)];
      case 'pharmacy':
        return [const Color(0xFFE67E22), const Color(0xFFBD6110)];
      case 'patient':
        return [const Color(0xFFFF6B6B), const Color(0xFFCC3D3D)];
      default:
        return [const Color(0xFF2EC4B6), const Color(0xFF0A8A7E)];
    }
  }
}
