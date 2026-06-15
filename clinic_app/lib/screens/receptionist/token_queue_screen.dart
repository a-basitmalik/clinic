import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/appointment_service.dart';
import '../../core/services/doctor_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/date_filter_bar.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/token_badge.dart';
import '../../models/api_response_model.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../routes/app_routes.dart';
import 'appointment_details_screen.dart';

class TokenQueueScreen extends StatefulWidget {
  const TokenQueueScreen({super.key});

  @override
  State<TokenQueueScreen> createState() => _TokenQueueScreenState();
}

class _TokenQueueScreenState extends State<TokenQueueScreen> {
  List<AppointmentModel> _all = [];
  List<AppointmentModel> _filtered = [];
  List<DoctorModel> _doctors = [];
  bool _loading = true;
  String? _error;
  String? _selectedDate;
  int? _selectedDoctorId;
  String? _selectedStatus;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _initToday();
    _loadDoctors();
  }

  void _initToday() {
    final now = DateTime.now();
    _selectedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _load();
  }

  Future<void> _loadDoctors() async {
    try {
      _doctors = await DoctorService.getDoctors();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _all = await AppointmentService.getTodayAppointments(
        doctorId: _selectedDoctorId?.toString(),
        status: _selectedStatus,
        search: _search.isEmpty ? null : _search,
      );
      if (mounted) {
        _applyFilter();
        setState(() => _loading = false);
      }
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

  void _applyFilter() {
    var list = List<AppointmentModel>.from(_all);
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((a) =>
              a.patientName.toLowerCase().contains(q) ||
              '${a.tokenNumber}'.contains(q))
          .toList();
    }
    list.sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));
    _filtered = list;
  }

  Future<void> _updateStatus(AppointmentModel appt, String newStatus) async {
    try {
      await AppointmentService.updateStatus(appt.id, newStatus);
      _snack('Status updated.', success: true);
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  void _openDetail(AppointmentModel appt) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentDetailsScreen(appointmentId: appt.id),
        )).then((_) => _load());
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: success ? AppColors.success : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Token Queue',
      currentRoute: AppRoutes.tokenQueue,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Filters row
        Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 44,
                child: TextField(
                  onChanged: (q) {
                    _search = q;
                    if (!_loading) {
                      _applyFilter();
                      setState(() {});
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search patient or token…',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 18, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5)),
                  ),
                ),
              ),
              if (_doctors.isNotEmpty)
                _DoctorFilter(
                    doctors: _doctors,
                    value: _selectedDoctorId,
                    onChanged: (v) {
                      setState(() => _selectedDoctorId = v);
                      _load();
                    }),
              _StatusFilter(
                  value: _selectedStatus,
                  onChanged: (v) {
                    setState(() => _selectedStatus = v);
                    _load();
                  }),
              IconButton(
                icon:
                    const Icon(Icons.refresh_rounded, color: AppColors.primary),
                tooltip: 'Refresh',
                onPressed: _load,
              ),
            ]),
        const SizedBox(height: 8),
        DateFilterBar(
          selectedDate: _selectedDate,
          onDateChanged: (d) {
            setState(() => _selectedDate = d);
            _load();
          },
        ),
        const SizedBox(height: 16),

        if (_loading)
          const LoadingWidget()
        else if (_error != null)
          ErrorView(message: _error!, onRetry: _load)
        else
          _buildQueue(),
      ]),
    );
  }

  Widget _buildQueue() {
    if (_filtered.isEmpty) {
      return Center(
        child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.queue_rounded,
                  size: 56, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text(
                  _search.isNotEmpty
                      ? 'No results found.'
                      : 'No appointments in queue.',
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textSecondary)),
            ])),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _QueueCard(
        appointment: _filtered[i],
        onTap: () => _openDetail(_filtered[i]),
        onStatusChange: (status) => _updateStatus(_filtered[i], status),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;
  final void Function(String) onStatusChange;

  const _QueueCard(
      {required this.appointment,
      required this.onTap,
      required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final accent = _tokenColor(a.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .85),
            Colors.white.withValues(alpha: .65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .28), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: .08),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 4)),
          BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              TokenBadge(a.tokenNumber, size: 52, color: accent),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text(a.patientName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15,
                                  color: AppColors.textPrimary))),
                      StatusBadge(a.status),
                    ]),
                    const SizedBox(height: 4),
                    Text('Dr. ${a.doctorName}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    Text(Helpers.formatTime(a.appointmentTime),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 10),
                    _StatusButtons(status: a.status, onChanged: onStatusChange),
                  ])),
            ]),
          ),
        ),
      ),
    );
  }

  Color _tokenColor(String status) {
    switch (status) {
      case 'waiting':
        return AppColors.warning;
      case 'sent_to_assistant':
        return AppColors.info;
      case 'in_consultation':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

}

class _StatusButtons extends StatelessWidget {
  final String status;
  final void Function(String) onChanged;
  const _StatusButtons({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 6, children: [
      if (status == 'waiting')
        _Btn('Send to Dr', AppColors.info, () => onChanged('in_consultation')),
      if (status == 'in_consultation')
        _Btn('Complete', AppColors.success, () => onChanged('completed')),
      if (status != 'completed' && status != 'cancelled')
        _Btn('Cancel', AppColors.danger, () => onChanged('cancelled')),
    ]);
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: .75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: .28),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
    );
  }
}

class _DoctorFilter extends StatelessWidget {
  final List<DoctorModel> doctors;
  final int? value;
  final void Function(int?) onChanged;
  const _DoctorFilter(
      {required this.doctors, this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final active = value != null;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: .13),
                  AppColors.primaryLight.withValues(alpha: .05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: .35)
                : AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          hint: const Text('All Doctors',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          items: [
            const DropdownMenuItem<int?>(
                value: null, child: Text('All Doctors')),
            ...doctors.map((d) => DropdownMenuItem(
                value: d.id,
                child: Text('Dr. ${d.name}',
                    style: const TextStyle(fontSize: 13)))),
          ],
          onChanged: onChanged,
          style: TextStyle(
              fontSize: 13,
              color: active ? AppColors.primary : AppColors.textPrimary,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal),
          icon: Icon(Icons.expand_more_rounded,
              size: 18,
              color: active ? AppColors.primary : AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final String? value;
  final void Function(String?) onChanged;
  const _StatusFilter({this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final active = value != null;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(
                colors: [
                  AppColors.info.withValues(alpha: .13),
                  AppColors.info.withValues(alpha: .05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: active
                ? AppColors.info.withValues(alpha: .35)
                : AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: const Text('All Status',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          items: const [
            DropdownMenuItem(value: null, child: Text('All Status')),
            DropdownMenuItem(value: 'waiting', child: Text('Waiting')),
            DropdownMenuItem(
                value: 'in_consultation', child: Text('In Consultation')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
          ],
          onChanged: onChanged,
          style: TextStyle(
              fontSize: 13,
              color: active ? AppColors.info : AppColors.textPrimary,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal),
          icon: Icon(Icons.expand_more_rounded,
              size: 18,
              color: active ? AppColors.info : AppColors.textSecondary),
        ),
      ),
    );
  }
}
