import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/payment_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/receipt_view.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/widgets/search_filter_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/api_response_model.dart';
import '../../models/payment_model.dart';
import '../../routes/app_routes.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  List<PaymentModel> _all = [];
  List<PaymentModel> _filtered = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String? _statusFilter;
  String? _methodFilter;
  DateTime? _from;
  DateTime? _to;

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
      _all = await PaymentService.getPayments(
        from: _from != null ? _fmtDate(_from!) : null,
        to: _to != null ? _fmtDate(_to!) : null,
        status: _statusFilter,
        method: _methodFilter,
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
    final q = _search.toLowerCase();
    _filtered = q.isEmpty
        ? List.from(_all)
        : _all
            .where((p) =>
                p.patientName.toLowerCase().contains(q) ||
                p.receiptNumber.toLowerCase().contains(q))
            .toList();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: (_from != null && _to != null)
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
    );
    if (range != null) {
      setState(() {
        _from = range.start;
        _to = range.end;
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Receipts',
      currentRoute: AppRoutes.receipts,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SearchFilterBar(
          hint: 'Search by patient or receipt no…',
          onSearch: (q) => setState(() {
            _search = q;
            _applyFilter();
          }),
          filters: [
            _FilterChip(
              label: _from != null && _to != null
                  ? '${_from!.day}/${_from!.month} – ${_to!.day}/${_to!.month}'
                  : 'Date Range',
              active: _from != null,
              onTap: _pickDateRange,
              onClear: _from != null
                  ? () {
                      setState(() {
                        _from = null;
                        _to = null;
                      });
                      _load();
                    }
                  : null,
            ),
            const SizedBox(width: 4),
            _DropFilter(
              value: _statusFilter,
              hint: 'Status',
              items: const [
                DropdownMenuItem(value: null, child: Text('All Status')),
                DropdownMenuItem(value: 'paid', child: Text('Paid')),
                DropdownMenuItem(value: 'partial', child: Text('Partial')),
              ],
              onChanged: (v) {
                setState(() => _statusFilter = v);
                _load();
              },
            ),
            const SizedBox(width: 4),
            _DropFilter(
              value: _methodFilter,
              hint: 'Method',
              items: const [
                DropdownMenuItem(value: null, child: Text('All Methods')),
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'easypaisa', child: Text('EasyPaisa')),
                DropdownMenuItem(value: 'jazzcash', child: Text('JazzCash')),
                DropdownMenuItem(value: 'bank', child: Text('Bank')),
              ],
              onChanged: (v) {
                setState(() => _methodFilter = v);
                _load();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!_loading && !(_error != null)) _SummaryBar(payments: _filtered),
        const SizedBox(height: 12),
        if (_loading)
          const LoadingWidget()
        else if (_error != null)
          ErrorView(message: _error!, onRetry: _load)
        else
          _buildList(),
      ]),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return const Center(
        child: Padding(
            padding: EdgeInsets.all(48),
            child: Text('No receipts found.',
                style: TextStyle(color: AppColors.textSecondary))),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ReceiptTile(
        payment: _filtered[i],
        onTap: () => ReceiptView.show(context, _filtered[i]),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final List<PaymentModel> payments;
  const _SummaryBar({required this.payments});

  @override
  Widget build(BuildContext context) {
    final total = payments.fold(0.0, (s, p) => s + p.paidAmount);
    return Container(
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
        Text('${payments.length} receipts',
            style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
                fontSize: 13)),
        const Spacer(),
        Text('Total: ${Helpers.formatCurrency(total)}',
            style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ]),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  final PaymentModel payment;
  final VoidCallback onTap;
  const _ReceiptTile({required this.payment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = payment;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: p.isPaid
                    ? AppColors.successSurface
                    : AppColors.warningSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.receipt_long_rounded,
                  color: p.isPaid ? AppColors.success : AppColors.warning,
                  size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(p.patientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(p.receiptNumber,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Text(Helpers.formatDateTime(p.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(Helpers.formatCurrency(p.paidAmount),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              StatusBadge(p.status),
              const SizedBox(height: 2),
              Text(_methodLabel(p.paymentMethod),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ]),
        ),
      ),
    );
  }

  String _methodLabel(String s) {
    const m = {
      'cash': 'Cash',
      'card': 'Card',
      'easypaisa': 'EasyPaisa',
      'jazzcash': 'JazzCash',
      'bank': 'Bank'
    };
    return m[s] ?? s;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _FilterChip(
      {required this.label,
      required this.active,
      required this.onTap,
      this.onClear});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.date_range_rounded,
              size: 16,
              color: active ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: active ? AppColors.primary : AppColors.textSecondary)),
          if (onClear != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 14, color: AppColors.primary)),
          ],
        ]),
      ),
    );
  }
}

class _DropFilter extends StatelessWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String?>> items;
  final void Function(String?) onChanged;
  const _DropFilter(
      {this.value,
      required this.hint,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          items: items,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          icon: const Icon(Icons.expand_more_rounded,
              size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
