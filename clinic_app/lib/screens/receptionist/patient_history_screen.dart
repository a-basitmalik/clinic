import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/patient_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/receipt_view.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/token_badge.dart';
import '../../models/api_response_model.dart';
import '../../models/patient_history_model.dart';

class PatientHistoryScreen extends StatefulWidget {
  final int patientId;
  const PatientHistoryScreen({super.key, required this.patientId});

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen>
    with SingleTickerProviderStateMixin {
  PatientHistoryModel? _history;
  bool _loading = true;
  String? _error;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _history = await PatientService.getHistory(widget.patientId);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          _history?.patient.name ?? 'Patient History',
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: _loading || _error != null
            ? null
            : TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Appointments'),
                  Tab(text: 'Prescriptions'),
                  Tab(text: 'Payments'),
                ],
              ),
      ),
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _OverviewTab(history: _history!),
                    _AppointmentsTab(history: _history!),
                    _PrescriptionsTab(history: _history!),
                    _PaymentsTab(history: _history!),
                  ],
                ),
    );
  }
}

// ── Overview ─────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final PatientHistoryModel history;
  const _OverviewTab({required this.history});

  @override
  Widget build(BuildContext context) {
    final p = history.patient;
    final h = history;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Profile
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primarySurface,
              child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(p.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(p.patientCode,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (p.age != null) '${p.age} yrs',
                      if (p.gender != null) Helpers.capitalize(p.gender!),
                      if (p.bloodGroup != null) p.bloodGroup!
                    ].join(' • '),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ])),
          ]),
        ),
        const SizedBox(height: 16),

        // Stats
        Row(children: [
          _StatCard('Total Visits', '${h.totalVisits}',
              Icons.calendar_month_rounded, AppColors.primary),
          const SizedBox(width: 12),
          _StatCard('Doctors Seen', '${h.visitedDoctors.length}',
              Icons.medical_services_rounded, AppColors.accent),
          const SizedBox(width: 12),
          _StatCard('Payments', '${h.payments.length}', Icons.payments_rounded,
              AppColors.success),
        ]),
        const SizedBox(height: 16),

        if (h.lastVisitDate != null) ...[
          _InfoRow('Last Visit', Helpers.formatDate(h.lastVisitDate!)),
          const SizedBox(height: 8),
        ],
        if (h.upcomingDate != null) ...[
          _InfoRow('Upcoming', Helpers.formatDate(h.upcomingDate!)),
          const SizedBox(height: 8),
        ],

        if (h.visitedDoctors.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Visited Doctors',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: h.visitedDoctors
                  .map((d) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(d,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500)),
                      ))
                  .toList()),
        ],
      ]),
    );
  }

  Widget _InfoRow(String label, String value) {
    return Row(children: [
      SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary))),
      Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(title,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ── Appointments tab ─────────────────────────────────────────────────────────

class _AppointmentsTab extends StatelessWidget {
  final PatientHistoryModel history;
  const _AppointmentsTab({required this.history});

  @override
  Widget build(BuildContext context) {
    final appts = history.appointments;
    if (appts.isEmpty) {
      return const Center(
          child: Text('No appointments.',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: appts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = appts[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            TokenBadgeSmall(a.tokenNumber),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Dr. ${a.doctorName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(Helpers.formatDate(a.appointmentDate),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text(_typeLabel(a.consultationType),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StatusBadge(a.status, fontSize: 10),
              const SizedBox(height: 4),
              Text(Helpers.formatCurrency(a.fee),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ]),
        );
      },
    );
  }

  String _typeLabel(String s) {
    const m = {'new': 'New', 'followup': 'Follow-up', 'emergency': 'Emergency'};
    return m[s] ?? s;
  }
}

// ── Prescriptions tab ─────────────────────────────────────────────────────────

class _PrescriptionsTab extends StatelessWidget {
  final PatientHistoryModel history;
  const _PrescriptionsTab({required this.history});

  @override
  Widget build(BuildContext context) {
    final rxList = history.prescriptions;
    if (rxList.isEmpty) {
      return const Center(
          child: Text('No prescriptions.',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rxList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final rx = rxList[i];
        final items = (rx['items'] as List?)?.cast<Map>() ?? [];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.receipt_long_rounded,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Dr. ${rx['doctor_name'] ?? '—'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14))),
              Text(Helpers.formatDate(rx['created_at']?.toString()),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
            if (rx['diagnosis'] != null) ...[
              const SizedBox(height: 6),
              Text('Diagnosis: ${rx['diagnosis']}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
            if (items.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.circle,
                          size: 6, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              '${item['medicine_name'] ?? '—'}  ${item['dosage'] ?? ''}  ${item['frequency'] ?? ''}',
                              style: const TextStyle(fontSize: 12))),
                    ]),
                  )),
            ],
          ]),
        );
      },
    );
  }
}

// ── Payments tab ─────────────────────────────────────────────────────────────

class _PaymentsTab extends StatelessWidget {
  final PatientHistoryModel history;
  const _PaymentsTab({required this.history});

  @override
  Widget build(BuildContext context) {
    final payments = history.payments;
    if (payments.isEmpty) {
      return const Center(
          child: Text('No payment records.',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    final total = payments.fold(0.0, (s, p) => s + p.paidAmount);
    return Column(children: [
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.successSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Text('${payments.length} payments',
              style: const TextStyle(
                  color: AppColors.success, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text('Total: ${Helpers.formatCurrency(total)}',
              style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final p = payments[i];
            return Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => ReceiptView.show(context, p),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: p.isPaid
                            ? AppColors.successSurface
                            : AppColors.warningSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.receipt_long_rounded,
                          color:
                              p.isPaid ? AppColors.success : AppColors.warning,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(p.receiptNumber,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(Helpers.formatDateTime(p.createdAt),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ])),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(Helpers.formatCurrency(p.paidAmount),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          StatusBadge(p.status, fontSize: 10),
                        ]),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
