import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../routes/app_routes.dart';
import 'patient_portal_base.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen>
    with PatientPortalLoader {
  @override
  void initState() {
    super.initState();
    loadPortal();
  }

  @override
  Widget build(BuildContext context) => ResponsiveLayout(
        title: 'Medical Records',
        currentRoute: AppRoutes.medicalRecords,
        body: portalState((p) {
          final entries = [
            ...p.appointments.map((a) => _TimelineEntry('Appointment',
                '${a.doctorName} • ${a.status}', a.appointmentDate)),
            ...p.prescriptions.map((rx) => _TimelineEntry('Prescription',
                '${rx.medicines.length} medicines', rx.createdAt)),
          ]..sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));
          if (entries.isEmpty)
            return const Text('No medical records yet.',
                style: TextStyle(color: AppColors.textSecondary));
          return Column(
              children: entries
                  .map((e) => Card(
                          child: ListTile(
                        leading: const CircleAvatar(
                            backgroundColor: AppColors.infoSurface,
                            child: Icon(Icons.history_rounded,
                                color: AppColors.info)),
                        title: Text(e.title),
                        subtitle: Text(e.subtitle),
                        trailing: Text(Helpers.formatDate(e.date)),
                      )))
                  .toList());
        }),
      );
}

class _TimelineEntry {
  final String title;
  final String subtitle;
  final String? date;
  const _TimelineEntry(this.title, this.subtitle, this.date);
}
