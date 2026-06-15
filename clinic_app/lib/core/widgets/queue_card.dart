import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../constants/app_colors.dart';
import '../utils/helpers.dart';
import 'status_badge.dart';
import 'token_badge.dart';
import 'premium_surface.dart';

class QueueCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onTap;
  final VoidCallback? onPrimary;
  final String primaryLabel;
  final IconData primaryIcon;

  const QueueCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.onPrimary,
    this.primaryLabel = 'Open',
    this.primaryIcon = Icons.chevron_right_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredGlassCard(
      color: AppColors.primary,
      radius: 20,
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            TokenBadge(appointment.tokenNumber, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patientName.isEmpty
                        ? 'Patient #${appointment.patientId ?? ''}'
                        : appointment.patientName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        Helpers.formatTime(appointment.appointmentTime),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          appointment.consultationType.replaceAll('_', ' '),
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (appointment.patientPhone != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.phone_rounded,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(appointment.patientPhone!,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(appointment.status),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onPrimary,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: .35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(primaryIcon, size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          primaryLabel,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
