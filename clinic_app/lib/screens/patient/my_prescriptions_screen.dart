import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../routes/app_routes.dart';
import 'patient_portal_base.dart';
import 'prescription_details_screen.dart';

class MyPrescriptionsScreen extends StatefulWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  State<MyPrescriptionsScreen> createState() => _MyPrescriptionsScreenState();
}

class _MyPrescriptionsScreenState extends State<MyPrescriptionsScreen>
    with PatientPortalLoader {
  @override
  void initState() {
    super.initState();
    loadPortal();
  }

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        title: 'My Prescriptions',
        currentRoute: AppRoutes.myPrescriptions,
        body: portalState((p) {
          if (p.prescriptions.isEmpty)
            return const Text('No prescriptions found.',
                style: TextStyle(color: AppColors.textSecondary));
          return Column(
              children: p.prescriptions
                  .map((rx) => Card(
                          child: ListTile(
                        leading: const Icon(Icons.receipt_long_rounded,
                            color: AppColors.accent),
                        title: Text('Prescription #${rx.id}'),
                        subtitle: Text(
                            '${Helpers.formatDate(rx.createdAt)} • ${rx.medicines.length} medicines'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    PatientPrescriptionDetailsScreen(
                                        prescription: rx))),
                      )))
                  .toList());
        }),
      );
}
