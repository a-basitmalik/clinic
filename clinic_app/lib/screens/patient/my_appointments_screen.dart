import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/status_badge.dart';
import '../../routes/app_routes.dart';
import 'patient_portal_base.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with PatientPortalLoader {
  @override
  void initState() {
    super.initState();
    loadPortal();
  }

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        title: 'My Appointments',
        currentRoute: AppRoutes.myAppointments,
        body: portalState((p) {
          final appts = p.appointments;
          if (appts.isEmpty)
            return const Text('No appointments found.',
                style: TextStyle(color: AppColors.textSecondary));
          return Column(
              children: appts
                  .map((a) => Card(
                          child: ListTile(
                        leading: const Icon(Icons.calendar_month_rounded,
                            color: AppColors.primary),
                        title: Text('${a.doctorName} • Token ${a.tokenNumber}'),
                        subtitle: Text(
                            '${Helpers.formatDate(a.appointmentDate)} ${Helpers.formatTime(a.appointmentTime)}'),
                        trailing: StatusBadge(a.status),
                      )))
                  .toList());
        }),
      );
}
