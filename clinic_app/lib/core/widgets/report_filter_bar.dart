import 'package:flutter/material.dart';
import '../utils/helpers.dart';

class ReportFilterBar extends StatelessWidget {
  final DateTimeRange? range;
  final String? doctorId;
  final String? paymentType;
  final String? status;
  final String groupBy;
  final ValueChanged<DateTimeRange?> onRangeChanged;
  final ValueChanged<String?>? onDoctorChanged;
  final ValueChanged<String?>? onPaymentTypeChanged;
  final ValueChanged<String?>? onStatusChanged;
  final ValueChanged<String>? onGroupByChanged;
  final VoidCallback onRefresh;

  const ReportFilterBar({
    super.key,
    required this.range,
    this.doctorId,
    this.paymentType,
    this.status,
    this.groupBy = 'day',
    required this.onRangeChanged,
    this.onDoctorChanged,
    this.onPaymentTypeChanged,
    this.onStatusChanged,
    this.onGroupByChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 12, runSpacing: 12, children: [
      OutlinedButton.icon(
        icon: const Icon(Icons.date_range_rounded),
        label: Text(range == null
            ? 'This Month'
            : '${Helpers.formatDate(range!.start.toIso8601String())} - ${Helpers.formatDate(range!.end.toIso8601String())}'),
        onPressed: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          onRangeChanged(picked);
        },
      ),
      if (onDoctorChanged != null)
        _textFilter('Doctor ID', doctorId, onDoctorChanged!),
      if (onPaymentTypeChanged != null)
        _select(
            'Payment Type',
            paymentType,
            const [null, 'consultation', 'pharmacy', 'lab', 'other'],
            onPaymentTypeChanged!),
      if (onStatusChanged != null)
        _select(
            'Status',
            status,
            const [
              null,
              'paid',
              'pending',
              'refunded',
              'completed',
              'cancelled'
            ],
            onStatusChanged!),
      if (onGroupByChanged != null)
        _select('Group By', groupBy, const ['day', 'month', 'year'],
            (v) => onGroupByChanged!(v ?? 'day')),
      IconButton.filled(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh'),
    ]);
  }

  Widget _textFilter(
          String label, String? value, ValueChanged<String?> onChanged) =>
      SizedBox(
        width: 140,
        child: TextFormField(
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          keyboardType: TextInputType.number,
          onChanged: (v) => onChanged(v.isEmpty ? null : v),
        ),
      );

  Widget _select(String label, String? value, List<String?> values,
          ValueChanged<String?> onChanged) =>
      SizedBox(
        width: 170,
        child: DropdownButtonFormField<String?>(
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          items: values
              .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(v == null ? 'All' : Helpers.snakeToTitle(v))))
              .toList(),
          onChanged: onChanged,
        ),
      );
}
