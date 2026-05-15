import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/doctor_service.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/queue_card.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../models/appointment_model.dart';
import '../../routes/app_routes.dart';
import 'consultation_screen.dart';
import 'doctor_patient_profile_screen.dart';

class DoctorQueueScreen extends StatefulWidget {
  const DoctorQueueScreen({super.key});

  @override
  State<DoctorQueueScreen> createState() => _DoctorQueueScreenState();
}

class _DoctorQueueScreenState extends State<DoctorQueueScreen> {
  List<AppointmentModel> _queue = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _queue = await DoctorService.queue();
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Patient Queue',
      currentRoute: AppRoutes.queue,
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _queue.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(48), child: Text('No patients in queue.', style: TextStyle(color: AppColors.textSecondary))))
                  : Column(children: _queue.map((a) => QueueCard(
                      appointment: a,
                      primaryLabel: a.status == 'in_consultation' ? 'Continue' : 'Start',
                      primaryIcon: Icons.play_arrow_rounded,
                      onPrimary: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConsultationScreen(appointment: a))).then((_) => _load()),
                      onTap: a.patientId == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorPatientProfileScreen(patientId: a.patientId!))),
                    )).toList()),
    );
  }
}
