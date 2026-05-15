import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../constants/app_colors.dart';
import '../utils/helpers.dart';
import 'status_badge.dart';
import 'token_badge.dart';

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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
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
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    '${Helpers.formatTime(appointment.appointmentTime)} • ${appointment.consultationType.replaceAll('_', ' ')}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (appointment.patientPhone != null)
                    Text(appointment.patientPhone!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StatusBadge(appointment.status),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onPrimary,
                icon: Icon(primaryIcon, size: 16),
                label: Text(primaryLabel),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
