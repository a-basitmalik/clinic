import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/doctor_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/api_response_model.dart';
import '../../models/appointment_model.dart';
import '../../routes/app_routes.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  List<AppointmentModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await DoctorService.todayAppointments();
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _error = e.message;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Schedule',
      currentRoute: AppRoutes.doctorSchedule,
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(48),
                          child: Text('No appointments today.',
                              style:
                                  TextStyle(color: AppColors.textSecondary))))
                  : Column(
                      children: _items
                          .map((a) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: const Icon(Icons.schedule_rounded,
                                      color: AppColors.primary),
                                  title: Text(
                                      a.patientName.isEmpty
                                          ? 'Patient #${a.patientId ?? ''}'
                                          : a.patientName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  subtitle: Text(
                                      '${Helpers.formatTime(a.appointmentTime)} • ${a.consultationType}'),
                                  trailing: StatusBadge(a.status),
                                ),
                              ))
                          .toList()),
    );
  }
}
