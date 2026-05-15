import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../routes/app_routes.dart';
import 'patient_portal_base.dart';

class MyDoctorsScreen extends StatefulWidget {
  const MyDoctorsScreen({super.key});

  @override
  State<MyDoctorsScreen> createState() => _MyDoctorsScreenState();
}

class _MyDoctorsScreenState extends State<MyDoctorsScreen>
    with PatientPortalLoader {
  @override
  void initState() {
    super.initState();
    loadPortal();
  }

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        title: 'My Doctors',
        currentRoute: AppRoutes.myDoctors,
        body: portalState((p) {
          final doctors = p.history?.visitedDoctors ?? [];
          if (doctors.isEmpty)
            return const Text('No visited doctors yet.',
                style: TextStyle(color: AppColors.textSecondary));
          return Column(
              children: doctors
                  .map((d) => Card(
                          child: ListTile(
                        leading: const CircleAvatar(
                            backgroundColor: AppColors.primarySurface,
                            child: Icon(Icons.medical_services_rounded,
                                color: AppColors.primary)),
                        title: Text(d),
                      )))
                  .toList());
        }),
      );
}
