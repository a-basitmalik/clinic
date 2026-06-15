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
                          AppColors.accent.withValues(alpha: .16),
                          AppColors.accent.withValues(alpha: .07),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: .22)),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppColors.accent, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('No prescriptions found.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 15)),
                ]),
              ),
            );
          return Column(
            children: p.prescriptions
                .map((rx) => _RxCard(
                      rx: rx,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PatientPrescriptionDetailsScreen(
                                      prescription: rx))),
                    ))
                .toList(),
          );
        }),
      );
}

class _RxCard extends StatelessWidget {
  final dynamic rx;
  final VoidCallback onTap;
  const _RxCard({required this.rx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          border:
              Border.all(color: AppColors.accent.withValues(alpha: .18)),
          boxShadow: [
            BoxShadow(
                color: AppColors.accent.withValues(alpha: .06),
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
                  AppColors.accent.withValues(alpha: .18),
                  AppColors.accent.withValues(alpha: .07),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: .25)),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Prescription #${rx.id}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 3),
              Text(
                '${Helpers.formatDate(rx.createdAt)}  •  ${rx.medicines.length} medicine${rx.medicines.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ]),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.accent),
          ),
        ]),
      ),
    );
  }
}
