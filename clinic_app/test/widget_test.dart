import 'package:clinic_app/app.dart';
import 'package:clinic_app/core/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('clinic app boots', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthService(),
        child: const ClinicApp(),
      ),
    );

    expect(find.byType(ClinicApp), findsOneWidget);
  });
}
