import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/premium_surface.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../routes/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Settings',
      currentRoute: AppRoutes.settings,
      body: Column(
        children: [
          ColoredGlassCard(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: .35),
                          blurRadius: 18,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.settings_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text(
                      'Clinic Settings',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage clinic preferences and configuration',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'General',
            items: [
              _SettingsTile(
                icon: Icons.business_rounded,
                label: 'Clinic Profile',
                subtitle: 'Name, address, contact info',
                color: AppColors.primary,
              ),
              _SettingsTile(
                icon: Icons.schedule_rounded,
                label: 'Working Hours',
                subtitle: 'Set clinic operating schedule',
                color: AppColors.info,
              ),
              _SettingsTile(
                icon: Icons.people_rounded,
                label: 'Staff Management',
                subtitle: 'Roles and permissions',
                color: AppColors.glowPurple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'System',
            items: [
              _SettingsTile(
                icon: Icons.notifications_rounded,
                label: 'Notifications',
                subtitle: 'Alerts and reminders',
                color: AppColors.warning,
              ),
              _SettingsTile(
                icon: Icons.security_rounded,
                label: 'Security',
                subtitle: 'Password and access control',
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 24),
          GlassPanel(
            radius: 16,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.info.withValues(alpha: .25)),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      color: AppColors.info, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Full settings management is coming in the next update. Stay tuned!',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsTile> items;
  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.textSecondary)),
      ]),
      const SizedBox(height: 10),
      GlassPanel(
        radius: 18,
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(children: [
              e.value,
              if (!isLast)
                Divider(
                    height: 1,
                    color: AppColors.divider.withValues(alpha: .5)),
            ]);
          }).toList(),
        ),
      ),
    ]);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: .16),
                color.withValues(alpha: .07),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: .22)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded,
            size: 18, color: AppColors.textMuted),
      ]),
    );
  }
}
