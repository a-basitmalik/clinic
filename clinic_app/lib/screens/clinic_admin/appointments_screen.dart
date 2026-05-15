import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/clinic_admin_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_table.dart';
import '../../core/widgets/data_card_list.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/search_filter_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/api_response_model.dart';
import '../../models/appointment_model.dart';
import '../../routes/app_routes.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<AppointmentModel> _appointments = [];
  bool _loading = true;
  String? _error;
  String? _dateFilter;
  String? _statusFilter;

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
      _appointments = await ClinicAdminService.getAppointments(
        date: _dateFilter,
        status: _statusFilter,
      );
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _dateFilter =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
      _load();
    }
  }

  void _clearDate() {
    setState(() => _dateFilter = null);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: AppStrings.appointments,
      currentRoute: AppRoutes.appointments,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchFilterBar(
            hint: 'Search appointments…',
            onSearch: (q) => _load(),
            filters: [
              _DateChip(
                  date: _dateFilter, onTap: _pickDate, onClear: _clearDate),
              const SizedBox(width: 8),
              _StatusFilter(
                  value: _statusFilter,
                  onChanged: (v) {
                    setState(() => _statusFilter = v);
                    _load();
                  }),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const LoadingWidget()
          else if (_error != null)
            ErrorView(message: _error!, onRetry: _load)
          else
            _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (ResponsiveLayout.isMobile(context)) {
      return DataCardList<AppointmentModel>(
        items: _appointments,
        emptyMessage: 'No appointments found.',
        builder: (a) => InfoCard(child: _AppointmentCard(appointment: a)),
      );
    }
    return AppTable<AppointmentModel>(
      rows: _appointments,
      emptyMessage: 'No appointments found.',
      columns: [
        AppTableColumn(
            header: '#',
            cell: (a) => Text('${a.tokenNumber}',
                style: const TextStyle(fontWeight: FontWeight.w600))),
        AppTableColumn(
            header: 'Patient',
            cell: (a) => Text(a.patientName,
                style: const TextStyle(fontWeight: FontWeight.w500))),
        AppTableColumn(header: 'Doctor', cell: (a) => Text(a.doctorName)),
        AppTableColumn(
            header: 'Date',
            cell: (a) => Text(Helpers.formatDate(a.appointmentDate),
                style: const TextStyle(fontSize: 12))),
        AppTableColumn(header: 'Time', cell: (a) => Text(a.appointmentTime)),
        AppTableColumn(
            header: 'Type', cell: (a) => _TypeBadge(a.consultationType)),
        AppTableColumn(header: 'Status', cell: (a) => StatusBadge(a.status)),
        AppTableColumn(
            header: 'Payment', cell: (a) => StatusBadge(a.paymentStatus)),
        AppTableColumn(
            header: 'Fee', cell: (a) => Text(Helpers.formatCurrency(a.fee))),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  final String? date;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _DateChip({this.date, required this.onTap, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: date != null ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: date != null ? AppColors.primary : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today_rounded,
              size: 16,
              color:
                  date != null ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            date ?? 'Date',
            style: TextStyle(
                fontSize: 13,
                color:
                    date != null ? AppColors.primary : AppColors.textSecondary),
          ),
          if (date != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded,
                  size: 14, color: AppColors.primary),
            ),
          ],
        ]),
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
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
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
                value: 'sent_to_assistant', child: Text('Sent to Assistant')),
            DropdownMenuItem(
                value: 'in_consultation', child: Text('In Consultation')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
          ],
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          icon: const Icon(Icons.expand_more_rounded,
              size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    const labels = {
      'new': 'New',
      'followup': 'Follow-up',
      'emergency': 'Emergency'
    };
    const colors = {
      'new': AppColors.info,
      'followup': AppColors.accent,
      'emergency': AppColors.danger,
    };
    final label = labels[type] ?? type;
    final color = colors[type] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8)),
          child: Center(
              child: Text('${a.tokenNumber}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 15))),
        ),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.patientName,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(a.doctorName,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ])),
        StatusBadge(a.status),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        const Icon(Icons.calendar_today_rounded,
            size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(Helpers.formatDate(a.appointmentDate),
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        const Icon(Icons.access_time_rounded,
            size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(a.appointmentTime,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const Spacer(),
        _TypeBadge(a.consultationType),
        const SizedBox(width: 8),
        StatusBadge(a.paymentStatus),
      ]),
    ]);
  }
}
