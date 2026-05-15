import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary ──────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color primaryDark  = Color(0xFF003C8F);
  static const Color primarySurface = Color(0xFFE3F2FD);

  // ── Accent / Teal ─────────────────────────────────────────────────────────
  static const Color accent        = Color(0xFF00897B);
  static const Color accentLight   = Color(0xFF4DB6AC);
  static const Color accentSurface = Color(0xFFE0F2F1);

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF6F9FC);
  static const Color surface    = Colors.white;
  static const Color cardBg     = Colors.white;

  // ── Status colours ────────────────────────────────────────────────────────
  static const Color success        = Color(0xFF2E7D32);
  static const Color successSurface = Color(0xFFE8F5E9);
  static const Color warning        = Color(0xFFF57C00);
  static const Color warningSurface = Color(0xFFFFF3E0);
  static const Color danger         = Color(0xFFC62828);
  static const Color dangerSurface  = Color(0xFFFFEBEE);
  static const Color info           = Color(0xFF0277BD);
  static const Color infoSurface    = Color(0xFFE1F5FE);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textMuted     = Color(0xFF9E9E9E);
  static const Color textHint      = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;

  // ── Borders / Dividers ────────────────────────────────────────────────────
  static const Color border  = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF0F0F0);

  // ── Sidebar ───────────────────────────────────────────────────────────────
  static const Color sidebarBg     = Color(0xFF0D1B4B);
  static const Color sidebarHeader = Color(0xFF0A1540);
  static const Color sidebarActive = Color(0xFF1565C0);
  static const Color sidebarHover  = Color(0xFF162260);
  static const Color sidebarText   = Color(0xFFB0BEC5);
  static const Color sidebarTextActive = Colors.white;
  static const Color sidebarIcon   = Color(0xFF78909C);
  static const Color sidebarIconActive = Colors.white;

  // ── Role badge colours ────────────────────────────────────────────────────
  static Color roleColor(String role) {
    switch (role) {
      case 'super_admin':   return const Color(0xFF6A1B9A);
      case 'clinic_admin':  return const Color(0xFF1565C0);
      case 'doctor':        return const Color(0xFF00695C);
      case 'assistant':     return const Color(0xFF0277BD);
      case 'receptionist':  return const Color(0xFF558B2F);
      case 'pharmacy':      return const Color(0xFFE65100);
      case 'patient':       return const Color(0xFF37474F);
      default:              return const Color(0xFF546E7A);
    }
  }
}
