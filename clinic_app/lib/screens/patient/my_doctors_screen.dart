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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: .16),
                          AppColors.primaryLight.withValues(alpha: .07),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: .22)),
                    ),
                    child: const Icon(Icons.medical_services_rounded,
                        color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('No visited doctors yet.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 15)),
                ]),
              ),
            );
          return Column(
            children: doctors.map((d) => _DoctorCard(name: d)).toList(),
          );
        }),
      );
}

class _DoctorCard extends StatelessWidget {
  final String name;
  const _DoctorCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .88),
            Colors.white.withValues(alpha: .65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: .06),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: .18),
                AppColors.primaryLight.withValues(alpha: .08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: .25)),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'D',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
          ),
          child: const Text('Doctor',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ),
      ]),
    );
  }
}
