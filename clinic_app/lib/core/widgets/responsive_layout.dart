import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../../routes/app_routes.dart';
import 'app_sidebar.dart';
import 'premium_surface.dart';

class ResponsiveLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final String currentRoute;
  final List<Widget>? actions;

  const ResponsiveLayout({
    super.key,
    required this.title,
    required this.body,
    required this.currentRoute,
    this.actions,
  });

  static const int _desktopBreak = 1200;
  static const int _tabletBreak = 600;

  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= _desktopBreak;

  static bool isTablet(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    return w >= _tabletBreak && w < _desktopBreak;
  }

  static bool isMobile(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width < _tabletBreak;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= _desktopBreak) {
      return _DesktopLayout(
        title: title,
        body: body,
        currentRoute: currentRoute,
        actions: actions,
      );
    }
    return _MobileLayout(
      title: title,
      body: body,
      currentRoute: currentRoute,
      actions: actions,
    );
  }
}

// ─── Desktop ──────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final String currentRoute;
  final List<Widget>? actions;

  const _DesktopLayout({
    required this.title,
    required this.body,
    required this.currentRoute,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: SafeArea(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                child: AppSidebar(currentRoute: currentRoute),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DesktopTopBar(title: title, actions: actions),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
                        child: body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mobile ───────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final String currentRoute;
  final List<Widget>? actions;

  const _MobileLayout({
    required this.title,
    required this.body,
    required this.currentRoute,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: _MobileAppBar(title: title, actions: actions),
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AppSidebar(currentRoute: currentRoute),
          ),
        ),
      ),
      bottomNavigationBar: _FloatingBottomNav(currentRoute: currentRoute),
      body: PremiumBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 102),
          child: body,
        ),
      ),
    );
  }
}

// ─── Mobile AppBar ────────────────────────────────────────────────────────

class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const _MobileAppBar({required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          height: 72 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .97),
                Colors.white.withValues(alpha: .92),
                AppColors.primarySurface.withValues(alpha: .76),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: .06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 13,
                child: Builder(
                  builder: (ctx) => _HeaderButton(
                    icon: Icons.menu_rounded,
                    onTap: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
              ),
              Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -.5,
                  ),
                ),
              ),
              Positioned(
                right: 13,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (actions != null) ...actions!,
                    const _NotifButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Floating Bottom Nav ─────────────────────────────────────────────────

class _FloatingBottomNav extends StatelessWidget {
  final String currentRoute;
  const _FloatingBottomNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthService>().currentUser?.role ?? '';
    final items = _items(role);
    if (items.isEmpty) return const SizedBox.shrink();
    final index = items.indexWhere((it) => it.route == currentRoute);
    final sel = index < 0 ? 0 : index;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .88),
                  Colors.white.withValues(alpha: .68),
                  AppColors.primarySurface.withValues(alpha: .34),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: .96),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: .12),
                  blurRadius: 24,
                  spreadRadius: -7,
                  offset: const Offset(0, 11),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final active = i == sel;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!active) {
                        Navigator.pushReplacementNamed(context, item.route);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: active ? 50 : 36,
                            height: active ? 34 : 34,
                            decoration: active
                                ? BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: .40),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  )
                                : null,
                            child: Icon(
                              item.icon,
                              size: active ? 19 : 20,
                              color:
                                  active ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
                              color: active
                                  ? AppColors.primaryDark
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  List<_BottomItem> _items(String role) {
    switch (role) {
      case 'super_admin':
        return const [
          _BottomItem(
              'Home', Icons.dashboard_rounded, AppRoutes.superAdminDashboard),
          _BottomItem(
              'Clinics', Icons.local_hospital_rounded, AppRoutes.clinics),
          _BottomItem('Stats', Icons.analytics_rounded, AppRoutes.systemStats),
          _BottomItem(
              'Revenue', Icons.payments_rounded, AppRoutes.superAdminRevenue),
        ];
      case 'clinic_admin':
        return const [
          _BottomItem(
              'Home', Icons.dashboard_rounded, AppRoutes.clinicAdminDashboard),
          _BottomItem(
              'Doctors', Icons.medical_services_rounded, AppRoutes.doctors),
          _BottomItem('Patients', Icons.people_alt_rounded, AppRoutes.patients),
          _BottomItem('Reports', Icons.bar_chart_rounded, AppRoutes.reports),
        ];
      case 'doctor':
        return const [
          _BottomItem(
              'Home', Icons.dashboard_rounded, AppRoutes.doctorDashboard),
          _BottomItem('Queue', Icons.queue_rounded, AppRoutes.queue),
          _BottomItem(
              'Rx', Icons.receipt_long_rounded, AppRoutes.prescriptions),
          _BottomItem('Earn', Icons.payments_rounded, AppRoutes.earnings),
        ];
      case 'assistant':
        return const [
          _BottomItem(
              'Home', Icons.dashboard_rounded, AppRoutes.assistantDashboard),
          _BottomItem('Queue', Icons.queue_rounded, AppRoutes.assistantQueue),
        ];
      case 'receptionist':
        return const [
          _BottomItem(
              'Home', Icons.dashboard_rounded, AppRoutes.receptionistDashboard),
          _BottomItem(
              'Patients', Icons.people_alt_rounded, AppRoutes.recPatients),
          _BottomItem('Queue', Icons.queue_rounded, AppRoutes.tokenQueue),
          _BottomItem('Bills', Icons.payments_rounded, AppRoutes.billing),
        ];
      case 'pharmacy':
        return const [
          _BottomItem(
              'Home', Icons.dashboard_rounded, AppRoutes.pharmacyDashboard),
          _BottomItem('Stock', Icons.inventory_2_rounded, AppRoutes.inventory),
          _BottomItem(
              'Orders', Icons.assignment_rounded, AppRoutes.pharmacyOrders),
          _BottomItem('Sales', Icons.point_of_sale_rounded, AppRoutes.sales),
        ];
      case 'patient':
        return const [
          _BottomItem(
              'Home', Icons.dashboard_rounded, AppRoutes.patientDashboard),
          _BottomItem(
              'Visits', Icons.calendar_month_rounded, AppRoutes.myAppointments),
          _BottomItem(
              'Rx', Icons.receipt_long_rounded, AppRoutes.myPrescriptions),
          _BottomItem('Bills', Icons.payments_rounded, AppRoutes.myBills),
        ];
      default:
        return const [];
    }
  }
}

class _BottomItem {
  final String label;
  final IconData icon;
  final String route;
  const _BottomItem(this.label, this.icon, this.route);
}

// ─── Desktop top bar ─────────────────────────────────────────────────────

class _DesktopTopBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  const _DesktopTopBar({required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [AppColors.textPrimary, AppColors.textSecondary],
            ).createShader(b),
            blendMode: BlendMode.srcIn,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -.5,
              ),
            ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
          const SizedBox(width: 8),
          const _NotifButton(),
          const SizedBox(width: 8),
          const _AvatarButton(),
        ],
      ),
    );
  }
}

// ─── Shared nav widgets ───────────────────────────────────────────────────

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .88),
            AppColors.primarySurface.withValues(alpha: .45),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .96)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: .07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

class _NotifButton extends StatelessWidget {
  const _NotifButton();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .90),
                AppColors.primarySurface.withValues(alpha: .45),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: .96),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: .08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, size: 19),
            color: AppColors.primaryDark,
            padding: EdgeInsets.zero,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final initials =
        user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
