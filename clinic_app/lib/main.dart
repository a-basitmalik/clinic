import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/services/auth_service.dart';
import 'core/services/api_service.dart';
import 'routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Wire 401 logout handler before any request fires
  ApiService.setUnauthorizedCallback(() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const ClinicApp(),
    ),
  );
}
