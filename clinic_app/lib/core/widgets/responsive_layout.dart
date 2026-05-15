import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../../routes/app_routes.dart';
import 'app_sidebar.dart';

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
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AppSidebar(currentRoute: currentRoute),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(title: title, actions: actions),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: actions,
      ),
      drawer: Drawer(
        child: AppSidebar(currentRoute: currentRoute),
      ),
      bottomNavigationBar: _MobileBottomNav(currentRoute: currentRoute),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: body,
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  final String currentRoute;

  const _MobileBottomNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthService>().currentUser?.role ?? '';
    final items = _items(role);
    if (items.isEmpty) return const SizedBox.shrink();
    final index = items.indexWhere((item) => item.route == currentRoute);
    return NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (i) {
        final route = items[i].route;
        if (route != currentRoute)
          Navigator.pushReplacementNamed(context, route);
      },
      destinations: items
          .map((item) =>
              NavigationDestination(icon: Icon(item.icon), label: item.label))
          .toList(),
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

class _TopBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const _TopBar({required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
