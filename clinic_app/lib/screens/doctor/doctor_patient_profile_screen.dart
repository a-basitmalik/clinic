import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/doctor_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';

class DoctorPatientProfileScreen extends StatefulWidget {
  final int patientId;
  const DoctorPatientProfileScreen({super.key, required this.patientId});

  @override
  State<DoctorPatientProfileScreen> createState() => _DoctorPatientProfileScreenState();
}

class _DoctorPatientProfileScreenState extends State<DoctorPatientProfileScreen> {
  Map<String, dynamic> _data = {};
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
      _data = await DoctorService.patientProfile(widget.patientId);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = _data['patient'] as Map<String, dynamic>? ?? {};
    final appointments = (_data['appointments'] as List? ?? []);
    final prescriptions = (_data['prescriptions'] as List? ?? []);
    final vitals = (_data['vitals'] as List? ?? []);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(patient['name'] as String? ?? 'Patient Profile')),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _Card(child: Row(children: [
                      const CircleAvatar(backgroundColor: AppColors.primarySurface, child: Icon(Icons.person_rounded, color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(patient['name'] as String? ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        Text([patient['patient_code'], patient['phone'], patient['blood_group']].where((e) => e != null && '$e'.isNotEmpty).join(' • '), style: const TextStyle(color: AppColors.textSecondary)),
                      ])),
                    ])),
                    const SizedBox(height: 16),
                    _ListSection(title: 'Appointments', rows: appointments, builder: (row) => '${Helpers.formatDate(row['appointment_date'] as String? ?? '')} • ${row['status'] ?? ''}'),
                    _ListSection(title: 'Prescriptions', rows: prescriptions, builder: (row) => '${row['diagnosis'] ?? 'Prescription #${row['id']}'} • ${Helpers.formatDate(row['created_at'] as String? ?? '')}'),
                    _ListSection(title: 'Vitals', rows: vitals, builder: (row) => 'BP ${row['blood_pressure'] ?? '-'} • Pulse ${row['pulse'] ?? '-'} • ${Helpers.formatDate(row['created_at'] as String? ?? '')}'),
                  ]),
                ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)), child: child);
}

class _ListSection extends StatelessWidget {
  final String title;
  final List rows;
  final String Function(Map<String, dynamic>) builder;
  const _ListSection({required this.title, required this.rows, required this.builder});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      if (rows.isEmpty) const Text('No records.', style: TextStyle(color: AppColors.textSecondary))
      else ...rows.take(8).map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(builder(e as Map<String, dynamic>)))),
    ])),
  );
}
