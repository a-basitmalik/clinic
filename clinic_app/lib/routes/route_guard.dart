import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import '../core/widgets/loading_widget.dart';
import 'app_routes.dart';

class RouteGuard extends StatelessWidget {
  final Widget child;
  final List<String>? allowedRoles;

  const RouteGuard({super.key, required this.child, this.allowedRoles});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.initialized) {
      return const Scaffold(body: LoadingWidget(message: 'Loading…'));
    }

    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      });
      return const Scaffold(body: LoadingWidget());
    }

    final role = auth.currentUser!.role;

    if (allowedRoles != null && !allowedRoles!.contains(role)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboardForRole(role),
          (_) => false,
        );
      });
      return const Scaffold(body: LoadingWidget());
    }

    return child;
  }
}
